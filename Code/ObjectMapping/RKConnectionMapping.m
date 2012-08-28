//
//  RKConnectionMapping.m
//  RestKit
//
//  Created by Charlie Savage on 5/15/12.
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

#import "RKConnectionMapping.h"
#import "RKEntityMapping.h"
#import "RKObjectManager.h"
#import "RKManagedObjectCaching.h"
#import "RKDynamicMappingMatcher.h"

@interface RKConnectionMapping()
@property (nonatomic, strong) NSString *relationshipName;
@property (nonatomic, strong) NSString *destinationKeyPath;
@property (nonatomic, strong) RKMapping *mapping;
@property (nonatomic, strong) RKDynamicMappingMatcher *matcher;
@property (nonatomic, strong) NSString *sourceKeyPath;
@end

@implementation RKConnectionMapping

@synthesize relationshipName = _relationshipName;
@synthesize destinationKeyPath = _destinationKeyPath;
@synthesize mapping = _mapping;
@synthesize matcher = _matcher;
@synthesize sourceKeyPath = _sourceKeyPath;

+ (RKConnectionMapping *)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping
{
    RKConnectionMapping *mapping = [[self alloc] initWithRelationshipName:relationshipName sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath mapping:objectOrDynamicMapping matcher:nil];
    return mapping;
}

+ (RKConnectionMapping*)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping matcher:(RKDynamicMappingMatcher *)matcher
{
    RKConnectionMapping *mapping = [[self alloc] initWithRelationshipName:relationshipName sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath mapping:objectOrDynamicMapping matcher:matcher];
    return mapping;
}

- (id)initWithRelationshipName:(NSString *)relationshipName sourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath mapping:(RKMapping *)objectOrDynamicMapping matcher:(RKDynamicMappingMatcher *)matcher
{
    self = [super init];
    if (self) {
        self.relationshipName = relationshipName;
        self.sourceKeyPath = sourceKeyPath;
        self.destinationKeyPath = destinationKeyPath;
        self.mapping = objectOrDynamicMapping;
        self.matcher = matcher;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithRelationshipName:self.relationshipName sourceKeyPath:self.sourceKeyPath destinationKeyPath:self.destinationKeyPath mapping:self.mapping matcher:self.matcher];
}


@end
