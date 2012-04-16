//
//  NSManagedObject+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "NSManagedObject+RKAdditions.h"
#import "NSManagedObjectContext+RKAdditions.h"

@implementation NSManagedObject (RKAdditions)

- (RKManagedObjectStore *)managedObjectStore
{
    return self.managedObjectContext.managedObjectStore;
}

@end
