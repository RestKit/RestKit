//
//  RKEntityMapping.m
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

#import "RKEntityMapping.h"
#import "RKManagedObjectStore.h"
#import "RKDynamicMappingMatcher.h"
#import "RKPropertyInspector+CoreData.h"
#import "RKLog.h"
#import "RKRelationshipMapping.h"
#import "RKObjectUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

static BOOL entityIdentifierInferenceEnabled = YES;

static void RKInferIdentifiersForEntityMapping(RKEntityMapping *entityMapping)
{
    if (! [RKEntityMapping isEntityIdentifierInferenceEnabled]) return;
    
    entityMapping.entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entityMapping.entity];
    [[entityMapping.entity relationshipsByName] enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationship, BOOL *stop) {
        RKEntityIdentifier *entityIdentififer = [RKEntityIdentifier inferredIdentifierForEntity:relationship.destinationEntity];
        if (entityIdentififer) {
            [entityMapping setEntityIdentifier:entityIdentififer forRelationship:relationshipName];
        }
    }];
}

@interface RKObjectMapping (Private)
- (NSString *)transformSourceKeyPath:(NSString *)keyPath;
@end

@interface RKEntityMapping ()
@property (nonatomic, weak, readwrite) Class objectClass;
@property (nonatomic, strong) NSMutableArray *mutableConnections;
@property (nonatomic, strong) NSMutableDictionary *relationshipNamesToEntityIdentifiers;
@end

@implementation RKEntityMapping

+ (id)mappingForClass:(Class)objectClass
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must provide a managedObjectStore. Invoke mappingForClass:inManagedObjectStore: instead."]
                                 userInfo:nil];
}

+ (id)mappingForEntityForName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    NSEntityDescription *entity = [[managedObjectStore.managedObjectModel entitiesByName] objectForKey:entityName];
    return [[self alloc] initWithEntity:entity];
}

- (id)initWithEntity:(NSEntityDescription *)entity
{
    NSAssert(entity, @"Cannot initialize an RKEntityMapping without an entity. Maybe you want RKObjectMapping instead?");
    Class objectClass = NSClassFromString([entity managedObjectClassName]);
    NSAssert(objectClass, @"Cannot initialize an entity mapping for an entity with a nil managed object class: Got nil class for managed object class name '%@'. Maybe you forgot to add the class files to your target?", [entity managedObjectClassName]);
    self = [self initWithClass:objectClass];
    if (self) {
        self.entity = entity;
        RKInferIdentifiersForEntityMapping(self);
    }

    return self;
}

- (id)initWithClass:(Class)objectClass
{
    self = [super initWithClass:objectClass];
    if (self) {
        self.mutableConnections = [NSMutableArray array];
        self.relationshipNamesToEntityIdentifiers = [NSMutableDictionary dictionary];
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    RKEntityMapping *copy = [super copyWithZone:zone];
    copy.entityIdentifier = [self.entityIdentifier copy];
    
    for (RKConnectionDescription *connection in self.connections) {
        [copy addConnection:[connection copy]];
    }
    
    return copy;
}

- (RKConnectionDescription *)connectionForRelationship:(id)relationshipOrName
{
    NSAssert([relationshipOrName isKindOfClass:[NSString class]] || [relationshipOrName isKindOfClass:[NSRelationshipDescription class]], @"Relationship specifier must be a name or a relationship description");
    NSString *relationshipName = [relationshipOrName isKindOfClass:[NSRelationshipDescription class]] ? [(NSRelationshipDescription *)relationshipOrName name] : relationshipOrName;
    for (RKConnectionDescription *connection in self.connections) {
        if ([[connection.relationship name] isEqualToString:relationshipName]) {
            return connection;
        }
    }
    return nil;
}

- (void)addConnection:(RKConnectionDescription *)connection
{
    NSParameterAssert(connection);
    RKConnectionDescription *existingConnection = [self connectionForRelationship:connection.relationship];
    NSAssert(existingConnection == nil, @"Cannot add connection: An existing connection already exists for the '%@' relationship.", connection.relationship.name);
    NSAssert(self.mutableConnections, @"self.mutableConnections should not be nil");
    [self.mutableConnections addObject:connection];
}

- (void)removeConnection:(RKConnectionDescription *)connection
{
    [self.mutableConnections removeObject:connection];
}

- (NSArray *)connections
{
    return [NSArray arrayWithArray:self.mutableConnections];
}

- (void)addConnectionForRelationship:(id)relationshipOrName connectedBy:(id)connectionSpecifier
{
    NSRelationshipDescription *relationship = [relationshipOrName isKindOfClass:[NSRelationshipDescription class]] ? relationshipOrName : [self.entity relationshipsByName][relationshipOrName];
    NSAssert(relationship, @"No relatiobship was found named '%@' in the '%@' entity", relationshipOrName, [self.entity name]);
    RKConnectionDescription *connection = nil;
    if ([connectionSpecifier isKindOfClass:[NSString class]]) {
        NSString *sourceAttribute = connectionSpecifier;
        NSString *destinationAttribute = [self transformSourceKeyPath:sourceAttribute];
        connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:@{ sourceAttribute: destinationAttribute }];
    } else if ([connectionSpecifier isKindOfClass:[NSArray class]]) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:[connectionSpecifier count]];
        for (NSString *sourceAttribute in connectionSpecifier) {
            NSString *destinationAttribute = [self transformSourceKeyPath:sourceAttribute];
            attributes[sourceAttribute] = destinationAttribute;
        }
        connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:attributes];
    } else if ([connectionSpecifier isKindOfClass:[NSDictionary class]]) {
        connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:connectionSpecifier];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Connections can only be described using `NSString`, `NSArray`, or `NSDictionary` objects. Instead, got: %@", connectionSpecifier];
    }
    
    [self.mutableConnections addObject:connection];
}

- (void)setEntityIdentifier:(RKEntityIdentifier *)entityIdentifier
{
    NSAssert(entityIdentifier == nil || [entityIdentifier.entity isKindOfEntity:self.entity], @"Invalid entity identifier value: The identifier given is for the '%@' entity.", [entityIdentifier.entity name]);
    _entityIdentifier = entityIdentifier;
}

- (void)setEntityIdentifier:(RKEntityIdentifier *)entityIdentifier forRelationship:(NSString *)relationshipName
{
    NSRelationshipDescription *relationship = [self.entity relationshipsByName][relationshipName];
    NSAssert(relationship, @"Cannot set entity identififer for relationship '%@': no relationship found for that name.", relationshipName);
    NSAssert([[relationship destinationEntity] isKindOfEntity:entityIdentifier.entity], @"Cannot set entity identifier for relationship '%@': the given relationship identifier is for the '%@' entity, but the '%@' entity was expected.", relationshipName, [entityIdentifier.entity name], [[relationship destinationEntity] name]);
    self.relationshipNamesToEntityIdentifiers[relationshipName] = entityIdentifier;
}

- (RKEntityIdentifier *)entityIdentifierForRelationship:(NSString *)relationshipName
{
    RKEntityIdentifier *entityIdentifier = self.relationshipNamesToEntityIdentifiers[relationshipName];
    if (! entityIdentifier) {
        RKRelationshipMapping *relationshipMapping = [self propertyMappingsByDestinationKeyPath][relationshipName];
        entityIdentifier = [relationshipMapping.mapping isKindOfClass:[RKEntityIdentifier class]] ? [(RKEntityMapping *)relationshipMapping.mapping entityIdentifier] : nil;
    }
    
    return entityIdentifier;
}

- (id)defaultValueForAttribute:(NSString *)attributeName
{
    NSAttributeDescription *desc = [[self.entity attributesByName] valueForKey:attributeName];
    return [desc defaultValue];
}

- (Class)classForProperty:(NSString *)propertyName
{
    Class propertyClass = [super classForProperty:propertyName];
    if (! propertyClass) {
        propertyClass = [[RKPropertyInspector sharedInspector] classForPropertyNamed:propertyName ofEntity:self.entity];
    }

    return propertyClass;
}

+ (void)setEntityIdentifierInferenceEnabled:(BOOL)enabled
{
    entityIdentifierInferenceEnabled = enabled;
}

+ (BOOL)isEntityIdentifierInferenceEnabled
{
    return entityIdentifierInferenceEnabled;
}

@end
