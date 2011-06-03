//
//  RKManagedObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectMappingOperation.h"
#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"

/*!
 Progressively enhance the RKObjectMappingOperation base class to inject Core Data
 specifics without leaking into the object mapper abstractions
 */
@implementation RKObjectMappingOperation (CoreData)

/*
 Trampoline the initialization through RKManagedObjectMapping so the mapper uses RKManagedObjectMappingOperation
 at the right moments
 */
+ (RKObjectMappingOperation*)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withObjectMapping:(RKObjectMapping*)objectMapping {
    if ([objectMapping isKindOfClass:[RKManagedObjectMapping class]]) {
        return [[[RKManagedObjectMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:destinationObject objectMapping:objectMapping] autorelease];
    }
        
    return [[[RKObjectMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:destinationObject objectMapping:objectMapping] autorelease];
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
            RKObjectRelationshipMapping* mapping = [self.objectMapping mappingForKeyPath:relationshipName];
            NSAssert(mapping, @"Unable to find relationship mapping '%@' to connect by primaryKey", relationshipName);
            NSAssert([mapping isKindOfClass:[RKObjectRelationshipMapping class]], @"Expected mapping for %@ to be a relationship mapping", relationshipName);
            NSAssert([mapping.objectMapping isKindOfClass:[RKManagedObjectMapping class]], @"Can only connect RKManagedObjectMapping relationships");
            NSString* primaryKeyAttributeOfRelatedObject = [(RKManagedObjectMapping*)mapping.objectMapping primaryKeyAttribute];
            NSAssert(primaryKeyAttributeOfRelatedObject, @"Cannot connect relationship: mapping for %@ has no primary key attribute specified", NSStringFromClass(mapping.objectMapping.objectClass));
            id valueOfLocalPrimaryKeyAttribute = [self.destinationObject valueForKey:primaryKeyAttribute];
            if (valueOfLocalPrimaryKeyAttribute) {
                id relatedObject = [mapping.objectMapping.objectClass findFirstByAttribute:primaryKeyAttributeOfRelatedObject withValue:valueOfLocalPrimaryKeyAttribute];
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
