//
//  RKDynamicObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
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

#import "RKDynamicObjectMapping.h"
#import "RKDynamicObjectMappingMatcher.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitObjectMapping


@implementation RKDynamicObjectMapping

@synthesize delegate = _delegate;
@synthesize objectMappingForDataBlock = _objectMappingForDataBlock;

+ (RKDynamicObjectMapping *)dynamicMapping
{
    return [[self new] autorelease];
}

#if NS_BLOCKS_AVAILABLE

+ (RKDynamicObjectMapping *)dynamicMappingUsingBlock:(void(^)(RKDynamicObjectMapping *))block
{
    RKDynamicObjectMapping *mapping = [self dynamicMapping];
    block(mapping);
    return mapping;
}

+ (RKDynamicObjectMapping *)dynamicMappingWithBlock:(void(^)(RKDynamicObjectMapping *))block
{
    return [self dynamicMappingUsingBlock:block];
}

#endif

- (id)init
{
    self = [super init];
    if (self) {
        _matchers = [NSMutableArray new];
    }

    return self;
}

- (void)dealloc
{
    [_matchers release];
    [super dealloc];
}

- (void)setObjectMapping:(RKObjectMapping *)objectMapping whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value
{
    RKLogDebug(@"Adding dynamic object mapping for key '%@' with value '%@' to destination class: %@", keyPath, value, NSStringFromClass(objectMapping.objectClass));
    RKDynamicObjectMappingMatcher *matcher = [[RKDynamicObjectMappingMatcher alloc] initWithKey:keyPath value:value objectMapping:objectMapping];
    [_matchers addObject:matcher];
    [matcher release];
}

- (RKObjectMapping *)objectMappingForDictionary:(NSDictionary *)data
{
    NSAssert([data isKindOfClass:[NSDictionary class]], @"Dynamic object mapping can only be performed on NSDictionary mappables, got %@", NSStringFromClass([data class]));
    RKObjectMapping *mapping = nil;

    RKLogTrace(@"Performing dynamic object mapping for mappable data: %@", data);

    // Consult the declarative matchers first
    for (RKDynamicObjectMappingMatcher *matcher in _matchers) {
        if ([matcher isMatchForData:data]) {
            RKLogTrace(@"Found declarative match for data: %@.", [matcher matchDescription]);
            return matcher.objectMapping;
        }
    }

    // Otherwise consult the delegates
    if (self.delegate) {
        mapping = [self.delegate objectMappingForData:data];
        if (mapping) {
            RKLogTrace(@"Found dynamic delegate match. Delegate = %@", self.delegate);
            return mapping;
        }
    }

    if (self.objectMappingForDataBlock) {
        mapping = self.objectMappingForDataBlock(data);
        if (mapping) {
            RKLogTrace(@"Found dynamic delegateBlock match. objectMappingForDataBlock = %@", self.objectMappingForDataBlock);
        }
    }

    return mapping;
}

@end

// Compatibility alias...
@implementation RKObjectDynamicMapping
@end
