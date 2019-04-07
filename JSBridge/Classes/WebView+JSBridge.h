//
//  WKWebView+JSBridge.h
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/6.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSBridge.h"

@interface WKWebView (JSBridge)

@property (nonatomic, weak) JSBridge *bridge;

@end


@interface UIWebView (JSBridge)

@property (nonatomic, weak) JSBridge *bridge;

@property (nonatomic, weak, readonly) JSContext *context;

@end

