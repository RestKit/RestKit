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

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

// Implemented in RKObjectMappingOperation
BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

@interface RKEntityMapping ()
@property (nonatomic, retain, readwrite) NSEntityDescription *entity;
@property (nonatomic, retain) NSMutableArray *mutableConnections;
@end

@implementation RKEntityMapping

@synthesize mutableConnections = _mutableConnections;
@synthesize entity = _entity;
@synthesize primaryKeyAttribute = _primaryKeyAttribute;

+ (id)mappingForClass:(Class)objectClass
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must provide a managedObjectStore. Invoke mappingForClass:inManagedObjectStore: instead."]
                                 userInfo:nil];
}

+ (id)mappingForEntityForName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    NSEntityDescription *entity = [[managedObjectStore.managedObjectModel entitiesByName] objectForKey:entityName];
    return [self mappingForEntity:entity];
}

+ (id)mappingForEntity:(NSEntityDescription *)entity
{
    return [[[self alloc] initWithEntity:entity] autorelease];
}

- (id)initWithEntity:(NSEntityDescription *)entity
{
    NSAssert(entity, @"Cannot initialize an RKEntityMapping without an entity. Maybe you want RKObjectMapping instead?");
    Class objectClass = NSClassFromString([entity managedObjectClassName]);
    NSAssert(objectClass, @"Cannot initialize an entity mapping for an entity with a nil managed object class: Got nil class for managed object class name '%@'. Maybe you forgot to add the class files to your target?", [entity managedObjectClassName]);
    self = [self init];
    if (self) {
        self.objectClass = objectClass;
        self.entity = entity;

        [self addObserver:self forKeyPath:@"entity" options:NSKeyValueObservingOptionInitial context:nil];
        [self addObserver:self forKeyPath:@"primaryKeyAttribute" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    }

    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.mutableConnections = [NSMutableArray array];
    }

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"entity"];
    [self removeObserver:self forKeyPath:@"primaryKeyAttribute"];

    [_entity release];
    [_mutableConnections release];
    [super dealloc];
}

- (RKConnectionMapping *)connectionMappingForRelationshipWithName:(NSString *)relationshipName
{
    for (RKConnectionMapping *connection in self.connectionMappings) {
        if ([connection.relationshipName isEqualToString:relationshipName]) {
            return connection;
        }
    }
    return nil;
}

- (RKMapping *)objectMappingForRelationship:(NSString *)relationshipName
{
    RKRelationshipMapping *relationshipMapping = [self mappingForRelationship:relationshipName];
    return relationshipMapping.mapping;
}

- (NSString *)primaryKeyPathForRelationship:(NSString *)relationshipName
{
    RKMapping* mappingDef = [self objectMappingForRelationship:relationshipName];
    RKEntityMapping *objectMapping = (RKEntityMapping *) mappingDef;
    return [objectMapping primaryKeyAttribute];
}

- (void)addConnectionMapping:(RKConnectionMapping *)mapping
{
    RKConnectionMapping *connectionMapping = [self connectionMappingForRelationshipWithName:mapping.relationshipName];
    NSAssert(connectionMapping == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", mapping.relationshipName);
    NSAssert(mapping.mapping, @"Attempted to connect relationship '%@' without a relationship mapping defined.", mapping.relationshipName);
    NSAssert([mapping.mapping isKindOfClass:[RKEntityMapping class]], @"Can only connect RKManagedObjectMapping relationships");
    [self.mutableConnections addObject:mapping];
}

- (void)removeConnectionMapping:(RKConnectionMapping *)connectionMapping
{
    [self.mutableConnections removeObject:connectionMapping];
}

- (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping
{
    NSAssert(sourceKeyPath, @"Cannot connect relationship: mapping for %@ has no source key attribute specified", relationshipName);
    NSAssert(destinationKeyPath, @"Cannot connect relationship: mapping for %@ has no destination key attribute specified", relationshipName);
    RKConnectionMapping *mapping = [RKConnectionMapping connectionMappingForRelationship:relationshipName fromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping];
    [self addConnectionMapping:mapping];
}

- (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value
{
    RKDynamicMappingMatcher *matcher = [[RKDynamicMappingMatcher alloc] initWithKey:keyPath value:value primaryKeyAttribute:sourceKeyPath];
    RKConnectionMapping *mapping = [RKConnectionMapping connectionMappingForRelationship:relationshipName fromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping matcher:matcher];
    [self addConnectionMapping:mapping];
    [matcher release];
}

- (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping usingEvaluationBlock:(BOOL (^)(id data))block
{
    RKDynamicMappingMatcher *matcher = [[RKDynamicMappingMatcher alloc] initWithPrimaryKeyAttribute:sourceKeyPath evaluationBlock:block];
    RKConnectionMapping *mapping = [RKConnectionMapping connectionMappingForRelationship:relationshipName fromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping matcher:matcher];
    [self addConnectionMapping:mapping];
    [matcher release];
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

@implementation RKEntityMapping (Deprecations)

+ (id)mappingForClass:(Class)objectClass inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    return [self mappingForEntityWithName:NSStringFromClass(objectClass) inManagedObjectStore:objectStore];
}

+ (RKEntityMapping *)mappingForEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    return [[[self alloc] initWithEntity:entity inManagedObjectStore:objectStore] autorelease];
}

+ (RKEntityMapping *)mappingForEntityWithName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    return [self mappingForEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:objectStore.primaryManagedObjectContext]
             inManagedObjectStore:objectStore];
}

- (id)initWithEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    return [self initWithEntity:entity];
}

/* Deprecated */
- (void)connectRelationship:(NSString*)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    RKMapping *objectOrDynamicMapping = [self objectMappingForRelationship:relationshipName];
    NSString *sourceKeyPath = primaryKeyAttribute;
    NSString *destinationKeyPath = [self primaryKeyPathForRelationship:relationshipName];
    
    RKConnectionMapping *mapping = [RKConnectionMapping connectionMappingForRelationship:relationshipName fromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping];
    [self addConnectionMapping:mapping];
}

- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString *)firstRelationshipName, ...
{
    va_list args;
    va_start(args, firstRelationshipName);
    for (NSString *relationshipName = firstRelationshipName; relationshipName != nil; relationshipName = va_arg(args, NSString*)) {
		NSString *primaryKeyAttribute = va_arg(args, NSString *);
        [self connectRelationship:relationshipName withObjectForPrimaryKeyAttribute:primaryKeyAttribute];
        // TODO: Raise proper exception here, argument error...
    }
    va_end(args);
}

- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute whenValueOfKeyPath:(NSString*)keyPath isEqualTo:(id)value
{
    RKMapping *objectOrDynamicMapping = [self objectMappingForRelationship:relationshipName];
    NSString *sourceKeyPath = primaryKeyAttribute;
    NSString *destinationKeyPath = [self primaryKeyPathForRelationship:relationshipName];
    [self connectRelationship:relationshipName fromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping whenValueOfKeyPath:keyPath isEqualTo:value];
}

- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute usingEvaluationBlock:(BOOL (^)(id data))block
{
    RKMapping *objectOrDynamicMapping = [self objectMappingForRelationship:relationshipName];
    NSString *sourceKeyPath = primaryKeyAttribute;
    NSString *destinationKeyPath = [self primaryKeyPathForRelationship:relationshipName];
    [self connectRelationship:relationshipName fromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping usingEvaluationBlock:block];
}

@end
