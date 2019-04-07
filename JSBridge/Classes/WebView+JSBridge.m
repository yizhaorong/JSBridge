//
//  WKWebView+JSBridge.m
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/6.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#import "WebView+JSBridge.h"
#import <objc/runtime.h>

@interface JSWeakObjectContainer : NSObject
@property (nonatomic, readonly, weak) id object;
@end

@implementation JSWeakObjectContainer
- (instancetype) initWithObject:(id)object
{
    if (!(self = [super init]))
        return nil;
    
    _object = object;
    
    return self;
}
@end

@implementation NSObject (JSBridge)

+ (BOOL)js_swizzleInstanceMethod:(Class)originalClass originalSel:(SEL)originalSel targetClass:(Class)targetClass targetSel:(SEL)targetSel {
    if (!originalClass || !originalSel || !targetClass || !targetSel) {
        return NO;
    }
    Method originalMethod = class_getInstanceMethod(originalClass, originalSel);
    Method newMethod = class_getInstanceMethod(targetClass, targetSel);
    if (!originalMethod || !newMethod) return NO;
    
    class_addMethod(originalClass,
                    originalSel,
                    class_getMethodImplementation(originalClass, originalSel),
                    method_getTypeEncoding(originalMethod));
    class_addMethod(targetClass,
                    targetSel,
                    class_getMethodImplementation(targetClass, targetSel),
                    method_getTypeEncoding(newMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSel),
                                   class_getInstanceMethod(targetClass, targetSel));
    
    return YES;
}

@end

@implementation WKWebView (JSBridge)

+ (void)load {
    [self js_swizzleInstanceMethod:self originalSel:@selector(setUIDelegate:) targetClass:self targetSel:@selector(js_setUIDelegate:)];
    [self js_swizzleInstanceMethod:self originalSel:@selector(setNavigationDelegate:) targetClass:self targetSel:@selector(js_setNavigationDelegate:)];
}

- (void)js_setUIDelegate:(id<WKUIDelegate>)UIDelegate {
    if (self.bridge && UIDelegate != self.bridge) {
        [self.bridge setWebViewDelegate:UIDelegate];
        [self js_setUIDelegate:self.bridge];
    } else {
        [self js_setUIDelegate:UIDelegate];
    }
}

- (void)js_setNavigationDelegate:(id<WKNavigationDelegate>)navigationDelegate {
    if (self.bridge && navigationDelegate != self.bridge) {
        [self.bridge setWebViewNavigationDelegate:navigationDelegate];
        [self js_setNavigationDelegate:self.bridge];
    } else {
        [self js_setNavigationDelegate:navigationDelegate];
    }
}

#pragma mark - Setters And Getters

- (void)setBridge:(JSBridge *)bridge {
    objc_setAssociatedObject(self, @selector(bridge), [[JSWeakObjectContainer alloc] initWithObject:bridge], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JSBridge *)bridge {
    return [objc_getAssociatedObject(self, @selector(bridge)) object];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation UIWebView (JSBridge)

+ (void)load {
    [self js_swizzleInstanceMethod:self originalSel:@selector(setDelegate:) targetClass:self targetSel:@selector(js_setDelegate:)];
}

- (void)js_setDelegate:(id<UIWebViewDelegate>)delegate {
    if (self.bridge && delegate != self.bridge) {
        [self.bridge setWebViewDelegate:delegate];
        [self js_setDelegate:self.bridge];
    } else {
        [self js_setDelegate:delegate];
    }
}

#pragma mark - Setters And Getters

- (void)setBridge:(JSBridge *)bridge {
    objc_setAssociatedObject(self, @selector(bridge), [[JSWeakObjectContainer alloc] initWithObject:bridge], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JSBridge *)bridge {
    return [objc_getAssociatedObject(self, @selector(bridge)) object];
}

- (JSContext *)context {
    return [self valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
}

@end
#pragma clang diagnostic pop
