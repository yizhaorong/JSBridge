//
//  JSMessageObject.m
//  WebViewDemo
//
//  Created by yizhaorong on 2019/4/3.
//  Copyright © 2019 yizhaorong. All rights reserved.
//

#import "JSMessageObject.h"

@interface JSMessageObject ()

@end

@implementation JSMessageObject

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

@end
