//
//  RKEntityMapping.h
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

#import <CoreData/CoreData.h>
#import "RKObjectMapping.h"
#import "RKConnectionDescription.h"
#import "RKMacros.h"
#import "RKEntityIdentifier.h"

@class RKManagedObjectStore;

/**
 `RKEntityMapping` objects model an object mapping with a Core Data destination entity.
 
 ## Entity Identification
 
 One of the fundamental problems when object mapping representations into Core Data entities is determining if a new object should be created or an existing object should be updated. The `RKEntityIdentifier` class describes how existing objects should be identified when an entity mapping is being applied. Entity identifiers specify one or more attributes of the entity that are to be used to identify existing objects. Typically the values of these attributes are populated by attribute mappings. It is common practice to use a single attribute corresponding to the primary key of the remote resource being mapped, but an arbitrary number of attributes may be specified for identification. Identifying attributes have all type transformations support by the mapper applied before the managed object context is search, supporting such use-cases as using an `NSDate` as an identifying attribute whose value is mapped from an `NSString`.
 
 ### Inferring Entity Identifiers
 
 The `RKEntityMapping` class provides support for inferring an entity identifier from the managed object model. When inference is enabled (the default state), the entity is searched for several commonly used identifying attributes and if any is found, an `entityIdentifier` is automatically configured. Inference is performed by the `[RKEntityIdentifier inferredIdentifierForEntity:` method and the inference rules are detailed in the accompanying documentation.
 
 ## Connecting Relationships
 
 When modeling an API into Core Data representation, a common problem is that managed objects that are semantically related are loaded across discrete requests, leaving the Core Data relationships empty. The `RKConnectionDescription` class provides a means for expressing a connection between entities using corresponding attribute values or by key path. Please refer to the documentation accompanying the `RKConnectionDescription` class and the `addConnectionForRelationship:connectedBy:` method of this class.
 
 @see `RKEntityIdentifier`
 @see `RKConnectionDescription`
 */
@interface RKEntityMapping : RKObjectMapping

///-----------------------------------------------------------------------------
/// @name Initializing an Entity Mapping
///-----------------------------------------------------------------------------

/**
 Initializes the receiver with a given entity.

 @param entity An entity with which to initialize the receiver.
 @returns The receiver, initialized with the given entity.
 */
- (id)initWithEntity:(NSEntityDescription *)entity;

/**
 A convenience initializer that creates and returns an entity mapping for the entity with the given name in
 the managed object model of the given managed object store.

 This method is functionally equivalent to the following example code:

     NSEntityDescription *entity = [[managedObjectStore.managedObjectModel entitiesByName] objectForKey:entityName];
     return [RKEntityMapping mappingForEntity:entity];

 @param entityName The name of the entity in the managed object model for which an entity mapping is to be created.
 @param managedObjectStore A managed object store containing the managed object model in which an entity with the given name is defined.
 @return A new entity mapping for the entity with the given name in the managed object model of the given managed object store.
 */
+ (id)mappingForEntityForName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

///---------------------------
/// @name Accessing the Entity
///---------------------------

/**
 The Core Data entity description used for this object mapping
 */
@property (nonatomic, strong) NSEntityDescription *entity;

///----------------------------------
/// @name Identifying Managed Objects
///----------------------------------

/**
 The entity identifier used to identify `NSManagedObject` instances for the receiver's entity by one or more attributes.
 
 The entity identifier is used during mapping to determine whether an existing object should be updated or a new managed object should be inserted. Please see the "Entity Identification" section of this document for more information.
 */
@property (nonatomic, copy) RKEntityIdentifier *entityIdentifier;

/**
 Sets an entity identifier for the relationship with the given name.
 
 When mapping the specified relationship, the given entity identifier will be used to find existing managed object instances. If no identifier is specified, then the entity identifier of the entity mapping is used by default. This method need only be invoked if the relationship has specific identification needs that diverge from the entity.
 
 @param entityIdentifier The entity identifier to be used when mapping the specified relationship
 @param relationshipName The name of the relationship for which the specified identifier is to be used.
 */
- (void)setEntityIdentifier:(RKEntityIdentifier *)entityIdentifier forRelationship:(NSString *)relationshipName;

/**
 Returns the entity identifier for the relationship with the given name.
 
 This method will return `nil` unless an entity identifier was specified via the `setEntityIdentifier:forRelationship:` method.
 
 @param relationshipName The name of the relationship to retrieve the entity identifier for.
 @return The entity identifier for the specified relationship or `nil` if none was configured.
 */
- (RKEntityIdentifier *)entityIdentifierForRelationship:(NSString *)relationshipName;

///-------------------------------------------
/// @name Configuring Relationship Connections
///-------------------------------------------

/**
 Returns the array of `RKConnectionDescripton` objects configured for connecting relationships during object mapping.
 */
@property (weak, nonatomic, readonly) NSArray *connections;

/**
 Adds a connection to the receiver.

 @param connection The connection to be added.
 */
- (void)addConnection:(RKConnectionDescription *)connection;

/**
 Removes a connection from the receiver.
 
 @param connection The connection to be removed.
 */
- (void)removeConnection:(RKConnectionDescription *)connection;

/**
 Adds a connection for the specified relationship connected using the attributes specified by the given `NSString`, `NSArray`, or `NSDictionary` object.
 
 This is a convenience method for flexibly adding a connection to the receiver. The relationship can be specified with by providing an `NSRelationshipDescription` object or an `NSString` specifying the name of the relationship to be connected. The connection specifier can be provided as an `NSString` object, an `NSArray` of `NSString` object, or an `NSDictionary` with `NSString` objects for the keys and values. The string objects specify the name of attributes within the entity and destination entity of the specified relationship. The `RKConnectionDescription` class models a connection as a dictionary in which the keys are `NSString` objects corresponding to the names of attributes in the source entity of the relationship being connected and the values are `NSString` objects corresponding to the names of attributes in the destination entity.
 
 When the `connectionSpecifier` is an `NSString` value, it is interpretted as the name of an attribute in the specified relationship's entity. The corresponding attribute in the destination entity is determined by invoking the source to destination key transformation block set via `[RKObjectMapping setSourceToDestinationKeyTransformationBlock:]`. If no transformation block is configured, then the destination attribute is assumed to have the same name as the source attribute. For example, consider a model in which there entities named 'User' and 'Project'. The 'User' entity has a to-many relationship to the 'Project' entity named 'projects'. Both the 'User' and the 'Project' entities contain an attribute named 'userID', which represents the value for the primary key of the 'User' in the API the application is communicating with. When the user's projects are loaded from the '/projects' endpoint, the user ID is sent down in the JSON representation of the Project objects as a numeric value. In order to establish a connection for the 'projects' relationship between the 'User' and 'Project' entities, we could add the connection like so:
    
    // JSON looks like {"project": { "name": "Project Name", "userID": 1234, "projectID": 1 } }
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Project" inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappings:@[ @"name", @"userID", @"projectID" ]];
 
    // Find a 'User' whose value for the 'userID' object is equal to the value stored on the 'userID' attribute of the 'Project' and assign it to the relationship
    // In other words, "Find the User whose userID == 1234 and assign that object to the 'user' relationship"
    [mapping addConnectionForRelationship:@"user" connectedBy:@"userID"];
 
 When the connection is attempted to be established by an instance of `RKRelationshipConnectionOperation`, the value for the 'userID' attribute will be read from the Project (in this case, @1234) and the managed object context will be searched for a managed object for the 'User' entity with a corresponding value for its 'userID' attribute.
 
 When the `connectionSpecifier` is an `NSArray` object, it is interpretted as containing the names of attributes in the specified relationship's entity. Just as with a stirng value, the corresponding destination attributes are determined by invoking the source to destination key transformation block or they are assumed to have matching names.
 
 When the `connectionSpecifier` is an `NSDictionary` object, the keys are interpretted as containing the names of attributes on the source entity the values are interpretted as the names of attributes on the destination entity. For example:
    
    // Find the User whose userID is equal to the value stored on the 'createdByUserID' attribute
    [mapping addConnectionForRelationship:@"createdByUser" connectedBy:@{ @"createdByUserID": @"userID" }];
 
 @param relationshipOrName The relationship object or name of the relationship object that is to be connected.
 @param connectionSpecifier An `NSString`, `NSArray`, or `NSDictionary` object specifying how the relationship is to be connected by matching attributes.
 @see `RKConnectionDescription`
 @see `[RKObjectMapping setSourceToDestinationKeyTransformationBlock:]`
 */
- (void)addConnectionForRelationship:(id)relationshipOrName connectedBy:(id)connectionSpecifier;

/**
 Returns the connection for the specified relationship.
 
 @param relationshipOrName The relationship object or name of the relationship object for which to retrieve the connection.
 @return The connection object for the specified relationship or `nil` if none is configured.
 */
- (RKConnectionDescription *)connectionForRelationship:(id)relationshipOrName;

///------------------------------------------
/// @name Retrieving Default Attribute Values
///------------------------------------------

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForAttribute:(NSString *)attributeName;

///----------------------------------------------
/// @name Configuring Entity Identifier Inference
///----------------------------------------------

/**
 Enables or disabled entity identifier inference.
 
 **Default:** `YES`
 
 @param enabled A Boolean value indicating if entity identifier inference is to be performed.
 */
+ (void)setEntityIdentifierInferenceEnabled:(BOOL)enabled;

/**
 Returns a Boolean value that indicates is entity identifier inference has been enabled.
 
 @return `YES` if entity identifier inference is enabled, else `NO`.
 */
+ (BOOL)isEntityIdentifierInferenceEnabled;

@end
