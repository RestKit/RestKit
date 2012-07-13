//
//  RKManagedObjectMappingOperationDataSource.h
//  RestKit
//
//  Created by Blake Watters on 7/3/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKMappingOperationDataSource.h"

@protocol RKManagedObjectCaching;

// TODO: Add note about deadlock prevention!!!
@interface RKManagedObjectMappingOperationDataSource : NSObject <RKMappingOperationDataSource>

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) id<RKManagedObjectCaching> managedObjectCache;
@property (nonatomic, assign) NSOperationQueue *operationQueue;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache;

@end
