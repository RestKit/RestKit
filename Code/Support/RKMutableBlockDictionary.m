//
//  RKMutableBlockDictionary.m
//  RestKit
//
//  Created by Blake Watters on 8/22/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKMutableBlockDictionary.h"

typedef id (^RKMutableBlockDictionaryValueBlock)();

@interface RKMutableBlockDictionaryBlockValue : NSObject {
    RKMutableBlockDictionaryValueBlock _executionBlock;
}

@property (nonatomic, copy) RKMutableBlockDictionaryValueBlock executionBlock;

+ (id)valueWithBlock:(RKMutableBlockDictionaryValueBlock)executionBlock;

@end

@implementation RKMutableBlockDictionaryBlockValue

@synthesize executionBlock = _executionBlock;

+ (id)valueWithBlock:(RKMutableBlockDictionaryValueBlock)executionBlock
{
    RKMutableBlockDictionaryBlockValue *value = [[self new] autorelease];
    value.executionBlock = executionBlock;

    return value;
}

- (void)setExecutionBlock:(RKMutableBlockDictionaryValueBlock)executionBlock
{
    if (_executionBlock) {
        Block_release(_executionBlock);
        _executionBlock = nil;
    }
    _executionBlock = Block_copy(executionBlock);
}

- (void)dealloc
{
    if (_executionBlock) {
        Block_release(_executionBlock);
        _executionBlock = nil;
    }
    [super dealloc];
}

@end

@implementation RKMutableBlockDictionary

- (id)init
{
    return [self initWithCapacity:0];
}

- (id)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self != nil) {
        _mutableDictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
    }

    return self;
}

- (void)dealloc
{
    [_mutableDictionary release];
    [super dealloc];
}

- (id)copy
{
    return [self mutableCopy];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    [_mutableDictionary setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
    [_mutableDictionary removeObjectForKey:aKey];
}

- (NSUInteger)count
{
    return [_mutableDictionary count];
}

- (id)objectForKey:(id)aKey
{
    return [_mutableDictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [_mutableDictionary keyEnumerator];
}

- (void)setValueWithBlock:(id (^)())block forKey:(NSString *)key
{
    RKMutableBlockDictionaryBlockValue *blockValue = [RKMutableBlockDictionaryBlockValue valueWithBlock:block];
    [self setObject:blockValue forKey:key];
}

- (id)valueForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if (value) {
        if ([value isKindOfClass:[RKMutableBlockDictionaryBlockValue class]]) {
            RKMutableBlockDictionaryBlockValue *blockValue = (RKMutableBlockDictionaryBlockValue *)value;
            return blockValue.executionBlock();
        }

        return value;
    }

    return nil;
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    id value = [super valueForKeyPath:keyPath];
    if (value) {
        if ([value isKindOfClass:[RKMutableBlockDictionaryBlockValue class]]) {
            RKMutableBlockDictionaryBlockValue *blockValue = (RKMutableBlockDictionaryBlockValue *)value;
            return blockValue.executionBlock();
        }

        return value;
    }

    return nil;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    [self setObject:value forKey:key];
}

@end
