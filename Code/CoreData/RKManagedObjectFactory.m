//
//  RKManagedObjectFactory.m
//  RestKit
//
//  Created by Blake Watters on 5/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectFactory.h"
#import "RKManagedObjectMapping.h"

@implementation RKManagedObjectFactory

- (id)initWithObjectStore:(RKManagedObjectStore*)objectStore {
    NSAssert(objectStore, @"Object store cannot be nil");
    
    self = [self init];
    if (self) {
        _objectStore = [objectStore retain];
    }
    
    return self;
}

+ (id)objectFactoryWithObjectStore:(RKManagedObjectStore*)objectStore {
    return [[[self alloc] initWithObjectStore:objectStore] autorelease];
}

- (void)dealloc {
    [_objectStore release];
    [super dealloc];
}

- (id)objectWithMapping:(RKObjectMapping*)mapping andData:(id)mappableData {
    NSAssert(mapping, @"Mapping cannot be nil");
    NSAssert(mappableData, @"Mappable data cannot be nil");
    NSAssert(_objectStore, @"Object store cannot be nil");
    
    id object = nil;
    id primaryKeyValue = nil;
    NSString* primaryKeyAttribute;
    
    if ([mapping isKindOfClass:[RKManagedObjectMapping class]]) {        
        NSEntityDescription* entity = [(RKManagedObjectMapping*)mapping entity];
        RKObjectAttributeMapping* primaryKeyAttributeMapping = nil;        
        
        primaryKeyAttribute = [(RKManagedObjectMapping*)mapping primaryKeyAttribute];
        if (primaryKeyAttribute) {
            // If a primary key has been set on the object mapping, find the attribute mapping
            // so that we can extract any existing primary key from the mappable data
            for (RKObjectAttributeMapping* attributeMapping in mapping.attributeMappings) {
                if ([attributeMapping.destinationKeyPath isEqualToString:primaryKeyAttribute]) {
                    primaryKeyAttributeMapping = attributeMapping;
                    break;
                }
            }
            
            // Get the primary key value out of the mappable data (if any)
            NSString* keyPathForPrimaryKeyElement = primaryKeyAttributeMapping.sourceKeyPath;
            if (keyPathForPrimaryKeyElement) {
                primaryKeyValue = [mappableData valueForKeyPath:keyPathForPrimaryKeyElement];
            }
        }
        
        // If we have found the primary key attribute & value, try to find an existing instance to update
        if (primaryKeyAttribute && primaryKeyValue) {                
            object = [_objectStore findOrCreateInstanceOfEntity:entity withPrimaryKeyAttribute:primaryKeyAttribute andValue:primaryKeyValue];
            NSAssert2(object, @"Failed creation of managed object with entity '%@' and primary key value '%@'", entity.name, primaryKeyValue);
        } else {
            object = [[[NSManagedObject alloc] initWithEntity:entity
                               insertIntoManagedObjectContext:_objectStore.managedObjectContext] autorelease];
        }
        
        return object;
    }
    
    return [[mapping.objectClass new] autorelease];
}

@end
