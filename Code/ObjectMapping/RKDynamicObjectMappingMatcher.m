//
//  RKDynamicObjectMappingMatcher.m
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKDynamicObjectMappingMatcher.h"


// Implemented in RKObjectMappingOperation
BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKDynamicObjectMappingMatcher

@synthesize objectMapping = _objectMapping;
@synthesize primaryKeyAttribute = _primaryKeyAttribute;
@synthesize createPredicateBlock = _createPredicateBlock;

- (id)initWithKey:(NSString*)key value:(id)value objectMapping:(RKObjectMapping*)objectMapping {
    self = [super init];
    if (self) {
        _keyPath = [key retain];
        _value = [value retain];
        _objectMapping = [objectMapping retain];
        _createPredicateBlock = NULL;
    }

    return self;
}

- (id)initWithKey:(NSString*)key value:(id)value primaryKeyAttribute:(NSString*)primaryKeyAttribute {
    self = [super init];
    if (self) {
        _keyPath = [key retain];
        _value = [value retain];
        _primaryKeyAttribute = [primaryKeyAttribute retain];
        _createPredicateBlock = NULL;
    }

    return self;
}

- (id)initWithPrimaryKeyAttribute:(NSString*)primaryKeyAttribute evaluationBlock:(BOOL (^)(id data))block {
    self = [super init];
    if (self) {
        _primaryKeyAttribute = [primaryKeyAttribute retain];
        _isMatchForDataBlock = Block_copy(block);
        _createPredicateBlock = NULL;
    }
    return self;
}

- (id)initWithPrimaryKeyAttribute:(NSString*)primaryKeyAttribute createPredicateBlock:(RKDynamicObjectCreatePredicateBlock)block {
    if((self = [super init]))
    {
        _primaryKeyAttribute = [primaryKeyAttribute retain];
        _createPredicateBlock = Block_copy(block);
    }
    return self;
}

- (void)dealloc {
    [_keyPath release];
    [_value release];
    [_objectMapping release];
    [_primaryKeyAttribute release];
    if (_isMatchForDataBlock) {
        Block_release(_isMatchForDataBlock);
    }
    if(_createPredicateBlock) {
        Block_release(_createPredicateBlock);
    }
    [super dealloc];
}

- (BOOL)isMatchForData:(id)data {
    NSAssert(!self.usePredicate, @"Cannot call isMatchForData on a predicate-yielding dynamic matcher - call predicateForRelationship instead");
    if (_isMatchForDataBlock) {
        return _isMatchForDataBlock(data);
    }
    return RKObjectIsValueEqualToValue([data valueForKeyPath:_keyPath], _value);
}

- (NSString*)matchDescription {
    if (_isMatchForDataBlock) {
        return @"No description available. Using block to perform match.";
    }
    return [NSString stringWithFormat:@"%@ == %@", _keyPath, _value];
}

- (BOOL)usePredicate {
    return _createPredicateBlock != NULL;
}


@end
