//
//  RKFetchRequestManagedObjectCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKManagedObjectCaching.h"

/**
 Provides a simple managed object cache strategy in which every request for an object
 is satisfied by dispatching an NSFetchRequest against the Core Data persistent store.
 Performance can be disappointing for data sets with a large amount of redundant data
 being mapped and connected together, but the memory footprint stays flat.
 */
@interface RKFetchRequestManagedObjectCache : NSObject <RKManagedObjectCaching>

@end
