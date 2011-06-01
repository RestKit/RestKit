//
//  RKManagedObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"

@implementation RKManagedObjectMapping

@synthesize primaryKeyAttribute = _primaryKeyAttribute;

+ (RKManagedObjectMapping*)mappingForEntity:(NSEntityDescription*)entity {
    Class mappableClass = NSClassFromString([entity managedObjectClassName]);
    return [self mappingForClass:mappableClass];
}

+ (RKManagedObjectMapping*)mappingForEntityWithName:(NSString*)entityName {
    return [self mappingForEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObject managedObjectContext]]];
}

- (id)init {
    self = [super init];
    if (self) {
        _relationshipToPrimaryKeyMappings = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
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

@end
