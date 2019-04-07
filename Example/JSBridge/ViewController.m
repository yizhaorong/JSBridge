//
//  JSViewController.m
//  JSBridge
//
//  Created by yizhaorong on 04/07/2019.
//  Copyright (c) 2019 yizhaorong. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <JSBridge/JSBridge.h>

@interface ViewController ()

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) JSBridge *jsBridge;

@end

@implementation ViewController

- (void)dealloc {
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"index.html" withExtension:nil];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [self.view addSubview:self.webView];
    
    
    [self.jsBridge registerHandler:@"nativeLog" handler:^(id data, JSResponseCallback responseCallback) {
        NSLog(@"Native Log");
        responseCallback(@{@"result": @"本地日志打印"});
    }];
    
    __weak typeof(self) weakSelf = self;
    [self.jsBridge registerHandler:@"callJS" handler:^(id data, JSResponseCallback responseCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.jsBridge callHandler:@"testJavascriptHandler" data:@{@"name": @"user"} callback:^(id result, NSError *error) {
            NSLog(@"result:%@", result);
        }];
    }];
    
    [self.jsBridge registerHandler:@"sendEvent" handler:^(id data, JSResponseCallback responseCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.jsBridge sendEvent:@"applicationEnterBackground" data:@{} callback:^(id result, NSError *error) {
            NSLog(@"发送成功");
        }];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.presentingViewController) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
        button.frame = CGRectMake(20, 20, 44, 44);
        button.backgroundColor = [UIColor orangeColor];
        [button addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    } else {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
        button.frame = CGRectMake(200, 64, 44, 44);
        button.backgroundColor = [UIColor orangeColor];
        [button addTarget:self action:@selector(openWebView) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

- (void)openWebView {
    UIViewController *vc = [NSClassFromString(@"UIWebViewController") new];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc]init];
        WKPreferences *preferences = [[WKPreferences alloc]init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        configuration.preferences = preferences;
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    }
    return _webView;
}

- (JSBridge *)jsBridge {
    if (!_jsBridge) {
        _jsBridge = [JSBridge bridgeForWebView:self.webView];
    }
    return _jsBridge;
}

@end
