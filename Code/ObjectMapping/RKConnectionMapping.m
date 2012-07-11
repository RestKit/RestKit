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
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectMapping.h"
#import "RKObjectManager.h"
#import "RKManagedObjectCaching.h"
#import "RKDynamicObjectMappingMatcher.h"

@interface RKConnectionMapping()
@property (nonatomic, retain) NSString *relationshipName;
@property (nonatomic, retain) NSString *destinationKeyPath;
@property (nonatomic, retain) RKObjectMappingDefinition *mapping;
@property (nonatomic, retain) RKDynamicObjectMappingMatcher *matcher;
@property (nonatomic, retain) NSString *sourceKeyPath;
@end

@implementation RKConnectionMapping

@synthesize relationshipName = _relationshipName;
@synthesize destinationKeyPath = _destinationKeyPath;
@synthesize mapping = _mapping;
@synthesize matcher = _matcher;
@synthesize sourceKeyPath = _sourceKeyPath;

+ (RKConnectionMapping *)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping {
    RKConnectionMapping *mapping = [[self alloc] initWithRelationshipName:relationshipName sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath mapping:objectOrDynamicMapping matcher:nil];
    return [mapping autorelease];
}

+ (RKConnectionMapping*)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKDynamicObjectMappingMatcher *)matcher matcher:(RKObjectMappingDefinition *)objectOrDynamicMapping {
    RKConnectionMapping *mapping = [[self alloc] initWithRelationshipName:relationshipName sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath mapping:objectOrDynamicMapping matcher:matcher];
    return [mapping autorelease];
}

- (id)initWithRelationshipName:(NSString *)relationshipName sourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath mapping:(RKObjectMappingDefinition *)objectOrDynamicMapping matcher:(RKDynamicObjectMappingMatcher *)matcher {
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

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithRelationshipName:self.relationshipName sourceKeyPath:self.sourceKeyPath destinationKeyPath:self.destinationKeyPath mapping:self.mapping matcher:self.matcher];
}

- (void)dealloc {
    self.relationshipName = nil;
    self.destinationKeyPath = nil;
    self.mapping = nil;
    self.matcher = nil;
    self.sourceKeyPath = nil;
    [super dealloc];
}

- (BOOL)isToMany:(NSManagedObject *)source {
    NSEntityDescription *entity = [source entity];
    NSDictionary *relationships = [entity relationshipsByName];
    NSRelationshipDescription *relationship = [relationships objectForKey:self.relationshipName];
    return relationship.isToMany;
}

- (NSManagedObject *)findOneConnected:(NSManagedObject *)source sourceValue:(id)sourceValue  {
    RKManagedObjectMapping* objectMapping = (RKManagedObjectMapping *)self.mapping;
    NSObject<RKManagedObjectCaching> *cache = [[objectMapping objectStore] cacheStrategy];
    NSManagedObjectContext *context = [[objectMapping objectStore] managedObjectContextForCurrentThread];
    return [cache findInstanceOfEntity:objectMapping.entity withPrimaryKeyAttribute:self.destinationKeyPath value:sourceValue inManagedObjectContext:context];
}

- (NSMutableSet *)findAllConnected:(NSManagedObject *)source sourceValue:(id)sourceValue {
    NSMutableSet *result = [NSMutableSet set];

    RKManagedObjectMapping* objectMapping = (RKManagedObjectMapping *)self.mapping;
    NSObject<RKManagedObjectCaching> *cache = [[objectMapping objectStore] cacheStrategy];
    NSManagedObjectContext *context = [[objectMapping objectStore] managedObjectContextForCurrentThread];

    id values = nil;
    if ([sourceValue conformsToProtocol:@protocol(NSFastEnumeration)]) {
        values = sourceValue;
    } else {
        values = [NSArray arrayWithObject:sourceValue];
    }

    for (id value in values) {
        NSArray *objects = [cache findInstancesOfEntity:objectMapping.entity withPrimaryKeyAttribute:self.destinationKeyPath value:value inManagedObjectContext:context];
        [result addObjectsFromArray:objects];
    }
    return result;
}

- (BOOL)checkMatcher:(NSManagedObject *)source {
    if (!self.matcher) {
        return YES;
    } else {
        return [self.matcher isMatchForData:source];
    }
}

- (id)findConnected:(NSManagedObject *)source {
    if ([self checkMatcher:source])
    {
        BOOL isToMany = [self isToMany:source];
        id sourceValue = [source valueForKey:self.sourceKeyPath];
        if (isToMany) {
            return [self findAllConnected:source sourceValue:sourceValue];
        } else {
            return [self findOneConnected:source sourceValue:sourceValue];
        }
    } else {
        return nil;
    }
}

@end
