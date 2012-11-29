//
//  RKConnectionDescription.h
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
 The `RKConnectionDescription` class describes a means for connecting a Core Data relationship. Connections can be established either by foreign key, in which case one or more attribute values on the source entity correspond to matching values on the destination entity, or by key path, in which case a key path is evaluated on the object graph to obtain a value for the relationship. Connection objects are used by instances of `RKRelationshipConnectionOperation` to connect a relationship of a given managed object.
 
 ## Foreign Key Connections
 
 A foreign key connection is established by identifying managed objects within a context which have corresponding values on the source and destination objects. This is typically used to model relationships in the same way one would within a relational database. 
 
 For example, consider the example of a `User` entity that has a to-many relationship named 'projects' for the `Project` entity. Within the `User` entity, there is an attribute named 'userID' that models the value for a given user's primary key as provided to the application by the remote backend API with which it is communicating. Within the `Project` entity, a corresponding 'userID' attribute exists specifying the value of the primary key for the `User` that owns the project. The applications loads each of these object representations independently from the '/me/profile' and '/projects' resources. The JSON representation returned for a given `Project` entity looks something like:
 
    { "project": 
        { "id": 12345, 
          "name": "My Project",
          "userID": 1
        }
    }
 
 When this representation is mapped to a managed object for the `Project` entity, the 'user' relationship cannot be mapped directly because there is no nested representation -- only the primary key is available. In this case, the relationship can be connected by describing the association between the entities with an `RKConnectionDescription` object:
 
    NSEntityDescription *projectEntity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:managedObjectContext];
    NSRelationshipDescription *userRelationship = [projectEntity relationshipsByName][@"user"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:@{ @"userID": @"userID" }];
 
 Note that the value for the `attributes` argument is provided as a dictionary. Each pair within the dictionary correspond to an attribute pair in which the key is an attribute on the source entity (in this case, the `Project`) and the value is the destination entity (in this case, the `User`).
 
 Any number of attribute pairs may be specified, but all values must match for the connection to be satisfied and the relationship's value to be set.
 
 ## Key Path Connections
 
 A key path connection is established by evaluating the key path of the connection against the managed object being connected. The returned value has type transformation applied and is then assigned to the relationship.
 
 @see `RKManagedObjectMappingOperationDataSource`
 @see `RKRelationshipConnectionOperation`
 */
@interface RKConnectionDescription : NSObject <NSCopying>

///-----------------------------------------------
/// @name Connecting Relationships by Foreign Keys
///-----------------------------------------------

/**
 Initializes the receiver with a given relationship and a dictionary of attributes specifying how to connect the relationship.
 
 @param relationship The relationship to be connected.
 @param sourceToDestinationEntityAttributes A dictionary specifying how attributes on the source entity correspond to attributes on the destination entity.
 @return The receiver, initialized with the given relationship and attributes.
 */
- (id)initWithRelationship:(NSRelationshipDescription *)relationship attributes:(NSDictionary *)sourceToDestinationEntityAttributes;

/**
 The dictionary of attributes specifying how attributes on the source entity for the relationship correspond to attributes on the destination entity.
 
 This attribute is `nil` unless the value of `isForeignKeyConnection` is `YES`.
 */
@property (nonatomic, copy, readonly) NSDictionary *attributes;

/**
 Returns a Boolean value indicating if the receiver describes a foreign key connection.
 
 @return `YES` if the receiver describes a foreign key connection, else `NO`.
 */
- (BOOL)isForeignKeyConnection;

///-------------------------------------------
/// @name Connecting Relationships by Key Path
///-------------------------------------------

/**
 Initializes the receiver with a given relationship and key path.
 
 @param relationship The relationship to be connected.
 @param keyPath The key path from which to read the value that is to be set for the relationship.
 @return The receiver, initialized with the given relationship and key path.
 */
- (id)initWithRelationship:(NSRelationshipDescription *)relationship keyPath:(NSString *)keyPath;

/**
 The key path that is to be evaluated to obtain the value for the relationship.
 
 This attribute is `nil` unless the value of `isKeyPathConnection` is `YES`.
 */
@property (nonatomic, copy, readonly) NSString *keyPath;

/**
 Returns a Boolean value indicating if the receiver describes a key path connection.
 
 @return `YES` if the receiver describes a key path connection, else `NO`.
 */
- (BOOL)isKeyPathConnection;

///-------------------------------------------------
/// @name Accessing the Relationship to be Connected
///-------------------------------------------------

/**
 Returns the relationship that is to be connected.
 */
@property (nonatomic, strong, readonly) NSRelationshipDescription *relationship;

///----------------------------
/// @name Setting the Predicate
///----------------------------

/**
 An optional predicate for filtering objects to be connected.
 */
@property (nonatomic, copy) NSPredicate *predicate;

@end
