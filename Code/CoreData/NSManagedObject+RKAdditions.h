//
//  NSManagedObject+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RKManagedObjectStore, RKManagedObjectMapping;

@interface NSManagedObject (RKAdditions)

/**
 The receiver's managed object store.
 */
- (RKManagedObjectStore *)managedObjectStore;

@end
