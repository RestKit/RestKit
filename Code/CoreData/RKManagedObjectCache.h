/*
 *  RKManagedObjectCache.h
 *  RestKit
 *
 *  Created by Jeff Arena on 10/15/10.
 *  Copyright 2010 GateGuru. All rights reserved.
 *
 */

/**
 * Class used for determining the set of NSFetchRequest objects that
 * map to a given request URL.
 */
@protocol RKManagedObjectCache
@required

/**
 * Must return an array containing NSFetchRequests for use in retrieving locally
 * cached objects associated with a given request resourcePath.
 */
- (NSArray*)fetchRequestsForResourcePath:(NSString*)resourcePath;

@optional

/**
 * When the managed object cache is compared to objects from a resource path 
 * payload, objects that are in the cache and not returned by the resource 
 * path are normally deleted.  By returning NO from this method you can prevent
 * the deletion of a given object.
 */
- (BOOL)shouldDeleteOrphanedObject:(NSManagedObject*)managedObject; 

@end
