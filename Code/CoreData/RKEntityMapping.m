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
#import "NSEntityDescription+RKAdditions.h"
#import "RKLog.h"
#import "RKRelationshipMapping.h"
#import "RKObjectUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

@interface RKEntityMapping ()
@property (nonatomic, weak, readwrite) Class objectClass;
@property (nonatomic, strong, readwrite) NSEntityDescription *entity;
@property (nonatomic, strong) NSMutableArray *mutableConnections;
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

        [self addObserver:self forKeyPath:@"entity" options:NSKeyValueObservingOptionInitial context:nil];
        [self addObserver:self forKeyPath:@"primaryKeyAttribute" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    }

    return self;
}

- (id)initWithClass:(Class)objectClass
{
    self = [super initWithClass:objectClass];
    if (self) {
        self.mutableConnections = [NSMutableArray array];
    }

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"entity"];
    [self removeObserver:self forKeyPath:@"primaryKeyAttribute"];
}

- (RKConnectionMapping *)connectionMappingForRelationshipWithName:(NSString *)relationshipName
{
    for (RKConnectionMapping *connection in self.connectionMappings) {
        if ([connection.relationship.name isEqualToString:relationshipName]) {
            return connection;
        }
    }
    return nil;
}

- (void)addConnectionMapping:(RKConnectionMapping *)mapping
{
    NSParameterAssert(mapping);
    RKConnectionMapping *connectionMapping = [self connectionMappingForRelationshipWithName:mapping.relationship.name];
    NSAssert(connectionMapping == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", mapping.relationship.name);
    NSAssert(self.mutableConnections, @"self.mutableConnections should not be nil");
    [self.mutableConnections addObject:mapping];
}

- (void)addConnectionMappingsFromArray:(NSArray *)arrayOfConnectionMappings
{
    for (RKConnectionMapping *connectionMapping in arrayOfConnectionMappings) {
        [self addConnectionMapping:connectionMapping];
    }
}

- (RKConnectionMapping *)addConnectionMappingForRelationshipForName:(NSString *)relationshipName
                                                  fromSourceKeyPath:(NSString *)sourceKeyPath
                                                          toKeyPath:(NSString *)destinationKeyPath
                                                            matcher:(RKDynamicMappingMatcher *)matcher
{
    NSRelationshipDescription *relationship = [[self.entity propertiesByName] objectForKey:relationshipName];
    NSAssert(relationship, @"Unable to find a relationship named '%@' in the entity: %@", relationshipName, self.entity);
    RKConnectionMapping *connectionMapping = [[RKConnectionMapping alloc] initWithRelationship:relationship sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath matcher:matcher];
    [self addConnectionMapping:connectionMapping];
    return connectionMapping;
}

- (void)removeConnectionMapping:(RKConnectionMapping *)connectionMapping
{
    [self.mutableConnections removeObject:connectionMapping];
}

- (id)defaultValueForMissingAttribute:(NSString *)attributeName
{
    NSAttributeDescription *desc = [[self.entity attributesByName] valueForKey:attributeName];
    return [desc defaultValue];
}

- (Class)classForProperty:(NSString *)propertyName
{
    Class propertyClass = [super classForProperty:propertyName];
    if (! propertyClass) {
        propertyClass = [[RKPropertyInspector sharedInspector] typeForProperty:propertyName ofEntity:self.entity];
    }

    return propertyClass;
}

/*
 Allows the primaryKeyAttributeName property on the NSEntityDescription to configure the mapping and vice-versa
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"entity"]) {
        if (! self.primaryKeyAttribute) {
            self.primaryKeyAttribute = [self.entity primaryKeyAttributeName];
        }
    } else if ([keyPath isEqualToString:@"primaryKeyAttribute"]) {
        if (! self.entity.primaryKeyAttribute) {
            self.entity.primaryKeyAttributeName = self.primaryKeyAttribute;
        }
    }
}

- (NSArray *)connectionMappings
{
    return [NSArray arrayWithArray:self.mutableConnections];
}

@end
