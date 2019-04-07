//
//  JSBridgeMacros.h
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/6.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#ifndef JSBridgeMacros_h
#define JSBridgeMacros_h

typedef void (^JSResponseCallback)(id responseData);

typedef void (^JSHandler) (id data, JSResponseCallback responseCallback);

typedef void (^JSCompletionCallback)(id result, NSError *error);

#endif /* JSBridgeMacros_h */
