//
//  JSMessageObject.h
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/3.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSBridgeMacros.h"

@interface JSMessageObject : NSObject
@property (nonatomic, copy) NSString *handlerName;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, copy, readonly) NSString * callbackID;
@property (nonatomic, copy, readonly) NSString  *callbackFunction;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

