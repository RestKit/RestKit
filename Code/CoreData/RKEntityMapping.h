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

@class RKManagedObjectStore;

/**
 `RKEntityMapping` objects model an object mapping with a Core Data destination entity.
 
 ## Entity Identification
 
 One of the fundamental problems when object mapping representations into Core Data entities is determining if a new object should be created or an existing object should be updated. In an entity mapping, one or more attributes can be designated as being used for identification purposes via the `identificationAttributes` property. Typically the values of these attributes are populated by attribute mappings. It is common practice to use a single attribute corresponding to the primary key of the remote resource being mapped, but an arbitrary number of attributes may be specified for identification. Identifying attributes have all type transformations support by the mapper applied before the managed object context is searched, supporting such use-cases as using an `NSDate` as an identifying attribute whose value is mapped from an `NSString`. Identified objects can be further constrained by configuring an identification predicate via the `identificationPredicate` property. The predicate is applied after the managed object has been searched.
 
 ### Identification Inference
 
 The `RKEntityMapping` class provides support for inferring identification attributes from the managed object model. When inference is enabled (the default state), the entity is searched for several commonly used identifying attributes and if any is found, the value of the `identificationAttributes` property is automatically configured. Inference is performed by the `RKIdentificationAttributesInferredFromEntity` function.
 
 When `RKIdentificationAttributesInferredFromEntity` is invoked, the entity is first checked for a user info key specifying the identifying attributes. If the user info of the given entity contains a value for the key 'RKEntityIdentificationAttributes', then that value is used to construct an array of attributes. The user info key must contain a string or an array of strings specifying the names of attributes that exist in the given entity.
 
 If no attributes are specified in the user info, then the entity is searched for an attribute whose name matches the llama-cased or snake-cased name of the entity. For example, an entity named 'Article' would have an inferred identifying attributes of 'articleID' and 'article_id', and an entity named 'ApprovedComment' would be inferred as 'approvedCommentID' and 'approved_comment_id'. If such an attribute is found within the entity, an array is returned containing the attribute. If none is returned, the the attributes are searched for the following names:
 
 1. 'identifier'
 1. 'id'
 1. 'ID'
 1. 'URL'
 1. 'url'
 
 If any of these attributes are found, then an array is returned containing the attribute. If all possible inferred attributes are exhausted, then `nil` is returned.
 
 Note that inference will only return a single attribute. Compound attributes must be configured manually via the `identificationAttributes` property.
 
 ## Connecting Relationships
 
 When modeling an API into Core Data representation, a common problem is that managed objects that are semantically related are loaded across discrete requests, leaving the Core Data relationships empty. The `RKConnectionDescription` class provides a means for expressing a connection between entities using corresponding attribute values or by key path. Please refer to the documentation accompanying the `RKConnectionDescription` class and the `addConnectionForRelationship:connectedBy:` method of this class.
 
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
- (instancetype)initWithEntity:(NSEntityDescription *)entity;

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
+ (instancetype)mappingForEntityForName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

///---------------------------
/// @name Accessing the Entity
///---------------------------

/**
 The Core Data entity description used for this object mapping
 */
@property (nonatomic, strong) NSEntityDescription *entity;

///------------------------------------------------
/// @name Configuring Managed Object Identification
///------------------------------------------------

/**
 The array of `NSAttributeDescription` objects specifying the attributes of the receiver's entity that are used during mapping to determine whether an existing object should be updated or a new managed object should be inserted. Please see the "Entity Identification" section of this document for more information.
 
 @return An array of identifying attributes or `nil` if none have been configured.
 @raises NSInvalidArgumentException Raised if the setter is invoked with the name of an attribute or an `NSAttributeDescription` that does not exist in the receiver's entity. Also raised if the setter is invoked with an empty array.
 @warning Note that for convenience, this property may be set with an array containing `NSAttributeDescription` objects or `NSString` objects specifying the names of attributes that exist within the receiver's entity. The getter will always return an array of `NSAttributeDescription` objects.
 */
@property (nonatomic, copy) NSArray *identificationAttributes;

/**
 An optional predicate used to filter identified objects during mapping.
 
 @return The identification predicate.
 */
@property (nonatomic, copy) NSPredicate *identificationPredicate;

/**
 An optional block which returns a predicate used to filter identified objects during mapping.
 
 @return The identification predicate block.
 */
@property (nonatomic, copy) NSPredicate *(^identificationPredicateBlock)(NSDictionary *representation, NSManagedObjectContext *managedObjectContext);

/**
 An optional attribute of the receiver's entity that can be used to detect modification of a given instance. This is used to improve the performance of mapping operations by skipping the property mappings for a given object if it is found to be not modified.
 
 A common modification attribute is a 'last modified' or 'updated at' timestamp that specifies the timestamp of the last change to an object. When the `modificationAttribute` is non-nil, the mapper will compare the value returned of the attribute on an existing object instance with the value in the representation being mapped. 
 
 The semantics of the comparison are dependent on the data type of the modification attribute. If the attribute is a string, then the values are compared for equality. If the attribute is a date or a numeric value, then the values will be compared numerically and mapping will be skipped unless the value in the representation is greater than the value of the modification attribute stored on the object.
 
 @raises NSInvalidArgumentException Raised if the attribute given is not a property of the receiver's entity.
 */
@property (nonatomic, strong) NSAttributeDescription *modificationAttribute;

/**
 If this is YES, mapping operations will map relationships of the object even if the `modificationAttribute` shows that the object has not been modified.
 
 This is useful if a response contains a nested object that has been updated inside an object that has not.
 
 Defaults to NO.
 */
@property (nonatomic) BOOL shouldMapRelationshipsIfObjectIsUnmodified;

/**
 Sets the `modificationAttribute` to the receiver to the attribute with the specified name.
 
 The given name must correspond to the name of an attribute within the receiver's entity.
 
 @param attributeName The name of an attribute in the entity of the receiver.
 @raises NSInvalidArgumentException Raised if no attribute could be found with the given name.
 */
- (void)setModificationAttributeForName:(NSString *)attributeName;

///---------------------------------------------------------------
/// @name Specifying a Persistent Store for Newly Inserted Objects
///---------------------------------------------------------------

/**
 The persistent store in which new object instances mapped with the receiver should be inserted.
 
 If your application makes use of more than one persistent store (i.e. a combination of an in-memory store and a SQLite store), then it can be desirable to specify the persistent store in which newly created managed objects will be assigned.
 
 **Default**: `nil`
 */
@property (nonatomic, weak) NSPersistentStore *persistentStore;

///-------------------------------------------
/// @name Configuring Relationship Connections
///-------------------------------------------

/**
 Returns the array of `RKConnectionDescripton` objects configured for connecting relationships during object mapping.
 */
@property (nonatomic, copy, readonly) NSArray *connections;

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
    [mapping addAttributeMappingsFromArray:@[ @"name", @"userID", @"projectID" ]];
 
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

///-----------------------------
/// @name Configuring Validation
///-----------------------------

/**
 A Boolean value that determines if newly created `NSManagedObject` instances mapped with the receiver should be discarded when they fail `validateForInsert:`.
 
 This property allows for the deletion of managed objects that fail validation such that `NSManagedObjectContext` save will complete successfully. Typically an invalid managed object in the graph will result in a failure to save the `NSManagedObjectContext` due to an NSValidation error. In some cases it is desirable to persist only the subset of objects that pass validation and discard the invalid content rather than failing the entire operation. Setting this property to `YES` will result in the deletion of in any newly created `NSManagedObject` instances that fail to return `YES` when sent the `validateForInsert:` message.
 
 **Default**: `NO`
 */
@property (nonatomic, assign) BOOL discardsInvalidObjectsOnInsert;

///------------------------------------
/// @name Flagging Objects for Deletion
///------------------------------------

/**
 A predicate that identifies objects for the receiver's entity that are to be deleted from the local store.

 This property provides support for local deletion of managed objects mapped as a 'tombstone' record from the source representation. The deletion predicate is used in conjunction with the entity associated with the receiver to construct an `NSFetchRequest` that identifies managed objects that should be deleted when a mapping operation is committed. For example, given the following JSON:
 
    { "userID": 12345, "is_deleted": true }
 
 We could map the `is_deleted` key to a Boolean attribute on the model such as `shouldBeDeleted` and configure a deletion predicate using this attribute:
 
    [entityMapping addAttributeMappingsFromDictionary:@{ @"is_deleted": @"shouldBeDeleted" }];
    entityMapping.deletionPredicate = [NSPredicate predicateWithFormat:@"shouldBeDeleted = true"];
 
 When a mapping operation completes, a `NSFetchRequest` will be constructed and executed. Any objects in the store whose `shouldBeDeleted` value is true will be deleted.
 */
@property (nonatomic, copy) NSPredicate *deletionPredicate;

///------------------------------------------
/// @name Retrieving Default Attribute Values
///------------------------------------------

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForAttribute:(NSString *)attributeName;

///--------------------------------------------------
/// @name Configuring Entity Identification Inference
///--------------------------------------------------

/**
 Enables or disabled entity identification inference.
 
 **Default:** `YES`
 
 @param enabled A Boolean value indicating if entity identification inference is to be performed.
 */
+ (void)setEntityIdentificationInferenceEnabled:(BOOL)enabled;

/**
 Returns a Boolean value that indicates if entity identification inference has been enabled.
 
 @return `YES` if entity identification inference is enabled, else `NO`.
 */
+ (BOOL)isEntityIdentificationInferenceEnabled;

@end

/**
 The name of a key in the user info dictionary of a `NSEntityDescription` specifying the name or one or more attributes to be used to infer an entity identifier. The value of this string is 'RKEntityIdentificationAttributes'.
 */
extern NSString * const RKEntityIdentificationAttributesUserInfoKey;

///----------------
/// @name Functions
///----------------

/**
 Returns an array of attributes likely to be usable for identification purposes inferred from the given entity.
 
 Please see the documentation accompanying the `RKEntityMapping` class for details about the inference rules.
 
 @param entity The entity to infer identification from.
 @return An array containing identifying attributes inferred from the given entity or `nil` if none could be inferred.
 */
NSArray *RKIdentificationAttributesInferredFromEntity(NSEntityDescription *entity);


@interface RKEntityMapping (Deprecations)
@property (nonatomic, copy) NSString *modificationKey DEPRECATED_ATTRIBUTE_MESSAGE("Use `setModificationAttributeForName:` instead");
@end
