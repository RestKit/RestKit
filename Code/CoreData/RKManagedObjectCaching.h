//
//  RKManagedObjectCaching.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 Objects implementing the RKManagedObjectCaching protocol can act as the cache
 strategy for RestKit managed object stores. The managed object cache is consulted
 when objects are retrieved from Core Data during object mapping operations and provide
 an opportunity to accelerate the mapping process by trading memory for speed.
 */
@protocol RKManagedObjectCaching

@required

/**
 Retrieves a model object from the object store given a Core Data entity and
 the primary key attribute and value for the desired object.

 @param entity The Core Data entity for the type of object to be retrieved from the cache.
 @param primaryKeyAttribute The name of the attribute that acts as the primary key for the entity.
 @param primaryKeyValue The value for the primary key attribute of the object to be retrieved from the cache.
 @param mmanagedObjectContext The managed object context to be searched for a matching instance.
 @return A managed object that is an instance of the given entity with a primary key and value matching
 the specified parameters, or nil if no object was found.
 */
- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                  withPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
                                    value:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@optional

/**
 Tells the receiver that an object was fetched and should be added to the cache.

 @param object The object that was fetched from a managed object context.
 */
- (void)didFetchObject:(NSManagedObject *)object;

/**
 Tells the receiver that an object was created and should be added to the cache.

 @param object The object that was created in a managed object context.
 */
- (void)didCreateObject:(NSManagedObject *)object;

/**
 Tells the receiver that an object was deleted and should be removed to the cache.

 @param object The object that was deleted from a managed object context.
 */
- (void)didDeleteObject:(NSManagedObject *)object;

@end
