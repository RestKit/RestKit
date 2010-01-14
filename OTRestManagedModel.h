//
//  OTManagedModel.h
//  OTRestFramework
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OTRestModelMappableProtocol.h"
#import "OTRestModelManager.h"

@interface OTRestManagedModel : NSManagedObject <OTRestModelMappable> {
	
}

/**
 * The Core Data managed object context from the OTRestModelManager's objectStore
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
+ (NSFetchRequest*)request;

+ (NSArray*)collectionWithRequest:(NSFetchRequest*)request;
+ (id)objectWithRequest:(NSFetchRequest*)request;
+ (NSArray*)collectionWithPredicate:(NSPredicate*)predicate;
+ (id)objectWithPredicate:(NSPredicate*)predicate;
+ (NSArray*)allObjects;


/**
 *	Creates a new OTManagedModel and inserts it into the managedObjectContext.
 */
+ (id)newObject;

/**
 *	The primaryKey property mapping, defaults to @"railsID"
 */
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
 *	Defines the properties which the OTModelMapper maps elements to
 */
+ (NSDictionary*)elementToPropertyMappings;

/**
 *	Defines the relationship properties which the OTModelMapper maps elements to
 *	@"user" => @"user" will map the @"user" element to an NSObject* property @"user"
 *	@"memberships > user" => @"users"   will map the @"user" elements in the @"memberships" element
 *				to an NSSet* property named @"users"
 */
+ (NSDictionary*)elementToRelationshipMappings;

/**
 * Returns all the XML/JSON element names for the properties of this model
 */
+ (NSArray*)elementNames;

/**
 * Returns all the Managed Model property names of this model
 */
+ (NSArray*)elementNames;

// The server side name of the model?
+ (NSString*)modelName;

- (NSDictionary*)elementNamesAndPropertyValues;

/**
 * Save the object into the managed object context
 */
- (NSError*)save;

/**
 * Deletes the object from the managed object context
 */
- (void)destroy;

/**
 * Sets attributes on the model from the XML document according to the element to property/relationship mappings
 */
- (void)setAttributesFromXML:(Element*)XML;

// TODO: Need helper method on superclass for this... setAttributesFromXML:/setAttributesFromJSON:/setAttributesFromPayload?

@end
