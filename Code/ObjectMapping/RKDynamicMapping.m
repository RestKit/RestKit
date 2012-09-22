//
//  RKDynamicMapping.m
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

#import "RKDynamicMapping.h"
#import "RKDynamicMappingMatcher.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitObjectMapping

@interface RKDynamicMapping ()
@property (nonatomic, strong) NSMutableArray *matchers;
@property (nonatomic, copy) RKDynamicMappingDelegateBlock objectMappingForDataBlock;
@end

@implementation RKDynamicMapping

- (id)init
{
    self = [super init];
    if (self) {
        self.matchers = [NSMutableArray new];
    }

    return self;
}

- (void)setObjectMapping:(RKObjectMapping *)objectMapping whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)expectedValue
{
    RKLogDebug(@"Adding dynamic object mapping for key '%@' with value '%@' to destination class: %@", keyPath, expectedValue, NSStringFromClass(objectMapping.objectClass));
    RKDynamicMappingMatcher *matcher = [[RKDynamicMappingMatcher alloc] initWithKeyPath:keyPath expectedValue:expectedValue objectMapping:objectMapping];
    [_matchers addObject:matcher];
}

- (RKObjectMapping *)objectMappingForRepresentation:(NSDictionary *)data
{
    NSAssert([data isKindOfClass:[NSDictionary class]], @"Dynamic object mapping can only be performed on NSDictionary mappables, got %@", NSStringFromClass([data class]));
    RKObjectMapping *mapping = nil;

    RKLogTrace(@"Performing dynamic object mapping for mappable data: %@", data);

    // Consult the declarative matchers first
    for (RKDynamicMappingMatcher *matcher in _matchers) {
        if ([matcher matches:data]) {
            RKLogTrace(@"Found declarative match for matcher: %@.", matcher);
            return matcher.objectMapping;
        }
    }

    // Otherwise consult the block
    if (self.objectMappingForDataBlock) {
        mapping = self.objectMappingForDataBlock(data);
        if (mapping) {
            RKLogTrace(@"Found dynamic delegateBlock match. objectMappingForDataBlock = %@", self.objectMappingForDataBlock);
        }
    }

    return mapping;
}

- (BOOL)isEqualToMapping:(RKMapping *)otherMapping
{
    // Comparison of dynamic mappings is not currently supported
    return NO;
}

@end
