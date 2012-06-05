//
//  RKObjectElementMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import "RKObjectAttributeMapping.h"

extern NSString * const RKObjectMappingNestingAttributeKeyName;

@implementation RKObjectAttributeMapping

@synthesize sourceKeyPath = _sourceKeyPath;
@synthesize destinationKeyPath = _destinationKeyPath;

/**
 @private
 */
- (id)initWithSourceKeyPath:(NSString *)sourceKeyPath andDestinationKeyPath:(NSString *)destinationKeyPath
{
    NSAssert(sourceKeyPath != nil, @"Cannot define an element mapping an element name to map from");
    NSAssert(destinationKeyPath != nil, @"Cannot define an element mapping without a property to apply the value to");
    self = [super init];
    if (self) {
        _sourceKeyPath = [sourceKeyPath retain];
        _destinationKeyPath = [destinationKeyPath retain];
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    RKObjectAttributeMapping *copy = [[[self class] allocWithZone:zone] initWithSourceKeyPath:self.sourceKeyPath andDestinationKeyPath:self.destinationKeyPath];
    return copy;
}

- (void)dealloc
{
    [_sourceKeyPath release];
    [_destinationKeyPath release];

    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"RKObjectKeyPathMapping: %@ => %@", self.sourceKeyPath, self.destinationKeyPath];
}

+ (RKObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath
{
    RKObjectAttributeMapping *mapping = [[self alloc] initWithSourceKeyPath:sourceKeyPath andDestinationKeyPath:destinationKeyPath];
    return [mapping autorelease];
}

- (BOOL)isMappingForKeyOfNestedDictionary
{
    return ([self.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]);
}

@end
