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
#import "RKObjectMappingMatcher.h"
#import "RKPropertyInspector+CoreData.h"
#import "RKLog.h"
#import "RKRelationshipMapping.h"
#import "RKObjectUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

NSString * const RKEntityIdentificationAttributesUserInfoKey = @"RKEntityIdentificationAttributes";

#pragma mark - Functions

static NSArray *RKEntityIdentificationAttributesFromUserInfoOfEntity(NSEntityDescription *entity)
{
    do {
        id userInfoValue = [[entity userInfo] valueForKey:RKEntityIdentificationAttributesUserInfoKey];
        if (userInfoValue) {
            NSArray *attributeNames = [userInfoValue isKindOfClass:[NSArray class]] ? userInfoValue : @[ userInfoValue ];
            NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:[attributeNames count]];
            [attributeNames enumerateObjectsUsingBlock:^(NSString *attributeName, NSUInteger idx, BOOL *stop) {
                if (! [attributeName isKindOfClass:[NSString class]]) {
                    [NSException raise:NSInvalidArgumentException format:@"Invalid value given in user info key '%@' of entity '%@': expected an `NSString` or `NSArray` of strings, instead got '%@' (%@)", RKEntityIdentificationAttributesUserInfoKey, [entity name], attributeName, [attributeName class]];
                }
                
                NSAttributeDescription *attribute = [[entity attributesByName] valueForKey:attributeName];
                if (! attribute) {
                    [NSException raise:NSInvalidArgumentException format:@"Invalid identifier attribute specified in user info key '%@' of entity '%@': no attribue was found with the name '%@'", RKEntityIdentificationAttributesUserInfoKey, [entity name], attributeName];
                }
                
                [attributes addObject:attribute];
            }];
            return attributes;
        }
        entity = [entity superentity];
    } while (entity);
    
    return nil;
}

static NSString *RKUnderscoredStringFromCamelCasedString(NSString *camelCasedString)
{
    NSError *error = nil;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"((^[a-z]+)|([A-Z]{1}[a-z]+)|([A-Z]+(?=([A-Z][a-z])|($))))" options:0 error:&error];
    if (! regularExpression) return nil;
    NSMutableArray *lowercasedComponents = [NSMutableArray array];
    [regularExpression enumerateMatchesInString:camelCasedString options:0 range:NSMakeRange(0, [camelCasedString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [lowercasedComponents addObject:[[camelCasedString substringWithRange:[result range]] lowercaseString]];
    }];
    return [lowercasedComponents componentsJoinedByString:@"_"];
}

// Given 'Human', returns 'humanID' and 'human_id'; Given 'AmenityReview' returns 'amenityReviewID' and 'amenity_review_id'
static NSArray *RKEntityIdentificationAttributeNamesForEntity(NSEntityDescription *entity)
{
    NSString *entityName = [entity name];
    NSString *lowerCasedFirstCharacter = [[entityName substringToIndex:1] lowercaseString];
    NSString *camelizedIDAttributeName = [NSString stringWithFormat:@"%@%@ID", lowerCasedFirstCharacter, [entityName substringFromIndex:1]];
    NSString *underscoredIDAttributeName = [NSString stringWithFormat:@"%@_id", RKUnderscoredStringFromCamelCasedString([entity name])];
    return @[ camelizedIDAttributeName, underscoredIDAttributeName ];
}

static NSArray *RKEntityIdentificationAttributeNames()
{
    return [NSArray arrayWithObjects:@"identifier", @"id", @"ID", @"URL", @"url", nil];
}

static NSArray *RKArrayOfAttributesForEntityFromAttributesOrNames(NSEntityDescription *entity, NSArray *attributesOrNames)
{
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:[attributesOrNames count]];
    for (id attributeOrName in attributesOrNames) {
        if ([attributeOrName isKindOfClass:[NSAttributeDescription class]]) {
            if (! [[entity properties] containsObject:attributeOrName]) [NSException raise:NSInvalidArgumentException format:@"Invalid attribute value '%@' given for entity identifer: not found in the '%@' entity", attributeOrName, [entity name]];
            [attributes addObject:attributeOrName];
        } else if ([attributeOrName isKindOfClass:[NSString class]]) {
            NSAttributeDescription *attribute = [[entity attributesByName] valueForKey:attributeOrName];
            if (!attribute) [NSException raise:NSInvalidArgumentException format:@"Invalid attribute '%@': no attribute was found for the given name in the '%@' entity.", attributeOrName, [entity name]];
            [attributes addObject:attribute];
        } else {
            [NSException raise:NSInvalidArgumentException format:@"Invalid value provided for entity identifier attribute: Acceptable values are either `NSAttributeDescription` or `NSString` objects."];
        }
    }
    
    return attributes;
}

NSArray *RKIdentificationAttributesInferredFromEntity(NSEntityDescription *entity)
{
    NSArray *attributes = RKEntityIdentificationAttributesFromUserInfoOfEntity(entity);
    if (attributes) {
        return RKArrayOfAttributesForEntityFromAttributesOrNames(entity, attributes);
    }
    
    NSMutableArray *identifyingAttributes = [RKEntityIdentificationAttributeNamesForEntity(entity) mutableCopy];
    [identifyingAttributes addObjectsFromArray:RKEntityIdentificationAttributeNames()];
    for (NSString *attributeName in identifyingAttributes) {
        NSAttributeDescription *attribute = [[entity attributesByName] valueForKey:attributeName];
        if (attribute) {
            return @[ attribute ];
        }
    }
    return nil;
}

static BOOL entityIdentificationInferenceEnabled = YES;

@interface RKObjectMapping (Private)
- (NSString *)transformSourceKeyPath:(NSString *)keyPath;
@end

@interface RKEntityMapping ()
@property (nonatomic, weak, readwrite) Class objectClass;
@property (nonatomic, strong) NSMutableArray *mutableConnections;
@end

@implementation RKEntityMapping

@synthesize identificationAttributes = _identificationAttributes;

+ (instancetype)mappingForClass:(Class)objectClass
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must provide a managedObjectStore. Invoke mappingForClass:inManagedObjectStore: instead."]
                                 userInfo:nil];
}

+ (instancetype)mappingForEntityForName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    NSParameterAssert(entityName);
    NSParameterAssert(managedObjectStore);
    NSEntityDescription *entity = [[managedObjectStore.managedObjectModel entitiesByName] objectForKey:entityName];
    NSAssert(entity, @"Unable to find an Entity with the name '%@' in the managed object model", entityName);
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
        self.discardsInvalidObjectsOnInsert = NO;
        if ([RKEntityMapping isEntityIdentificationInferenceEnabled]) self.identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
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

- (id)copyWithZone:(NSZone *)zone
{
    RKEntityMapping *copy = [super copyWithZone:zone];
    copy.entity = self.entity;
    copy.identificationAttributes = self.identificationAttributes;
    copy.identificationPredicate = self.identificationPredicate;
    copy.deletionPredicate = self.deletionPredicate;
    copy.mutableConnections = [NSMutableArray array];
    
    for (RKConnectionDescription *connection in self.connections) {
        [copy addConnection:[connection copy]];
    }
    
    return copy;
}

- (void)setIdentificationAttributes:(NSArray *)attributesOrNames
{
    if (attributesOrNames && [attributesOrNames count] == 0) [NSException raise:NSInvalidArgumentException format:@"At least one attribute must be provided to identify managed objects"];
    _identificationAttributes = attributesOrNames ? RKArrayOfAttributesForEntityFromAttributesOrNames(self.entity, attributesOrNames) : nil;
}

- (NSArray *)identificationAttributes
{
    return _identificationAttributes;
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
    NSRelationshipDescription *relationship = [relationshipOrName isKindOfClass:[NSRelationshipDescription class]] ? relationshipOrName : [[self.entity relationshipsByName] valueForKey:relationshipOrName];
    NSAssert(relationship, @"No relationship was found named '%@' in the '%@' entity", relationshipOrName, [self.entity name]);
    RKConnectionDescription *connection = nil;
    if ([connectionSpecifier isKindOfClass:[NSString class]]) {
        NSString *sourceAttribute = connectionSpecifier;
        NSString *destinationAttribute = [self transformSourceKeyPath:sourceAttribute];
        connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:@{ sourceAttribute: destinationAttribute }];
    } else if ([connectionSpecifier isKindOfClass:[NSArray class]]) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:[connectionSpecifier count]];
        for (NSString *sourceAttribute in connectionSpecifier) {
            NSString *destinationAttribute = [self transformSourceKeyPath:sourceAttribute];
            [attributes setObject:destinationAttribute forKey:sourceAttribute];
        }
        connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:attributes];
    } else if ([connectionSpecifier isKindOfClass:[NSDictionary class]]) {
        connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:connectionSpecifier];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Connections can only be described using `NSString`, `NSArray`, or `NSDictionary` objects. Instead, got: %@", connectionSpecifier];
    }
    
    [self.mutableConnections addObject:connection];
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

- (Class)classForKeyPath:(NSString *)keyPath
{
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    Class propertyClass = self.objectClass;
    for (NSString *property in components) {
        propertyClass = [[RKPropertyInspector sharedInspector] classForPropertyNamed:property ofClass:propertyClass isPrimitive:nil];
        if (! propertyClass) propertyClass = [[RKPropertyInspector sharedInspector] classForPropertyNamed:property ofEntity:self.entity];
        if (! propertyClass) break;
    }

    return propertyClass;
}

+ (void)setEntityIdentificationInferenceEnabled:(BOOL)enabled
{
    entityIdentificationInferenceEnabled = enabled;
}

+ (BOOL)isEntityIdentificationInferenceEnabled
{
    return entityIdentificationInferenceEnabled;
}

@end
