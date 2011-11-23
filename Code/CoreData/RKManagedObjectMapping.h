//
//  RKManagedObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters
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

@interface RKManagedObjectMapping : RKObjectMapping {
    NSEntityDescription* _entity;
    NSString* _primaryKeyAttribute;
    NSMutableDictionary* _relationshipToPrimaryKeyMappings;
}

/**
 Creates a new object mapping targetting the specified Core Data entity
 */
+ (RKManagedObjectMapping*)mappingForEntity:(NSEntityDescription*)entity;

/**
 Creates a new object mapping targetting the Core Data entity with the specified name.
 The entity description is fetched from the current managed object context
 */
+ (RKManagedObjectMapping*)mappingForEntityWithName:(NSString*)entityName;

/**
 The Core Data entity description used for this object mapping
 */
@property (nonatomic, readonly) NSEntityDescription* entity;

/**
 The attribute containing the primary key value for the class. This is consulted by
 RestKit to uniquely identify objects within the store using the primary key in your
 remote backend system.
 */
@property (nonatomic, retain) NSString* primaryKeyAttribute;

/**
 Returns a dictionary containing Core Data relationships and attribute pairs containing
 the primary key for 
 */
@property (nonatomic, readonly) NSDictionary* relationshipsAndPrimaryKeyAttributes;

/**
 Instructs RestKit to automatically connect a relationship of the object being mapped by looking up 
 the related object by primary key.
 
 For example, given a Project object associated with a User, where the 'user' relationship is
 specified by a userID property on the managed object:
 
 [mapping connectRelationship:@"user" withObjectForPrimaryKeyAttribute:@"userID"];
 
 Will hydrate the 'user' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.
  
 In effect, this approach allows foreign key relationships between managed objects
 to be automatically maintained from the server to the underlying Core Data object graph.
 */
- (void)connectRelationship:(NSString*)relationshipName withObjectForPrimaryKeyAttribute:(NSString*)primaryKeyAttribute;

/**
 Connects relationships using the primary key values contained in the specified attribute. This method is
 a short-cut for repeated invocation of `connectRelationship:withObjectForPrimaryKeyAttribute:`.
 
 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString*)firstRelationshipName, ... NS_REQUIRES_NIL_TERMINATION;

- (id)initWithEntity:(NSEntityDescription*)entity;

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForMissingAttribute:(NSString*)attributeName;

@end
