/*
 *  RKObjectMappable.h
 *  RestKit
 *
 *  Created by Blake Watters on 8/14/09.
 *  Copyright 2009 Two Toasters. All rights reserved.
 *
 */

@protocol RKRequestSerializable;

/**
 * Must be implemented by all classes utilizing the RKModelMapper to map REST
 * responses to domain model classes
 */
@protocol RKObjectMappable

/**
 * Must return a dictionary containing mapping from JSON element names to property accessors
 */
+ (NSDictionary*)elementToPropertyMappings;

/**
 * Must return a dictionary mapping JSON element names to related object accessors. Must
 * return an empty dictionary if there are no related objects.
 *
 * When assigning a collection of related objects, use key-value coding to traverse the
 * collection and access the descendent objects. For example, given a Project object
 * associated with a user and a collection of tasks:
 *
 * [NSDictionary dictionaryWithObject:@"user" forKey:@"user"];
 * Will map from an element named 'user' to the user property on the model instance.
 *
 * [NSDictionary dictionaryWithObject:@"tasks" forKey:@"tasks.task"];
 * Will map each 'task' element nested under a containing element named 'tasks' and
 * assign the collection to the tasks property on the target object.
 * The assigned collection is assumed to be an NSSet.
 */
+ (NSDictionary*)elementToRelationshipMappings;

@optional

/**
 * Return a dictionary of values to be serialized for submission to a remote resource. The router
 * will encode these parameters into a serialization format (form encoded, JSON, etc). This is
 * required to use putObject: and postObject: for updating and creating remote object representations.
 */
- (NSObject<RKRequestSerializable>*)paramsForSerialization;

/**
 * Must return a new autoreleased instance of the model class ready for mapping. Used to initialize the model
 * via any method other than alloc & init.
 */
+ (id)object;

@end
