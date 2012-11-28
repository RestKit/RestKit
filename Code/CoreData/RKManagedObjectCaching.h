//
//  RKManagedObjectCaching.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 Objects implementing the `RKManagedObjectCaching` provide support for retrieving managed object matching a set of attributes using an opaque caching strategy. The objects retrieved are not required to be in any particular order, but must exactly match the attribute values requested.
 */
@protocol RKManagedObjectCaching <NSObject>

@required

///---------------------------------
/// @name Retrieving Managed Objects
///---------------------------------

/**
 Returns all managed objects for a given entity with attributes whose names and values match the given dictionary in a given context.
 
 @param entity The entity to retrieve managed objects for.
 @param attributeValues A dictionary specifying the attribute criteria for retrieving managed objects.
 @param managedObjectContext The context to fetch the matching objects in.
 */
- (NSArray *)managedObjectsWithEntity:(NSEntityDescription *)entity
                      attributeValues:(NSDictionary *)attributeValues
               inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

///---------------------------------------------------
/// @name Handling Managed Object Change Notifications
///---------------------------------------------------

@optional

/**
 Invoked to inform the receiver that an object was fetched and should be added to the cache.

 @param object The object that was fetched from a managed object context.
 */
- (void)didFetchObject:(NSManagedObject *)object;

/**
 Invoked to inform the receiver that an object was created and should be added to the cache.

 @param object The object that was created in a managed object context.
 */
- (void)didCreateObject:(NSManagedObject *)object;

/**
 Invoked to inform the receiver that an object was deleted and should be removed to the cache.

 @param object The object that was deleted from a managed object context.
 */
- (void)didDeleteObject:(NSManagedObject *)object;

@end
