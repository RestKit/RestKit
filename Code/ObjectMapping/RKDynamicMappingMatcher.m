//
//  RKDynamicMappingMatcher.m
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKDynamicMappingMatcher.h"


// Implemented in RKMappingOperation
BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface RKDynamicMappingMatcher ()
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong) id value;
@property (nonatomic, copy) BOOL (^isMatchForDataBlock)(id data);
@property (nonatomic, strong, readwrite) RKObjectMapping *objectMapping;
@property (nonatomic, copy, readwrite) NSString *primaryKeyAttribute;
@end

@implementation RKDynamicMappingMatcher

- (id)initWithKey:(NSString *)key value:(id)value objectMapping:(RKObjectMapping *)objectMapping
{
    self = [super init];
    if (self) {
        self.keyPath = key;
        self.value = value;
        self.objectMapping = objectMapping;
    }

    return self;
}

- (id)initWithKey:(NSString *)key value:(id)value primaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    self = [super init];
    if (self) {
        self.keyPath = key;
        self.value = value;
        self.primaryKeyAttribute = primaryKeyAttribute;
    }

    return self;
}

- (id)initWithPrimaryKeyAttribute:(NSString *)primaryKeyAttribute evaluationBlock:(BOOL (^)(id data))block
{
    self = [super init];
    if (self) {
        self.primaryKeyAttribute = primaryKeyAttribute;
        self.isMatchForDataBlock = block;
    }
    return self;
}

- (BOOL)isMatchForData:(id)data
{
    if (self.isMatchForDataBlock) {
        return self.isMatchForDataBlock(data);
    }
    return RKObjectIsValueEqualToValue([data valueForKeyPath:_keyPath], _value);
}

- (NSString *)matchDescription
{
    if (self.isMatchForDataBlock) {
        return @"No description available. Using block to perform match.";
    }
    return [NSString stringWithFormat:@"%@ == %@", _keyPath, _value];
}

@end
