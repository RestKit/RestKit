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
    
    Class mappableClass = mapping.objectClass;
    if ([mappableClass isSubclassOfClass:[NSManagedObject class]]) {
        id primaryKeyValue = nil;
        NSString* primaryKeyAttribute;
        
        // Handle an RKManagedObjectMapping
        if ([mapping isKindOfClass:[RKManagedObjectMapping class]]) {
            RKObjectAttributeMapping* primaryKeyAttributeMapping = nil;        
            
            primaryKeyAttribute = [(RKManagedObjectMapping*)mapping primaryKeyAttribute];
            if (primaryKeyAttribute) {
                for (RKObjectAttributeMapping* attributeMapping in mapping.attributeMappings) {
                    if ([attributeMapping.destinationKeyPath isEqualToString:primaryKeyAttribute]) {
                        primaryKeyAttributeMapping = attributeMapping;
                        break;
                    }
                }
                
                NSString* keyPathForPrimaryKeyElement = primaryKeyAttributeMapping.sourceKeyPath;
                if (keyPathForPrimaryKeyElement) {
                    primaryKeyValue = [mappableData valueForKey:keyPathForPrimaryKeyElement];
                }
            }
        }        
        
        // Handle managed objects without a primary key
        id object = nil;
        if (primaryKeyAttribute && primaryKeyValue) {
            object = [_objectStore findOrCreateInstanceOfManagedObject:mappableClass withPrimaryKeyAttribute:primaryKeyAttribute andValue:primaryKeyValue];
            NSAssert2(object, @"Failed creation of managed object with class '%@' and primary key value '%@'", NSStringFromClass(mappableClass), primaryKeyValue);
        } else {
            object = [mappableClass performSelector:@selector(object)];
        }
        // TODO: Error logging...
        return object;
    } else {
        return [[mappableClass new] autorelease];
    }
    
    return nil;
}

@end
