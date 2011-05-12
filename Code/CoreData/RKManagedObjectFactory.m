//
//  RKManagedObjectFactory.m
//  RestKit
//
//  Created by Blake Watters on 5/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectFactory.h"

@implementation RKManagedObjectFactory

- (id)initWithObjectStore:(RKManagedObjectStore*)objectStore {
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
    Class mappableClass = mapping.objectClass;
    if (mappableClass) {
        Class nsManagedObjectClass = NSClassFromString(@"NSManagedObject");
        if (nsManagedObjectClass && [mappableClass isSubclassOfClass:nsManagedObjectClass]) {
            RKObjectAttributeMapping* primaryKeyAttributeMapping = nil;
            id primaryKeyValue = nil;
            
            NSString* primaryKeyProperty = [mappableClass performSelector:@selector(primaryKeyProperty)];
            for (RKObjectAttributeMapping* attributeMapping in mapping.attributeMappings) {
                if ([attributeMapping.destinationKeyPath isEqualToString:primaryKeyProperty]) {
                    primaryKeyAttributeMapping = attributeMapping;
                    break;
                }
            }
            
            NSString* keyPathForPrimaryKeyElement = primaryKeyAttributeMapping.sourceKeyPath;
            if (keyPathForPrimaryKeyElement) {
                primaryKeyValue = [mappableData valueForKey:keyPathForPrimaryKeyElement];
            }
            
            return [_objectStore findOrCreateInstanceOfManagedObject:mappableClass withPrimaryKeyValue:primaryKeyValue];
        } else {
            return [[mappableClass new] autorelease];
        }
    }
    
    return nil;
}

@end
