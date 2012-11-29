//
//  RKEntityIdentifier.h
//  RestKit
//
//  Created by Blake Watters on 11/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

/**
 The name of a key in the user info dictionary of a `NSEntityDescription` specifying the name or one or more attributes to be used to infer an entity identifier. The value of this string is 'RKEntityIdentifierAttributes'.
 */
extern NSString * const RKEntityIdentifierUserInfoKey;

@class RKManagedObjectStore;

/**
 The `RKEntityIdentifier` object describes a means for uniquely identifying one or more `NSManagedObject` objects within a Core Data managed object model. Entity identifiers are used by RestKit to identify existing managed objects that are to be updated while performing object mapping with an `RKEntityMapping` object. Entity identifiers identify objects by specifying the attributes that can be used to uniquely differentiate managed objects within a context.
 */
@interface RKEntityIdentifier : NSObject

///----------------------------------------
/// @name Initializing an Entity Identifier
///----------------------------------------

/**
 Creates and returns a new entity identifier with the entity for the given name and attributes in the specified managed object store.
 
 @param entityName The name of the entity being identified.
 @param attributes An array of `NSString` objects containing the names of attributes or `NSAttributeDescription` objects specifying the identifying attributes for the entity.
 @param managedObjectStore The managed object store containing the managed object model within which the entity exists.
 @return A new entity identifier, configured with the given entity for the given name and the array of attributes.
 */
+ (id)identifierWithEntityName:(NSString *)entityName attributes:(NSArray *)attributes inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

/**
 Initializes the receiver with a given entity and array of attributes.
 
 @param entity The entity being identified.
 @param attributes An array of `NSString` objects containing the names of attributes or `NSAttributeDescription` objects specifying the identifying attributes for the entity.
 @return The receiver, initialized with the given entity and attributes.
 */
- (id)initWithEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributes;

///--------------------------------
/// @name Accessing Entity Identity
///--------------------------------

/**
 The entity that the receiver identifies.
 */
@property (nonatomic, strong, readonly) NSEntityDescription *entity;

/**
 An array of `NSAttributeDescription` objects specifying the attributes used for identification.
 */
@property (nonatomic, copy, readonly) NSArray *attributes;

///---------------------------------------
/// @name Filtering the Identified Objects
///---------------------------------------

/**
 An optional predicate for filtering identified objects.
 */
@property (nonatomic, copy) NSPredicate *predicate;

///-------------------------------------------
/// @name Inferring Identifiers from the Model
///-------------------------------------------

/**
 Creates and returns an entity identifier for the given entity inferred from the managed object model.
 
 When inferring an entity identifier, the entity is first checked for a user info key specifying the identifying attributes. If the user info of the given entity contains a value for the key 'RKEntityIdentifierAttributes', then that value is used to construct an entity identifier. The user info key must contain a string or an array of strings specifying the names of attributes that exist in the given entity.
 
 If no attributes are specified in the user info, then the entity is searched for an attribute whose name matches the llama-cased name of the entity. For example, an entity named 'Article' would have an inferred identifier attribute of 'articleID' and an entity named 'ApprovedComment' would be inferred as 'approvedCommentID'. If such an attribute is found within the entity, an identifier is returned specifying that attribute. If none is returned, the the attributes are search for the following names:
 
 1. 'identifier'
 1. 'ID'
 1. 'URL'
 1. 'url'
 
 If any of these attributes are found, then an entity identifier is created for that attribute. If all possible inferred attributes are exhausted, then `nil` is returned.
 
 @param entity The entity to infer an identifier for.
 @return An entity identifier inferred from the model for the given entity, or `nil` if none could be inferred.
 */
+ (RKEntityIdentifier *)inferredIdentifierForEntity:(NSEntityDescription *)entity;

@end
