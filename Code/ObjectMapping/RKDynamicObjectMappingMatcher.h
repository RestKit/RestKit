//
//  RKDynamicObjectMappingMatcher.h
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectMapping.h"

typedef NSPredicate*(^RKDynamicObjectCreatePredicateBlock)(NSString*,id,id,RKObjectMapping*);

@interface RKDynamicObjectMappingMatcher : NSObject {
    NSString* _keyPath;
    id _value;
    RKObjectMapping* _objectMapping;
    NSString* _primaryKeyAttribute;
    BOOL (^_isMatchForDataBlock)(id data);
    RKDynamicObjectCreatePredicateBlock _createPredicateBlock;
}

@property (nonatomic, readonly) RKObjectMapping* objectMapping;
@property (nonatomic, readonly) NSString* primaryKeyAttribute;
@property (nonatomic, readonly) RKDynamicObjectCreatePredicateBlock createPredicateBlock;
@property (nonatomic, readonly) BOOL usePredicate;

- (id)initWithKey:(NSString*)key value:(id)value objectMapping:(RKObjectMapping*)objectMapping;
- (id)initWithKey:(NSString*)key value:(id)value primaryKeyAttribute:(NSString*)primaryKeyAttribute;
- (id)initWithPrimaryKeyAttribute:(NSString*)primaryKeyAttribute evaluationBlock:(BOOL (^)(id data))block;
- (id)initWithPrimaryKeyAttribute:(NSString*)primaryKeyAttribute createPredicateBlock:(RKDynamicObjectCreatePredicateBlock)block;
- (BOOL)isMatchForData:(id)data;
- (NSString*)matchDescription;


@end
