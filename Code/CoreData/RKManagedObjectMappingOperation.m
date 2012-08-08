//
//  RKManagedObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
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

#import "RKManagedObjectMappingOperation.h"
#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKDynamicObjectMappingMatcher.h"
#import "RKManagedObjectCaching.h"
#import "RKManagedObjectStore.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKManagedObjectMappingOperation

- (void)connectRelationship:(NSString *)relationshipName
{
    NSDictionary *relationshipsAndPrimaryKeyAttributes = [(RKManagedObjectMapping *)self.objectMapping relationshipsAndPrimaryKeyAttributes];
    id primaryKeyObject = [relationshipsAndPrimaryKeyAttributes objectForKey:relationshipName];
    NSString *primaryKeyAttribute = nil;
    if ([primaryKeyObject isKindOfClass:[RKDynamicObjectMappingMatcher class]]) {
        RKLogTrace(@"Found a dynamic matcher attempting to connect relationshipName: %@", relationshipName);
        RKDynamicObjectMappingMatcher *matcher = (RKDynamicObjectMappingMatcher *)primaryKeyObject;
        if ([matcher isMatchForData:self.destinationObject]) {
            primaryKeyAttribute = matcher.primaryKeyAttribute;
            RKLogTrace(@"Dynamic matched succeeded. Proceeding to connect relationshipName '%@' using primaryKeyAttribute '%@'", relationshipName, primaryKeyAttribute);
        } else {
            RKLogTrace(@"Dynamic matcher match failed. Skipping connection of relationshipName: %@", relationshipName);
            return;
        }
    } else if ([primaryKeyObject isKindOfClass:[NSString class]]) {
        primaryKeyAttribute = (NSString *)primaryKeyObject;
    }
    NSAssert(primaryKeyAttribute, @"Cannot connect relationship without primaryKeyAttribute");

    RKObjectRelationshipMapping *relationshipMapping = [self.objectMapping mappingForRelationship:relationshipName];
    RKObjectMappingDefinition *mapping = relationshipMapping.mapping;
    NSAssert(mapping, @"Attempted to connect relationship for keyPath '%@' without a relationship mapping defined.", relationshipName);
    if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
        RKLogWarning(@"Can only connect relationships for RKObjectMapping relationships. Found %@: Skipping...", NSStringFromClass([mapping class]));
        return;
    }
    RKManagedObjectMapping *objectMapping = (RKManagedObjectMapping *)mapping;
    NSAssert(relationshipMapping, @"Unable to find relationship mapping '%@' to connect by primaryKey", relationshipName);
    NSAssert([relationshipMapping isKindOfClass:[RKObjectRelationshipMapping class]], @"Expected mapping for %@ to be a relationship mapping", relationshipName);
    NSAssert([relationshipMapping.mapping isKindOfClass:[RKManagedObjectMapping class]], @"Can only connect RKManagedObjectMapping relationships");
    NSString *primaryKeyAttributeOfRelatedObject = [(RKManagedObjectMapping *)objectMapping primaryKeyAttribute];
    NSAssert(primaryKeyAttributeOfRelatedObject, @"Cannot connect relationship: mapping for %@ has no primary key attribute specified", NSStringFromClass(objectMapping.objectClass));
    id valueOfLocalPrimaryKeyAttribute = [self.destinationObject valueForKey:primaryKeyAttribute];
    if (valueOfLocalPrimaryKeyAttribute) {
        id relatedObject = nil;
        if ([valueOfLocalPrimaryKeyAttribute conformsToProtocol:@protocol(NSFastEnumeration)]) {
            RKLogTrace(@"Connecting has-many relationship at keyPath '%@' to object with primaryKey attribute '%@'", relationshipName, primaryKeyAttributeOfRelatedObject);

            // Implemented for issue 284 - https://github.com/RestKit/RestKit/issues/284
            relatedObject = [NSMutableSet set];
            NSObject<RKManagedObjectCaching> *cache = [[(RKManagedObjectMapping *)[self objectMapping] objectStore] cacheStrategy];
            for (id foreignKey in valueOfLocalPrimaryKeyAttribute) {
                id searchResult = [cache findInstanceOfEntity:objectMapping.entity withPrimaryKeyAttribute:primaryKeyAttributeOfRelatedObject value:foreignKey inManagedObjectContext:[[(RKManagedObjectMapping *)[self objectMapping] objectStore] managedObjectContextForCurrentThread]];
                if (searchResult) {
                    [relatedObject addObject:searchResult];
                }
            }
        } else {
            RKLogTrace(@"Connecting has-one relationship at keyPath '%@' to object with primaryKey attribute '%@'", relationshipName, primaryKeyAttributeOfRelatedObject);

            // Normal foreign key
            NSObject<RKManagedObjectCaching> *cache = [[(RKManagedObjectMapping *)[self objectMapping] objectStore] cacheStrategy];
            relatedObject = [cache findInstanceOfEntity:objectMapping.entity withPrimaryKeyAttribute:primaryKeyAttributeOfRelatedObject value:valueOfLocalPrimaryKeyAttribute inManagedObjectContext:[self.destinationObject managedObjectContext]];
        }
        if (relatedObject) {
            RKLogDebug(@"Connected relationship '%@' to object with primary key value '%@': %@", relationshipName, valueOfLocalPrimaryKeyAttribute, relatedObject);
        } else {
            RKLogDebug(@"Failed to find instance of '%@' to connect relationship '%@' with primary key value '%@'", [[objectMapping entity] name], relationshipName, valueOfLocalPrimaryKeyAttribute);
        }
        if ([relatedObject isKindOfClass:[NSManagedObject class]]) {
            // Sanity check the managed object contexts
            NSAssert([[(NSManagedObject *)self.destinationObject managedObjectContext] isEqual:[(NSManagedObject *)relatedObject managedObjectContext]], nil);
        }
        RKLogTrace(@"setValue of %@ forKeyPath %@", relatedObject, relationshipName);
        [self.destinationObject setValue:relatedObject forKeyPath:relationshipName];
    } else {
        RKLogTrace(@"Failed to find primary key value for attribute '%@'", primaryKeyAttribute);
    }
}

- (void)connectRelationships
{
    NSDictionary *relationshipsAndPrimaryKeyAttributes = [(RKManagedObjectMapping *)self.objectMapping relationshipsAndPrimaryKeyAttributes];
    RKLogTrace(@"relationshipsAndPrimaryKeyAttributes: %@", relationshipsAndPrimaryKeyAttributes);
    for (NSString *relationshipName in relationshipsAndPrimaryKeyAttributes) {
        if (self.queue) {
            RKLogTrace(@"Enqueueing relationship connection using operation queue");
            __block RKManagedObjectMappingOperation *selfRef = self;
            [self.queue addOperationWithBlock:^{
                [selfRef connectRelationship:relationshipName];
            }];
        } else {
            [self connectRelationship:relationshipName];
        }
    }
}

- (BOOL)performMapping:(NSError **)error
{
    BOOL success = [super performMapping:error];
    if ([self.objectMapping isKindOfClass:[RKManagedObjectMapping class]]) {
        /**
         NOTE: Processing the pending changes here ensures that the managed object context generates observable
         callbacks that are important for maintaining any sort of cache that is consistent within a single
         object mapping operation. As the MOC is only saved when the aggregate operation is processed, we must
         manually invoke processPendingChanges to prevent recreating objects with the same primary key.
         See https://github.com/RestKit/RestKit/issues/661
         */
        [self connectRelationships];
    }
    return success;
}

@end
