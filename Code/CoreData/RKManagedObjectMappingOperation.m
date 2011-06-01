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

@implementation RKManagedObjectMappingOperation

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
