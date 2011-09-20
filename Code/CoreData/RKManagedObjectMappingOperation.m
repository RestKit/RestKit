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
#import "../Support/RKLog.h"

/**
 Progressively enhance the RKObjectMappingOperation base class to inject Core Data
 specifics without leaking into the object mapper abstractions
 */
@implementation RKObjectMappingOperation (CoreData)

/*
 Trampoline the initialization through RKManagedObjectMapping so the mapper uses RKManagedObjectMappingOperation
 at the right moments
 */
+ (RKObjectMappingOperation*)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withMapping:(RKObjectMapping*)objectMapping {
    if ([objectMapping isKindOfClass:[RKManagedObjectMapping class]]) {
        return [[[RKManagedObjectMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:destinationObject mapping:objectMapping] autorelease];
    }
        
    return [[[RKObjectMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:destinationObject mapping:objectMapping] autorelease];
}

@end

@implementation RKManagedObjectMappingOperation

// TODO: Move this to a better home to take exposure out of the mapper
- (Class)operationClassForMapping:(RKObjectMapping*)mapping {
    Class managedMappingClass = NSClassFromString(@"RKManagedObjectMapping");
    Class managedMappingOperationClass = NSClassFromString(@"RKManagedObjectMappingOperation");    
    if (managedMappingClass != nil && [mapping isMemberOfClass:managedMappingClass]) {
        return managedMappingOperationClass;        
    }
    
    return [RKObjectMappingOperation class];
}

- (void)connectRelationships {
    if ([self.objectMapping isKindOfClass:[RKManagedObjectMapping class]]) {
        NSDictionary* relationshipsAndPrimaryKeyAttributes = [(RKManagedObjectMapping*)self.objectMapping relationshipsAndPrimaryKeyAttributes];
        for (NSString* relationshipName in relationshipsAndPrimaryKeyAttributes) {
            NSString* primaryKeyAttribute = [relationshipsAndPrimaryKeyAttributes objectForKey:relationshipName];
            RKObjectRelationshipMapping* relationshipMapping = [self.objectMapping mappingForKeyPath:relationshipName];
            id<RKObjectMappingDefinition> mapping = relationshipMapping.mapping;
            if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
                RKLogWarning(@"Can only connect relationships for RKObjectMapping relationships. Found %@: Skipping...", NSStringFromClass([mapping class]));
                continue;
            }
            RKObjectMapping* objectMapping = (RKObjectMapping*)mapping;
            NSAssert(relationshipMapping, @"Unable to find relationship mapping '%@' to connect by primaryKey", relationshipName);
            NSAssert([relationshipMapping isKindOfClass:[RKObjectRelationshipMapping class]], @"Expected mapping for %@ to be a relationship mapping", relationshipName);
            NSAssert([relationshipMapping.mapping isKindOfClass:[RKManagedObjectMapping class]], @"Can only connect RKManagedObjectMapping relationships");
            NSString* primaryKeyAttributeOfRelatedObject = [(RKManagedObjectMapping*)objectMapping primaryKeyAttribute];
            NSAssert(primaryKeyAttributeOfRelatedObject, @"Cannot connect relationship: mapping for %@ has no primary key attribute specified", NSStringFromClass(objectMapping.objectClass));
            id valueOfLocalPrimaryKeyAttribute = [self.destinationObject valueForKey:primaryKeyAttribute];
            if (valueOfLocalPrimaryKeyAttribute) {
                id relatedObject = [objectMapping.objectClass findFirstByAttribute:primaryKeyAttributeOfRelatedObject withValue:valueOfLocalPrimaryKeyAttribute];
                [self.destinationObject setValue:relatedObject forKey:relationshipName];
                // TODO: Logging
            }
        }
    }
}

- (BOOL)performMapping:(NSError**)error {
    BOOL success = [super performMapping:error];
    [self connectRelationships];
    return success;
}

@end
