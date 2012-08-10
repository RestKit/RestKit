//
//  RKDynamicObjectMappingMatcher.h
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectMapping.h"


@interface RKDynamicObjectMappingMatcher : NSObject {
    NSString *_keyPath;
    id _value;
    BOOL (^_isMatchForDataBlock)(id data);
}

@property (nonatomic, readonly) RKObjectMapping *objectMapping;
@property (nonatomic, readonly) NSString *primaryKeyAttribute;

- (id)initWithKey:(NSString *)key value:(id)value objectMapping:(RKObjectMapping *)objectMapping;
- (id)initWithKey:(NSString *)key value:(id)value primaryKeyAttribute:(NSString *)primaryKeyAttribute;
- (id)initWithPrimaryKeyAttribute:(NSString *)primaryKeyAttribute evaluationBlock:(BOOL (^)(id data))block;
- (BOOL)isMatchForData:(id)data;
- (NSString *)matchDescription;

@end
