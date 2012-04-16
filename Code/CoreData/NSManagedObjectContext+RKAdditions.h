//
//  NSManagedObjectContext+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RKManagedObjectStore;

@interface NSManagedObjectContext (RKAdditions)

/**
 The receiver's managed object store.
 */
@property (nonatomic, assign) RKManagedObjectStore *managedObjectStore;

@end
