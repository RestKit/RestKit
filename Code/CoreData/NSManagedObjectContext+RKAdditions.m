//
//  NSManagedObjectContext+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <objc/runtime.h>
#import "NSManagedObjectContext+RKAdditions.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKLog.h"

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

- (id)insertNewObjectForEntityForName:(NSString *)entityName
{
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self];
}

- (NSUInteger)countForEntityForName:(NSString *)entityName predicate:(NSPredicate *)predicate error:(NSError **)error
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.predicate = predicate;
    return [self countForFetchRequest:fetchRequest error:error];
}

- (id)fetchObjectForEntity:(NSEntityDescription *)entity withValueForPrimaryKeyAttribute:(id)primaryKeyValue
{
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:primaryKeyValue];
    if (! predicate) {
        RKLogWarning(@"Attempt to fetchObjectForEntity for entity with nil primaryKeyAttribute. Set the primaryKeyAttributeName and try again! %@", self);
        return nil;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest new] autorelease];
    fetchRequest.entity = entity;
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    __block NSError *error;
    __block NSArray *objects;
    [self performBlockAndWait:^{
        objects = [self executeFetchRequest:fetchRequest error:&error];
    }];
    if (! objects) {
        RKLogCoreDataError(error);
        return nil;
    }

    if ([objects count] == 1) {
        return [objects objectAtIndex:0];
    }

    return nil;
}

- (id)fetchObjectForEntityForName:(NSString *)entityName withValueForPrimaryKeyAttribute:(id)primaryKeyValue
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    return [self fetchObjectForEntity:entity withValueForPrimaryKeyAttribute:primaryKeyValue];
}

- (BOOL)saveToPersistentStore:(NSError **)error
{
    NSManagedObjectContext *contextToSave = self;
    while (contextToSave) {
        __block BOOL success;
        [contextToSave performBlockAndWait:^{
            success = [contextToSave save:error];
        }];

        if (! success) return NO;
        if (! contextToSave.parentContext && contextToSave.persistentStoreCoordinator == nil) {
            RKLogWarning(@"Reached the end of the chain of nested managed object contexts without encountering a persistent store coordinator. Objects are not fully persisted.");
            return NO;
        }
        contextToSave = contextToSave.parentContext;
    }

    return YES;
}

@end
