//
// RKManagedObject.h
//  RestKit
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../ObjectMapping/ObjectMapping.h"

/////////////////////////////////////////////////////////////////////////////////////////////////
// RestKit managed models

@interface RKManagedObject : NSManagedObject <RKObjectMappable> {
	
}

/**
 * The Core Data managed object context from the RKObjectManager's objectStore
 * that is managing this model
 */
+ (NSManagedObjectContext*)managedObjectContext;

/**
 *	The NSEntityDescription for the Subclass 
 *	defaults to the subclass className, may be overridden
 */
+ (NSEntityDescription*)entity;

/**
 *	Returns an initialized NSFetchRequest for the entity, with no predicate
 */
+ (NSFetchRequest*)fetchRequest;

/**
 * Fetches all objects from the persistent store identified by the fetchRequest
 */
+ (NSArray*)objectsWithFetchRequest:(NSFetchRequest*)fetchRequest;

/**
 * Fetches all objects from the persistent store via a set of fetch requests and
 * returns all results in a single array.
 */
+ (NSArray*)objectsWithFetchRequests:(NSArray*)fetchRequests;

/**
 * Fetches the first object identified by the fetch request. A limit of one will be
 * applied to the fetch request before dispatching.
 */
+ (id)objectWithFetchRequest:(NSFetchRequest*)fetchRequest;

/**
 * Fetches all objects from the persistent store by constructing a fetch request and
 * applying the predicate supplied. A short-cut for doing filtered searches on the objects
 * of this class under management.
 */
+ (NSArray*)objectsWithPredicate:(NSPredicate*)predicate;

/**
 * Fetches the first object matching a predicate from the persistent store. A fetch request
 * will be constructed for you and a fetch limit of 1 will be applied.
 */
+ (id)objectWithPredicate:(NSPredicate*)predicate;

/**
 * Fetches all managed objects of this class from the persistent store as an array
 */
+ (NSArray*)allObjects;

/**
 * Returns a count of all managed objects of this class in the persistent store. On
 * error, will populate the error argument
 */
+ (NSUInteger)count:(NSError**)error;

/**
 * Returns a count of all managed objects of this class in the persistent store. Deprecated
 * use the error form above
 *
 * @deprecated
 */
+ (NSUInteger)count DEPRECATED_ATTRIBUTE;

/**
 *	Creates a new managed object and inserts it into the managedObjectContext.
 */
+ (id)object;

/**
 * The name of an object mapped property existing on this class representing the unique primary key. 
 * Must be implemented by the subclass for the mapper to be able to uniquely identify objects.
 */
+ (NSString*)primaryKeyProperty;

/**
 * The name of the primary key in the server-side data payload. This defaults to the key
 * in the element to property mappings corresponding to the primaryKeyProperty value.
 */
+ (NSString*)primaryKeyElement;

/**
 * Returns the instance of this class where the primary key value is value or nil when not found. This
 * is the preferred way to retrieve a single unique object.
 */
+ (id)objectWithPrimaryKeyValue:(id)value;

/**
 * Must return a dictionary mapping Core Data relationships for the managed object
 * to their corresponding primary key properties on the managed object.  Must
 * return an empty dictionary if there are no relationships to be mapped.
 *
 * For example, given a Project object associated with a user, where the user is
 * specified by a userId property on the managed object:
 *
 * [NSDictionary dictionaryWithObject:@"userId" forKey:@"user"];
 * Will hydrate the 'user' association on the managed object with the object
 * in the local object graph having the primary key specified in the managed object's
 * userId property.
 * 
 * In effect, this approach allows foreign key relationships between managed objects
 * to be automatically maintained from the server to the underlying Core Data object graph.
 */
+ (NSDictionary*)relationshipToPrimaryKeyPropertyMappings;

/**
 * Returns the value of the primary key property for this object
 */
- (id)primaryKeyValue;

/**
 * Returns YES when an object has not been saved to the managed object context yet
 */
- (BOOL)isNew;

@end
