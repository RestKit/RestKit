//
//  RKManagedObjectMapping.m
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

#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"
#import "RKDynamicObjectMappingMatcher.h"
#import "RKObjectPropertyInspector+CoreData.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKManagedObjectMapping

@synthesize entity = _entity;
@synthesize primaryKeyAttribute = _primaryKeyAttribute;
@synthesize objectStore = _objectStore;

+ (id)mappingForClass:(Class)objectClass
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must provide a managedObjectStore. Invoke mappingForClass:inManagedObjectStore: instead."]
                                 userInfo:nil];
}

+ (id)mappingForClass:(Class)objectClass inManagedObjectStore:(RKManagedObjectStore *)objectStore
{
    return [self mappingForEntityWithName:NSStringFromClass(objectClass) inManagedObjectStore:objectStore];
}

+ (RKManagedObjectMapping *)mappingForEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore
{
    return [[[self alloc] initWithEntity:entity inManagedObjectStore:objectStore] autorelease];
}

+ (RKManagedObjectMapping *)mappingForEntityWithName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)objectStore
{
    return [self mappingForEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:objectStore.primaryManagedObjectContext]
             inManagedObjectStore:objectStore];
}

- (id)initWithEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore
{
    NSAssert(entity, @"Cannot initialize an RKManagedObjectMapping without an entity. Maybe you want RKObjectMapping instead?");
    NSAssert(objectStore, @"Object store cannot be nil");
    Class objectClass = NSClassFromString([entity managedObjectClassName]);
    NSAssert(objectClass, @"The managedObjectClass for an object mapped entity cannot be nil.");
    self = [self init];
    if (self) {
        _objectClass = [objectClass retain];
        _entity = [entity retain];
        _objectStore = objectStore;

        [self addObserver:self forKeyPath:@"entity" options:NSKeyValueObservingOptionInitial context:nil];
        [self addObserver:self forKeyPath:@"primaryKeyAttribute" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    }

    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        _relationshipToPrimaryKeyMappings = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"entity"];
    [self removeObserver:self forKeyPath:@"primaryKeyAttribute"];

    [_entity release];
    [_relationshipToPrimaryKeyMappings release];
    [super dealloc];
}

- (NSDictionary *)relationshipsAndPrimaryKeyAttributes
{
    return _relationshipToPrimaryKeyMappings;
}

- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    NSAssert([_relationshipToPrimaryKeyMappings objectForKey:relationshipName] == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", relationshipName);
    [_relationshipToPrimaryKeyMappings setObject:primaryKeyAttribute forKey:relationshipName];
}

- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString *)firstRelationshipName, ...
{
    va_list args;
    va_start(args, firstRelationshipName);
    for (NSString *relationshipName = firstRelationshipName; relationshipName != nil; relationshipName = va_arg(args, NSString *)) {
        NSString *primaryKeyAttribute = va_arg(args, NSString *);
        NSAssert(primaryKeyAttribute != nil, @"Cannot connect a relationship without an attribute containing the primary key");
        [self connectRelationship:relationshipName withObjectForPrimaryKeyAttribute:primaryKeyAttribute];
        // TODO: Raise proper exception here, argument error...
    }
    va_end(args);
}

- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value
{
    NSAssert([_relationshipToPrimaryKeyMappings objectForKey:relationshipName] == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", relationshipName);
    RKDynamicObjectMappingMatcher *matcher = [[RKDynamicObjectMappingMatcher alloc] initWithKey:keyPath value:value primaryKeyAttribute:primaryKeyAttribute];
    [_relationshipToPrimaryKeyMappings setObject:matcher forKey:relationshipName];
    [matcher release];
}

- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute usingEvaluationBlock:(BOOL (^)(id data))block
{
    NSAssert([_relationshipToPrimaryKeyMappings objectForKey:relationshipName] == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", relationshipName);
    RKDynamicObjectMappingMatcher *matcher = [[RKDynamicObjectMappingMatcher alloc] initWithPrimaryKeyAttribute:primaryKeyAttribute evaluationBlock:block];
    [_relationshipToPrimaryKeyMappings setObject:matcher forKey:relationshipName];
    [matcher release];
}

- (id)defaultValueForMissingAttribute:(NSString *)attributeName
{
    NSAttributeDescription *desc = [[self.entity attributesByName] valueForKey:attributeName];
    return [desc defaultValue];
}

- (id)mappableObjectForData:(id)mappableData
{
    NSAssert(mappableData, @"Mappable data cannot be nil");

    id object = nil;
    id primaryKeyValue = nil;
    NSString *primaryKeyAttribute;

    NSEntityDescription *entity = [self entity];
    RKObjectAttributeMapping *primaryKeyAttributeMapping = nil;

    primaryKeyAttribute = [self primaryKeyAttribute];
    if (primaryKeyAttribute) {
        // If a primary key has been set on the object mapping, find the attribute mapping
        // so that we can extract any existing primary key from the mappable data
        for (RKObjectAttributeMapping *attributeMapping in self.attributeMappings) {
            if ([attributeMapping.destinationKeyPath isEqualToString:primaryKeyAttribute]) {
                primaryKeyAttributeMapping = attributeMapping;
                break;
            }
        }

        // Get the primary key value out of the mappable data (if any)
        if ([primaryKeyAttributeMapping isMappingForKeyOfNestedDictionary]) {
            RKLogDebug(@"Detected use of nested dictionary key as primaryKey attribute...");
            primaryKeyValue = [[mappableData allKeys] lastObject];
        } else {
            NSString *keyPathForPrimaryKeyElement = primaryKeyAttributeMapping.sourceKeyPath;
            if (keyPathForPrimaryKeyElement) {
                primaryKeyValue = [mappableData valueForKeyPath:keyPathForPrimaryKeyElement];
            } else {
                RKLogWarning(@"Unable to find source attribute for primaryKeyAttribute '%@': unable to find existing object instances by primary key.", primaryKeyAttribute);
            }
        }
    }

    // If we have found the primary key attribute & value, try to find an existing instance to update
    if (primaryKeyAttribute && primaryKeyValue && NO == [primaryKeyValue isEqual:[NSNull null]]) {
        object = [self.objectStore.cacheStrategy findInstanceOfEntity:entity
                                              withPrimaryKeyAttribute:primaryKeyAttribute
                                                                value:primaryKeyValue
                                               inManagedObjectContext:[self.objectStore managedObjectContextForCurrentThread]];

        if (object && [self.objectStore.cacheStrategy respondsToSelector:@selector(didFetchObject:)]) {
            [self.objectStore.cacheStrategy didFetchObject:object];
        }
    }

    if (object == nil) {
        object = [[[NSManagedObject alloc] initWithEntity:entity
                           insertIntoManagedObjectContext:[_objectStore managedObjectContextForCurrentThread]] autorelease];
        if (primaryKeyAttribute && primaryKeyValue && ![primaryKeyValue isEqual:[NSNull null]]) {
            id coercedPrimaryKeyValue = [entity coerceValueForPrimaryKey:primaryKeyValue];
            [object setValue:coercedPrimaryKeyValue forKey:primaryKeyAttribute];
        }

        if ([self.objectStore.cacheStrategy respondsToSelector:@selector(didCreateObject:)]) {
            [self.objectStore.cacheStrategy didCreateObject:object];
        }
    }
    return object;
}

- (Class)classForProperty:(NSString *)propertyName
{
    Class propertyClass = [super classForProperty:propertyName];
    if (! propertyClass) {
        propertyClass = [[RKObjectPropertyInspector sharedInspector] typeForProperty:propertyName ofEntity:self.entity];
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
@end
