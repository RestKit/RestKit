//
//  NSManagedObjectContext+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <objc/runtime.h>
#import "NSManagedObjectContext+RKAdditions.h"

static char NSManagedObject_RKManagedObjectStoreAssociatedKey;

@implementation NSManagedObjectContext (RKAdditions)

- (RKManagedObjectStore *)managedObjectStore
{
    return (RKManagedObjectStore *)objc_getAssociatedObject(self, &NSManagedObject_RKManagedObjectStoreAssociatedKey);
}

- (void)setManagedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    objc_setAssociatedObject(self, &NSManagedObject_RKManagedObjectStoreAssociatedKey, managedObjectStore, OBJC_ASSOCIATION_ASSIGN);
}

@end
