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
 * The Core Data managed object context from the RKModelManager's objectStore
 * that is managing this model
 */
+ (NSManagedObjectContext*)managedObjectContext;

/**
 *	The NSEntityDescription for the Subclass 
 *	defaults to the subclass className, may be overridden
 */
// TODO: Should be entityDescription
+ (NSEntityDescription*)entity;

/**
 *	Returns an initialized NSFetchRequest for the entity, with no predicate
 */
// TODO: Should be fetchRequest
+ (NSFetchRequest*)request;

// TODO: Stays, document all these guys...
+ (NSArray*)objectsWithRequest:(NSFetchRequest*)request;
+ (id)objectWithRequest:(NSFetchRequest*)request; // objectWithFetchRequest:
+ (NSArray*)objectsWithPredicate:(NSPredicate*)predicate;
+ (id)objectWithPredicate:(NSPredicate*)predicate;
+ (NSArray*)allObjects;

// Count the objects of this class in the store...
+ (NSUInteger)count;

/**
 *	Creates a new managed object and inserts it into the managedObjectContext.
 */
+ (id)object;

/**
 *	Retrieves a model object from the appropriate context using the objectId
 */
// TODO: Moves to objectStore
+ (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID;

/**
 *	Retrieves a array of model objects from the appropriate context using
 *	an array of NSManagedObjectIDs
 */
// TODO: Moves to objectStore
+ (NSArray*)objectsWithIDs:(NSArray*)objectIDs;

// TODO: RKObjectFindable / RKObjectPersistable??? RKObjectLocatable / RKObjectAddressable
/**
 *	The primaryKey property mapping, defaults to @"railsID"
 */
// Moves to mapper? primaryKeyForObjectClass: / primaryKeyElementForObjectClass: / primaryKeyFo
+ (NSString*)primaryKey;

/**
 * The name of the primary key in the server-side data payload. Defaults to @"id" for Rails generated XML/JSON
 */
+ (NSString*)primaryKeyElement;

/**
 *	Will find the existing object with the primary key of 'value' and return it
 *	or return nil
 */
+ (id)findByPrimaryKey:(id)value;

/**
 * Returns all the XML/JSON element names for the properties of this model
 */
// TODO: Moves to the mapper perhaps???
+ (NSArray*)elementNames;

// The server side name of the model?
// TODO: Should be registered on the model manager somehow...
// TODO: Use entity name on managed model?
// TODO: Moves to the router probably...
+ (NSString*)modelName;

/**
 * Formats an element name to match the encoding format of a mapping request. By default, assumes
 * that the element name should be dasherized for XML and underscored for JSON
 */
// TODO: Moves to the router...
+ (NSString*)formatElementName:(NSString*)elementName forMappingFormat:(RKMappingFormat)format;

/**
 * Return a fetch request used for querying locally cached objects in the Core Data
 * store for a given resource path. The default implementation does nothing, so subclasses
 * are responsible for parsing the object path and building a valid fetch request.
 */
// TODO: Gets removed...
+ (NSFetchRequest*)fetchRequestForResourcePath:(NSString*)resourcePath;

- (NSDictionary*)elementNamesAndPropertyValues;

/**
 * Returns YES when an object has not been saved to the managed object context yet
 */
- (BOOL)isNew;

@end
