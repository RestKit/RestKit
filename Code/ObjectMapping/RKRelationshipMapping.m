//
//  RKRelationshipMapping.m
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
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

#import "RKRelationshipMapping.h"

@implementation RKRelationshipMapping

@synthesize mapping = _mapping;
@synthesize reversible = _reversible;

+ (RKRelationshipMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(id)objectOrDynamicMapping reversible:(BOOL)reversible
{
    RKRelationshipMapping *relationshipMapping = (RKRelationshipMapping *)[self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    relationshipMapping.reversible = reversible;
    relationshipMapping.mapping = objectOrDynamicMapping;
    return relationshipMapping;
}

+ (RKRelationshipMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(id)objectOrDynamicMapping
{
    return [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping reversible:YES];
}

- (id)copyWithZone:(NSZone *)zone
{
    RKRelationshipMapping *copy = [super copyWithZone:zone];
    copy.mapping = self.mapping;
    copy.reversible = self.reversible;
    return copy;
}

- (void)dealloc
{
    [_mapping release];
    [super dealloc];
}

- (BOOL)isEqualToMapping:(RKRelationshipMapping *)otherMapping
{
    if (! [otherMapping isMemberOfClass:[RKRelationshipMapping class]]) return NO;
    if (! [super isEqualToMapping:otherMapping]) return NO;
    if (self.mapping == nil && otherMapping.mapping == nil) return YES;

    return [self.mapping isEqualToMapping:otherMapping.mapping];
}

@end
