/*
 *  RKObjectMappable.h
 *  RestKit
 *
 *  Created by Blake Watters on 8/14/09.
 *  Copyright 2009 Two Toasters. All rights reserved.
 *
 */

@protocol RKRequestSerializable;
@class RKObjectLoader;

/**
 * Must be implemented by all classes utilizing the RKModelMapper to map REST
 * responses to domain model classes
 */
@protocol RKObjectMappable <NSObject>

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

/**
 * Must return an array containing names of relationship properties to serialize
 */
+ (NSArray*)relationshipsToSerialize;

@optional

/**
 * Must return a new autoreleased instance of the model class ready for mapping. Used to initialize the model
 * via any method other than alloc &amp; init.
 */
+ (id)object;

/**
 * Return a dictionary of values to be serialized for submission to a remote resource. The router
 * will encode these parameters into a serialization format (form encoded, JSON, etc). This is
 * required to use putObject: and postObject: for updating and creating remote object representations.
 */
- (NSDictionary*)propertiesForSerialization;

/**
 * Return a dictionary of relationships to be serialized for submission to a remote resource. The router
 * will encode these parameters into a serialization format (form encoded, JSON, etc). This is
 * required to use putObject: and postObject: for updating and creating remote object representations.
 */
- (NSDictionary*)relationshipsForSerialization;

/**
 * Invoked before the mappable object is sent with an Object Loader. This
 * can be used to completely customize the behavior of an object loader at the 
 * model level before sending the request. Note that this is invoked after the
 * router has processed and just before the object loader is sent.
 *
 * If you want to customize the behavior of the parameters sent with the request
 * this is the right place to do so.
 */
- (void)willSendWithObjectLoader:(RKObjectLoader*)objectLoader;

@end

/**
 * Returns a dictionary containing all the mappable properties
 * and their values for a given mappable object.
 */
NSDictionary* RKObjectMappableGetProperties(NSObject<RKObjectMappable>*object);

/**
 * Returns a dictionary containing all the mappable properties
 * and their values keyed by the element name. 
 */
NSDictionary* RKObjectMappableGetPropertiesByElement(NSObject<RKObjectMappable>*object);

/**
 * Return all the serialzable mapped relationships of object in a dictionary under their element names
 */
NSDictionary* RKObjectMappableGetRelationshipsByElement(NSObject<RKObjectMappable>*object);
