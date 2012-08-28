//
//  RKConnectionMapping.h
//  RestKit
//
//  Created by Charlie Savage on 5/15/12.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKMapping.h"

@class RKConnectionMapping, RKDynamicMappingMatcher;
@protocol RKManagedObjectCaching;

typedef id(^RKObjectConnectionBlock)(RKConnectionMapping *mapping, id source);

// Defines the rules for connecting relationsips
/**
 Instructs RestKit to connect a relationship of the object being mapped to the
 appropriate target object(s).  It does this by using the value of the object's
 fromKeyPath attribute to query instances of the target entity that have the
 same value in their toKeyPath attribute.
 
 Note that connectRelationship runs *after* an object's attributes have been
 mapped and is dependent upon the results of those mappings.  Also, connectRelationship
 will never create a new object - it simply looks up existing objects.   In effect,
 connectRelationship allows foreign key relationships between managed objects
 to be automatically maintained from the server to the underlying Core Data object graph.
 
 For example, given a Project object associated with a User, where the 'user' relationship is
 specified by a userID property on the managed object:
 
 [mapping connectRelationship:@"user" withMapping:userMapping fromKeyPath:@"userId" toKeyPath:@"id"];
 
 Will hydrate the 'user' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.
 
 You can also do the reverse. Given a User object associated with a Project, with a
 'project' relationship:
 
 [mapping connectRelationship:@"project" fromKeyPath:@"id" toKeyPath:@"userId" withMapping:projectMapping];
 */
//- (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping DEPRECATED_ATTRIBUTE;

/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 keyPath equal to a specified value.
 
 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:
 
 [mapping connectRelationship:@"admin" fromKeyPath:@"adminId" toKeyPath:@"id" withMapping:userMapping whenValueOfKeyPath:@"userType" isEqualTo:@"Admin"];
 
 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the Product's 'userType'
 property equals 'Admin'. In cases where no match occurs, the relationship connection is skipped.
 
 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
// - (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value DEPRECATED_ATTRIBUTE;
/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 block evaluate to YES. This variant is useful in cases where you want to execute an arbitrary
 block to determine whether or not to connect a relationship.
 
 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:
 
 [mapping connectRelationship:@"admin" fromKeyPath:@"adminId" toKeyPath:@"adminID" withMapping:userMapping usingEvaluationBlock:^(id data) {
 return [User isAuthenticated];
 }];
 
 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the provided block evalutes to YES.
 In cases where no match occurs, the relationship connection is skipped.
 
 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */

@interface RKConnectionMapping : NSObject

@property (nonatomic, strong, readonly) NSString *relationshipName;
@property (nonatomic, strong, readonly) NSString *sourceKeyPath;
@property (nonatomic, strong, readonly) NSString *destinationKeyPath;
@property (nonatomic, strong, readonly) RKMapping *mapping;
@property (nonatomic, strong, readonly) RKDynamicMappingMatcher *matcher;

/**
 Defines a mapping that is used to connect a source object relationship to
 the appropriate target object(s).

 @param relationshipName The name of the relationship on the source object.
 @param sourceKeyPath Specifies the path to an attribute on the source object that
 contains the value that should be used to connect the relationship.  This will generally
 be a primary key or a foreign key value.
 @param targetKeyPath Specifies the path to an attribute on the target object(s) that
 must match the value of the sourceKeyPath attribute.
 @param withMapping The mapping for the target object.

 @return A new instance of a RKObjectConnectionMapping.
 */
+ (RKConnectionMapping *)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping;

/**
 Defines a mapping that is used to connect a source object relationship to
 the appropriate target object(s).  This is similar to mapping:fromKeyPath:toKeyPath:withMapping:
 (@see mapping:fromKeyPath:toKeyPath:withMapping:) but adds in an additional matcher parameter
 that can be used to filter source objects.

 @return A new instance of a RKObjectConnectionMapping.
 */
+ (RKConnectionMapping *)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping matcher:(RKDynamicMappingMatcher *)matcher;

/**
 Initializes the receiver with a relationship name, source key path, destination key path, mapping, and matcher.
 */
- (id)initWithRelationshipName:(NSString *)relationshipName sourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath mapping:(RKMapping *)objectOrDynamicMapping matcher:(RKDynamicMappingMatcher *)matcher;

@end
