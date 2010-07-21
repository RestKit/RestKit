/*
 *  RKResourceMappable.h
 *  RestKit
 *
 *  Created by Blake Watters on 8/14/09.
 *  Copyright 2009 Two Toasters. All rights reserved.
 *
 */

#import "RKRequest.h"

// TODO: De-emphasize this and move...
typedef enum {
	RKMappingFormatXML = 0,
	RKMappingFormatJSON
} RKMappingFormat;

/**
 * Must be implemented by all classes utilizing the RKModelMapper to map REST
 * responses to domain model classes
 */
@protocol RKResourceMappable

/**
 * Must return a dictionary containing mapping from XML element names to property accessors
 */
+ (NSDictionary*)elementToPropertyMappings;

/**
 * Must return a dictionary mapping XML element names to related object accessors. Must
 * return an empty dictionary if there are no related objects.
 *
 * To differentiate between single associated objects and collections, use descendent
 * selectors. For example, given a Project model associated with a user and a collection
 * of tasks:
 *
 * [NSDictionary dictionaryWithObject:@"user" forKey:@"user"];
 * Will map from an XML element named user to the user property on the model instance.
 *
 * [NSDictionary dictionaryWithObject:@"tasks" forKey:@"tasks > task"];
 * Will map from the collection of XML elements named task nested under the tasks element
 * to the tasks property on the model instance. The assigned collection is assumed to be an NSSet.
 */
+ (NSDictionary*)elementToRelationshipMappings;

// TODO: Add an optional errors property. This will be populated when there are errors in the mapping.

/**
 * Return a dictionary of values to be serialized for submission to a remote resource. The router
 * will encode these parameters into a serialization format (form encoded, JSON, etc).
 */
- (NSDictionary*)paramsForSerialization;

@optional

/**
 * Must return a new instance of the model class ready for mapping. Used to initialize the model
 * via any method other than alloc & init.
 */
+ (id)newObject;

@end
