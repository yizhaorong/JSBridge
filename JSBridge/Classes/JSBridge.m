//
//  JSBridge.m
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/3.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#import "JSBridge.h"
#import "JSBridge_JS.h"
#import "WebView+JSBridge.h"

#define EXCUTE_IN_MAINTHREAD(block) \
if ([NSThread currentThread].isMainThread) { \
block(); \
} else {\
dispatch_async(dispatch_get_main_queue(), ^{ \
block(); \
});\
}

static BOOL _enableLogging = NO;

@interface WeakScriptMessageDelegate : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface JSBridge () 

@property (nonatomic, strong)NSMutableDictionary *handlerMap;

@property (nonatomic, weak) id webViewDelegate;

@property (nonatomic, weak) id webViewNavigationDelegate;

@end

@implementation JSBridge

+ (void)enableLogging {
    _enableLogging = YES;
}

+ (instancetype)bridgeForWebView:(id)webView {
    JSBridge *bridge = [[JSBridge alloc] initWithWebView:webView];
    return bridge;
}

+ (instancetype)bridge:(id)webView {
    return [self bridgeForWebView:webView];
}

- (instancetype)initWithWebView:(id)webView {
    if (self = [super init]) {
        self.webView = webView;
        [self _configWebView];
    }
    return self;
}

- (void)registerHandler:(NSString *)handlerName handler:(JSHandler)handler {
    if (handlerName && handler) {
        self.handlerMap[handlerName] = [handler copy];
    }
}

- (void)removeHandler:(NSString *)handlerName {
    if (handlerName) {
        [self.handlerMap removeObjectForKey:handlerName];
    }
}

- (void)reset {
    [self.handlerMap removeAllObjects];
}

- (void)callHandler:(NSString *)handlerName data:(NSDictionary *)data callback:(JSCompletionCallback)responseCallback {
    [self _log:@"SEND" actionName:handlerName json:data];
    NSString *jsFunction = @"window.JSBridge.callJSHandler";
    [self _injectMessageFuction:jsFunction withActionId:handlerName withParams:data handler:responseCallback];
}

- (void)sendEvent:(NSString *)eventName data:(NSDictionary *)data callback:(JSCompletionCallback)responseCallback {
    [self _log:@"SEND" actionName:eventName json:data];
    NSString *jsFunction = @"window.JSBridge.eventDispatcher";
    [self _injectMessageFuction:jsFunction withActionId:eventName withParams:data handler:responseCallback];
}

#pragma mark - Private
- (void)_configWebView {
    id webView = self.webView;
    if ([webView isKindOfClass:UIWebView.class]) {
        UIWebView *ui_webView = (UIWebView *)webView;
        ui_webView.bridge = self;
        if (ui_webView.delegate) {
            [self setWebViewDelegate:ui_webView.delegate];
        }
        ui_webView.delegate = self;
        
        __weak typeof(self) weakSelf = self;
        ui_webView.context[@"JSBridge_postAsyncMessage"] = ^(NSDictionary *data) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf _processAsyncMessage:data];
        };
        
        ui_webView.context[@"JSBridge_postSyncMessage"] = ^(NSDictionary *data) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return @"";
            [strongSelf _log:@"RCVD" actionName:nil json:data];
            JSMessageObject *msg = [[JSMessageObject alloc] initWithDictionary:data];
            JSHandler handler = strongSelf.handlerMap[msg.handlerName];
            __block NSString *resultJson = @"{}";
            JSResponseCallback callback = ^(id responseData) {
                resultJson = [strongSelf _serializeMessageData:responseData];
            };
            if (handler) {
                handler(msg, callback);
            }
            return resultJson;
        };
    } else if ([webView isKindOfClass:WKWebView.class]) {
        WKWebView *wk_webView = (WKWebView *)webView;
        wk_webView.bridge = self;
        if (wk_webView.UIDelegate) {
            [self setWebViewDelegate:wk_webView.UIDelegate];
        }
        wk_webView.UIDelegate = self;
        
        if (wk_webView.navigationDelegate) {
            [self setWebViewNavigationDelegate:wk_webView.navigationDelegate];
        }
        wk_webView.navigationDelegate = self;
    }
}

- (void)_injectJavascriptFile {
    NSString *js = JSBridge_js([self isWKWebView]);
    [self _evaluateJavaScript:js completionHandler:nil];
}

- (void)_evaluateJavaScript:(NSString *)javascriptCommand completionHandler:(void (^)(id, NSError *))completionHandler {
    if ([self isWKWebView]) {
        WKWebView *webView = (WKWebView *)self.webView;
        EXCUTE_IN_MAINTHREAD(^{
            [webView evaluateJavaScript:javascriptCommand completionHandler:^(id result, NSError * _Nullable error) {
                if (completionHandler) {
                    completionHandler(result, error);
                }
            }];
        });
    } else {
        UIWebView *webView = (UIWebView *)self.webView;
        EXCUTE_IN_MAINTHREAD(^{
            NSString *result = [webView stringByEvaluatingJavaScriptFromString:javascriptCommand];
            if (completionHandler) {
                completionHandler(result, nil);
            }
        });
    }
}

- (BOOL)isWKWebView {
    if ([self.webView isKindOfClass:WKWebView.class]) {
        return YES;
    }
    return NO;
}

// 字典JSON化
- (NSString *)_serializeMessageData:(id)message{
    if (message) {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    }
    return nil;
}
// JSON Javascript编码处理
- (NSString *)_transcodingJavascriptMessage:(NSString *)message {
    message = [message stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    message = [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    message = [message stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    message = [message stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    message = [message stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    message = [message stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    message = [message stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    message = [message stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    return message;
}

-(void)_injectMessageFuction:(NSString *)msg withActionId:(NSString *)actionId withParams:(NSDictionary *)params handler:(void (^)(id result, NSError *error))handler{
    if (!params) {
        params = @{};
    }
    
    NSString *paramsString = [self _serializeMessageData:params];
    NSString *paramsJSString = [self _transcodingJavascriptMessage:paramsString];
    NSString* javascriptCommand = [NSString stringWithFormat:@"%@('%@', '%@');", msg, actionId, paramsJSString];
    [self _evaluateJavaScript:javascriptCommand completionHandler:handler];
}

- (void)_processAsyncMessage:(NSDictionary *)message {
    [self _log:@"RCVD" actionName:nil json:message];
    if (message) {
        JSMessageObject *msg = [[JSMessageObject alloc] initWithDictionary:message];
        JSHandler handler = self.handlerMap[msg.handlerName];
        JSResponseCallback callback = nil;
        //处理回调
        if (msg.callbackID && msg.callbackID.length > 0) {
            NSString *callbackFunction = msg.callbackFunction;
            NSString *callbackId = msg.callbackID;
            //生成OC的回调block，输入参数是，任意字典对象的执行结果
            __weak typeof(self) weakSelf = self;
            callback = ^(id responseData){
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                //执行OC 主动 Call JS 的编码与通信
                [self _injectMessageFuction:callbackFunction withActionId:callbackId withParams:responseData handler:nil];
            };
        }
        if (handler){
            handler(msg, callback);
        }
    }
}

- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}

- (void)_log:(NSString *)action actionName:(NSString *)actionName json:(id)json {
    if (!_enableLogging) { return; }
    
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _serializeMessage:json pretty:YES];
    }
    if (actionName) {
        NSLog(@"JSBridge %@: actionName:%@\n %@", action, actionName, json);
    } else {
        NSLog(@"JSBridge %@: %@", action, json);
    }
    
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    NSDictionary *msgBody = message.body;
    [self _processAsyncMessage:msgBody];
}

#pragma mark - WKUIDelegate
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)]) {
        return [self.webViewDelegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return nil;
}

- (void)webViewDidClose:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)) {
    if ([self.webViewDelegate respondsToSelector:@selector(webViewDidClose:)]) {
        [self.webViewDelegate webViewDidClose:webView];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.webViewDelegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.webViewDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * result))completionHandler {
    
    if (webView != self.webView) {
        completionHandler(@"");
        return;
    }
    
    NSData *jsonData = [prompt dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingMutableContainers
                                                          error:&err];
    [self _log:@"RCVD" actionName:nil json:dic];
    JSMessageObject *msg = [[JSMessageObject alloc] initWithDictionary:dic];
    JSHandler handler = self.handlerMap[msg.handlerName];
    __block NSString *resultJson = @"{}";
    __weak typeof(self) weakSelf = self;
    JSResponseCallback callback = ^(id responseData) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        resultJson = [strongSelf _serializeMessageData:responseData];
    };
    if (handler) {
        handler(msg, callback);
    }
    completionHandler(resultJson);
}

#if TARGET_OS_IPHONE
- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo API_AVAILABLE(ios(10.0)) {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:shouldPreviewElement:)]) {
        return [self.webViewDelegate webView:webView shouldPreviewElement:elementInfo];
    }
    return NO;
}

- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions API_AVAILABLE(ios(10.0)) {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:previewingViewControllerForElement:defaultActions:)]) {
        return [self.webViewDelegate webView:webView previewingViewControllerForElement:elementInfo defaultActions:previewActions];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_AVAILABLE(ios(10.0)) {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:commitPreviewingViewController:)]) {
        [self.webViewDelegate webView:webView commitPreviewingViewController:previewingViewController];
    }
}
#endif // TARGET_OS_IPHONE

#if !TARGET_OS_IPHONE
- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * _Nullable URLs))completionHandler API_AVAILABLE(macosx(10.12)) {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:runOpenPanelWithParameters:initiatedByFrame:completionHandler:)]) {
        [self.webViewDelegate webView:webView runOpenPanelWithParameters: parameters initiatedByFrame:frame completionHandler:completionHandler];
    }
}

#endif

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    [self _injectJavascriptFile];
    if ([self.webViewNavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.webViewNavigationDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if([self.webViewNavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [self.webViewNavigationDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    if([self.webViewNavigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [self.webViewNavigationDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    if([self.webViewNavigationDelegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [self.webViewNavigationDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if ([self.webViewNavigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.webViewNavigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    if ([self.webViewNavigationDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [self.webViewNavigationDelegate webView:webView didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    if ([self.webViewNavigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [self.webViewNavigationDelegate webView:webView didFinishNavigation:navigation];
    }
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if ([self.webViewNavigationDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [self.webViewNavigationDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    if ([self.webViewNavigationDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [self.webViewNavigationDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)) {
    if ([self.webViewNavigationDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        [self.webViewNavigationDelegate webViewWebContentProcessDidTerminate:webView];
    }
}

#pragma mark - UIWebViewDelegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self _injectJavascriptFile];
    if ([self.webViewDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.webViewDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView  {
    if ([self.webViewDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.webViewDelegate webViewDidStartLoad:webView];
    }
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([self.webViewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.webViewDelegate webViewDidFinishLoad:webView];
    }
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([self.webViewDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.webViewDelegate webView:webView didFailLoadWithError:error];
    }
}
#pragma clang diagnostic pop

#pragma mark - Setters And Getters
- (NSMutableDictionary *)handlerMap {
    if (!_handlerMap) {
        _handlerMap = [NSMutableDictionary dictionary];
    }
    return _handlerMap;
}

- (void)setWebView:(id)webView {
    _webView = webView;
    if ([webView isKindOfClass:WKWebView.class]) {
        WKWebView *wk_webView = (WKWebView *)webView;
        [wk_webView.configuration.userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"JSBridge"];
    }
}

@end

#pragma clang diagnostic pop

@implementation WeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate
{
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end
