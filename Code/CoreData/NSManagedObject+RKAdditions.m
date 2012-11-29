//
//  NSManagedObject+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "NSManagedObject+RKAdditions.h"
#import "NSManagedObjectContext+RKAdditions.h"
#import "RKLog.h"
#import "RKManagedObjectStore.h"

@implementation NSManagedObject (RKAdditions)

- (BOOL)hasBeenDeleted
{
    NSManagedObject *managedObjectClone = [[self managedObjectContext] existingObjectWithID:[self objectID] error:nil];
    return (managedObjectClone == nil) ? YES : NO;
}

- (BOOL)isNew
{
    NSDictionary *vals = [self committedValuesForKeys:nil];
    return [vals count] == 0;
}

@end
