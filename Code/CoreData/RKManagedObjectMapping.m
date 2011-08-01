//
//  RKManagedObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKObjectManager.h"
#import "RKManagedObjectStore.h"

@implementation RKManagedObjectMapping

@synthesize entity = _entity;
@synthesize primaryKeyAttribute = _primaryKeyAttribute;

+ (id)mappingForClass:(Class)objectClass {
    return [self mappingForEntityWithName:NSStringFromClass(objectClass)];
}

+ (RKManagedObjectMapping*)mappingForEntity:(NSEntityDescription*)entity {
    return [[[self alloc] initWithEntity:entity] autorelease];
}

+ (RKManagedObjectMapping*)mappingForEntityWithName:(NSString*)entityName {
    return [self mappingForEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObject managedObjectContext]]];
}

- (id)initWithEntity:(NSEntityDescription*)entity {
    NSAssert(entity, @"Cannot initialize an RKManagedObjectMapping without an entity. Maybe you want RKObjectMapping instead?");
    self = [self init];
    if (self) {
        self.objectClass = NSClassFromString([entity managedObjectClassName]);
        _entity = [entity retain];
    }
    
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _relationshipToPrimaryKeyMappings = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_entity release];
    [_relationshipToPrimaryKeyMappings release];
    [super dealloc];
}

- (NSDictionary*)relationshipsAndPrimaryKeyAttributes {
    return _relationshipToPrimaryKeyMappings;
}

- (void)connectRelationship:(NSString*)relationshipName withObjectForPrimaryKeyAttribute:(NSString*)primaryKeyAttribute {
    NSAssert([_relationshipToPrimaryKeyMappings objectForKey:relationshipName] == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", relationshipName);
    [_relationshipToPrimaryKeyMappings setObject:primaryKeyAttribute forKey:relationshipName];
}

- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString*)firstRelationshipName, ... {
    va_list args;
    va_start(args, firstRelationshipName);
    for (NSString* relationshipName = firstRelationshipName; relationshipName != nil; relationshipName = va_arg(args, NSString*)) {
		NSString* primaryKeyAttribute = va_arg(args, NSString*);
        NSAssert(primaryKeyAttribute != nil, @"Cannot connect a relationship without an attribute containing the primary key");
        [self connectRelationship:relationshipName withObjectForPrimaryKeyAttribute:primaryKeyAttribute];
        // TODO: Raise proper exception here, argument error...
    }
    va_end(args);
}

- (id)defaultValueForMissingAttribute:(NSString*)attributeName {
    NSAttributeDescription *desc = [[self.entity attributesByName] valueForKey:attributeName];
    return [desc defaultValue];
}

- (id)mappableObjectForData:(id)mappableData {    
    NSAssert(mappableData, @"Mappable data cannot be nil");
    
    // TODO: We do not want to be using this singleton reference to the object store.
    // Clean this up when we update the Core Data internals
    RKManagedObjectStore* objectStore = [RKObjectManager sharedManager].objectStore;
    NSAssert(objectStore, @"Object store cannot be nil");
    
    id object = nil;
    id primaryKeyValue = nil;
    NSString* primaryKeyAttribute;
    
    NSEntityDescription* entity = [self entity];
    RKObjectAttributeMapping* primaryKeyAttributeMapping = nil;        
    
    primaryKeyAttribute = [self primaryKeyAttribute];
    if (primaryKeyAttribute) {
        // If a primary key has been set on the object mapping, find the attribute mapping
        // so that we can extract any existing primary key from the mappable data
        for (RKObjectAttributeMapping* attributeMapping in self.attributeMappings) {
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
        object = [objectStore findOrCreateInstanceOfEntity:entity withPrimaryKeyAttribute:primaryKeyAttribute andValue:primaryKeyValue];
        NSAssert2(object, @"Failed creation of managed object with entity '%@' and primary key value '%@'", entity.name, primaryKeyValue);
    } else {
        object = [[[NSManagedObject alloc] initWithEntity:entity
                           insertIntoManagedObjectContext:objectStore.managedObjectContext] autorelease];
    }
    
    return object;
}

@end
