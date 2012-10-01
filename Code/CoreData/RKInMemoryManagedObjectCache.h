//
//  RKInMemoryManagedObjectCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKManagedObjectCaching.h"

/**
 Provides a fast managed object cache where-in object instances are retained in
 memory to avoid hitting the Core Data persistent store. Performance is greatly
 increased over fetch request based strategy at the expense of memory consumption.
 */
@interface RKInMemoryManagedObjectCache : NSObject <RKManagedObjectCaching>

/**
 Initializes the receiver with a managed object context that is to be observed
 and used to populate the in memory cache. The receiver may then be used to fulfill
 cache requests for child contexts of the given managed object context.
 
 @param managedObjectContext The managed object context with which to initialize the receiver.
 @return The receiver, initialized with the given managed object context.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
