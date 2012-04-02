//
//  RKManagedObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters
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
#import "RKLog.h"
#import "RKManagedObjectStore.h"
#import "RKObjectManager.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKManagedObjectMappingOperation

// TODO: Move this to a better home to take exposure out of the mapper
- (Class)operationClassForMapping:(RKObjectMapping *)mapping {
    Class managedMappingClass = NSClassFromString(@"RKManagedObjectMapping");
    Class managedMappingOperationClass = NSClassFromString(@"RKManagedObjectMappingOperation");    
    if (managedMappingClass != nil && [mapping isMemberOfClass:managedMappingClass]) {
        return managedMappingOperationClass;        
    }
    
    return [RKObjectMappingOperation class];
}

- (void)connectRelationship:(NSString *)relationshipName {
    NSDictionary* relationshipsAndPrimaryKeyAttributes = [(RKManagedObjectMapping*)self.objectMapping relationshipsAndPrimaryKeyAttributes];
    NSString* primaryKeyAttribute = [relationshipsAndPrimaryKeyAttributes objectForKey:relationshipName];
    RKObjectRelationshipMapping* relationshipMapping = [self.objectMapping mappingForRelationship:relationshipName];
    BOOL ordered = [[[(RKManagedObjectMapping*)self.objectMapping relationshipsAndOrderings] objectForKey:relationshipName] boolValue];
    id<RKObjectMappingDefinition> mapping = relationshipMapping.mapping;
    NSAssert(mapping, @"Attempted to connect relationship for keyPath '%@' without a relationship mapping defined.");
    if (! [mapping isKindOfClass:[RKManagedObjectMapping class]]) {
        RKLogWarning(@"Can only connect relationships for RKManagedObjectMapping relationships. Found %@: Skipping...", NSStringFromClass([mapping class]));
        return;
    }
    RKManagedObjectMapping* objectMapping = (RKManagedObjectMapping*)mapping;
    NSAssert(relationshipMapping, @"Unable to find relationship mapping '%@' to connect by primaryKey", relationshipName);
    NSAssert([relationshipMapping isKindOfClass:[RKObjectRelationshipMapping class]], @"Expected mapping for %@ to be a relationship mapping", relationshipName);
    NSAssert([relationshipMapping.mapping isKindOfClass:[RKManagedObjectMapping class]], @"Can only connect RKManagedObjectMapping relationships");
    NSString* primaryKeyAttributeOfRelatedObject = [(RKManagedObjectMapping*)objectMapping primaryKeyAttribute];
    NSAssert(primaryKeyAttributeOfRelatedObject, @"Cannot connect relationship: mapping for %@ has no primary key attribute specified", NSStringFromClass(objectMapping.objectClass));
    id valueOfLocalPrimaryKeyAttribute = [self.destinationObject valueForKey:primaryKeyAttribute];
    RKLogDebug(@"Connecting relationship at keyPath '%@' to object with primaryKey attribute '%@'", relationshipName, primaryKeyAttributeOfRelatedObject);
    
    // TODO: We do not want to be using this singleton reference to the object store.
    // Clean this up when we update the Core Data internals
    RKManagedObjectStore* objectStore = [RKObjectManager sharedManager].objectStore;
    NSAssert(objectStore, @"Object store cannot be nil");
    
    if ([valueOfLocalPrimaryKeyAttribute conformsToProtocol:@protocol(NSFastEnumeration)]) {
        RKLogDebug(@"Connecting one to many relationship");
        id newValue;
        if(ordered) {
            newValue = [NSMutableOrderedSet orderedSetWithCapacity:[valueOfLocalPrimaryKeyAttribute count]];
        }
        else {
            newValue = [NSMutableSet setWithCapacity:[valueOfLocalPrimaryKeyAttribute count]];
        }
        for (id key in valueOfLocalPrimaryKeyAttribute) {
            id relatedObject = [objectStore findInstanceOfEntity:objectMapping.entity withPrimaryKeyAttribute:primaryKeyAttributeOfRelatedObject andValue:key create:NO];
            if (relatedObject) {                
                [newValue addObject:relatedObject];
                RKLogTrace(@"Connected relationship '%@' to object with primary key value '%@': %@", relationshipName, key, relatedObject);
            } else {
                RKLogTrace(@"Failed to find object to connect relationship '%@' with primary key value '%@'", relationshipName, key);
            }
        }
        [self.destinationObject setValue:newValue forKey:relationshipName];
    }
    else if (valueOfLocalPrimaryKeyAttribute) {
        RKLogDebug(@"Connecting one to one relationship");
        id relatedObject = [objectStore findInstanceOfEntity:objectMapping.entity withPrimaryKeyAttribute:primaryKeyAttributeOfRelatedObject andValue:valueOfLocalPrimaryKeyAttribute create:NO];
        if (relatedObject) {                
            RKLogTrace(@"Connected relationship '%@' to object with primary key value '%@': %@", relationshipName, valueOfLocalPrimaryKeyAttribute, relatedObject);
        } else {
            RKLogTrace(@"Failed to find object to connect relationship '%@' with primary key value '%@'", relationshipName, valueOfLocalPrimaryKeyAttribute);
        }
        [self.destinationObject setValue:relatedObject forKey:relationshipName];
    } else {
        RKLogTrace(@"Failed to find primary key value for attribute '%@'", primaryKeyAttribute);
    }
}

- (void)connectRelationships {
    if ([self.objectMapping isKindOfClass:[RKManagedObjectMapping class]]) {
        NSDictionary* relationshipsAndPrimaryKeyAttributes = [(RKManagedObjectMapping*)self.objectMapping relationshipsAndPrimaryKeyAttributes];
        for (NSString* relationshipName in relationshipsAndPrimaryKeyAttributes) {
            if (self.queue) {
                RKLogTrace(@"Enqueueing relationship connection using operation queue");
                [self.queue addOperationWithBlock:^{
                    [self connectRelationship:relationshipName];
                }];
            } else {
                [self connectRelationship:relationshipName];
            }
        }
    }
}

- (BOOL)performMapping:(NSError **)error {
    BOOL success = [super performMapping:error];
    [self connectRelationships];
    return success;
}

@end
