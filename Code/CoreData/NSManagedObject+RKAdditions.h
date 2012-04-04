//
//  NSManagedObject+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RKManagedObjectStore, RKManagedObjectMapping;

/**
 Provides extensions to NSManagedObject for various common tasks.
 */
@interface NSManagedObject (RKAdditions)

/**
 The receiver's managed object store.
 */
- (RKManagedObjectStore *)managedObjectStore;

@end
