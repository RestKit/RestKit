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
#import "RKObjectMappingMatcher.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitObjectMapping

@interface RKDynamicMapping ()
@property (nonatomic, strong) NSMutableArray *mutableMatchers;
@property (nonatomic, strong) NSArray *possibleObjectMappings;
@property (nonatomic, copy) RKObjectMapping *(^objectMappingForRepresentationBlock)(id representation);
@end

@implementation RKDynamicMapping

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mutableMatchers = [NSMutableArray new];
        self.possibleObjectMappings = [NSArray new];
    }

    return self;
}

- (NSArray *)matchers
{
    return [self.mutableMatchers copy];
}

- (NSArray *)objectMappings
{
    return self.possibleObjectMappings;
}

- (void)addMatcher:(RKObjectMappingMatcher *)matcher
{
    NSParameterAssert(matcher);
    if ([self.mutableMatchers containsObject:matcher]) {
        [self.mutableMatchers removeObject:matcher];
        [self.mutableMatchers insertObject:matcher atIndex:0];
    } else {
        [self.mutableMatchers addObject:matcher];

        NSArray *newPossibleMappings = [matcher possibleObjectMappings];
        if (newPossibleMappings.count > 0) {
            self.possibleObjectMappings = [self.possibleObjectMappings arrayByAddingObjectsFromArray:newPossibleMappings];
        }
    }
}

- (void)removeMatcher:(RKObjectMappingMatcher *)matcher
{
    NSParameterAssert(matcher);

    if ([self.mutableMatchers containsObject:matcher]) {
        NSMutableArray *mappings = [self.possibleObjectMappings mutableCopy];
        for (RKObjectMapping *mapping in [matcher possibleObjectMappings]) {
            /* removeObject will remove *all* instances; if we have dups we just want to remove one */
            NSUInteger idx = [mappings indexOfObject:mapping];
            if (idx != NSNotFound)
                [mappings removeObjectAtIndex:idx];
        }
        self.possibleObjectMappings = [mappings copy];
        [self.mutableMatchers removeObject:matcher];
    }
}

- (RKObjectMapping *)objectMappingForRepresentation:(id)representation
{
    RKObjectMapping *mapping = nil;

    RKLogTrace(@"Performing dynamic object mapping for object representation: %@", representation);

    // Consult the declarative matchers first
    for (RKObjectMappingMatcher *matcher in self.mutableMatchers) {
        if ([matcher matches:representation]) {
            RKLogTrace(@"Found declarative match for matcher: %@.", matcher);
            return matcher.objectMapping;
        }
    }

    // Otherwise consult the block
    if (self.objectMappingForRepresentationBlock) {
        mapping = self.objectMappingForRepresentationBlock(representation);
        if (mapping) RKLogTrace(@"Determined concrete `RKObjectMapping` using object mapping for representation block");
    }

    return mapping;
}

- (BOOL)isEqualToMapping:(RKMapping *)otherMapping
{
    return (self == otherMapping);
}

@end
