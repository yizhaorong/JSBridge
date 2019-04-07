//
//  JSBridge.h
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/3.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "JSMessageObject.h"


@interface JSBridge : NSObject <WKScriptMessageHandler, UIWebViewDelegate, WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, weak) id webView;

/**
 通过 WebView 初始化实例

 @param webView UIWebView 或 WKWebView
 @return 实例
 */
+ (instancetype)bridgeForWebView:(id)webView;

/**
 通过 WebView 初始化实例
 
 @param webView UIWebView 或 WKWebView
 @return 实例
 */
+ (instancetype)bridge:(id)webView;
/// 开启日志打印
+ (void)enableLogging;

/**
 通过 WebView 初始化实例
 
 @param webView UIWebView 或 WKWebView
 @return 实例
 */
- (instancetype)initWithWebView:(id)webView;

/**
 注册用于 JS 调用 Native 的方法

 @param handlerName JS 中使用的handlerName
 @param handler 回调
 */
- (void)registerHandler:(NSString*)handlerName handler:(JSHandler)handler;

/**
 移除 handler

 @param handlerName handlerName
 */
- (void)removeHandler:(NSString*)handlerName;

/**
 移除所有 handler
 */
- (void)reset;

/**
 调用 JS 方法

 @param handlerName 句柄名
 @param data 数据
 @param responseCallback 回调
 */
- (void)callHandler:(NSString *)handlerName data:(NSDictionary *)data callback:(JSCompletionCallback)responseCallback;

/**
 发送事件

 @param eventName 事件名
 @param data 数据
 @param responseCallback 回调
 */
- (void)sendEvent:(NSString *)eventName data:(NSDictionary *)data callback:(JSCompletionCallback)responseCallback;

/**
 设置 UIDelegate 或 UIWebViewDelegate

 @param delegate 代理
 */
- (void)setWebViewDelegate:(id)delegate;

/**
 设置 UINavigationDelegate

 @param delegate 代理
 */
- (void)setWebViewNavigationDelegate:(id)delegate;

@end

