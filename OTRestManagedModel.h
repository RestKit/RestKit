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
 *	The primaryKey property mapping, defaults to @"id" for rails generated XML
 */
+ (NSString*)primaryKey;

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

@end
