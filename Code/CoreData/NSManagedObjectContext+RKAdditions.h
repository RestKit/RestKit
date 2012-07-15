//
//  NSManagedObjectContext+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RKManagedObjectStore;
typedef void (^NSManagedObjectContextFetchCompleteBlock)(NSArray* results);
typedef void (^NSManagedObjectContextFetchFailBlock)(NSError *error);

/**
 Provides extensions to NSManagedObjectContext for various common tasks.
 */
@interface NSManagedObjectContext (RKAdditions)

/**
 The receiver's managed object store.
 */
@property (nonatomic, assign) RKManagedObjectStore *managedObjectStore;

/**
 Executes supplied fetch request in background thread. Once results are retrieved, the supplied onComplete or onError blocks are executed in the main thread and results are supplied in the correct managed object context of the main thread (approach is from a blog post discussing block based searches by Jonathan Dalrymple).Primarily used for incremental search as you type fetch requests. 
 */
-(void)executeFetchRequestInBackground:(NSFetchRequest*) aRequest 
							onComplete:(NSManagedObjectContextFetchCompleteBlock) completeBlock 
							   onError:(NSManagedObjectContextFetchFailBlock) failBlock;
@end





