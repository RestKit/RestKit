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
 * Must return an NSFetchRequest for use in retrieving locally
 * cached objects associated with a given request resourcePath.
 */
- (NSFetchRequest*)fetchRequestForResourcePath:(NSString*)resourcePath;

@end
