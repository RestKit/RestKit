//
//  RKRelationshipConnectionOperation.h
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RKConnectionMapping;
@protocol RKManagedObjectCaching;

@interface RKRelationshipConnectionOperation : NSOperation

@property (nonatomic, retain, readonly) NSManagedObject *managedObject;
@property (nonatomic, retain, readonly) RKConnectionMapping *connectionMapping;
@property (nonatomic, retain, readonly) id<RKManagedObjectCaching> managedObjectCache;

- (id)initWithManagedObject:(NSManagedObject *)managedObject connectionMapping:(RKConnectionMapping *)connectionMapping managedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache;

@end
