//
//  RKEntityConnectionOperation.h
//  RestKit
//
//  Created by Blake Watters on 7/4/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObject, RKEntityMapping;
@protocol RKManagedObjectCaching;

@interface RKEntityConnectionOperation : NSOperation

- (id)initWithManagedObject:(NSManagedObject *)managedObject entityMapping:(RKEntityMapping *)entityMapping managedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache;

@end
