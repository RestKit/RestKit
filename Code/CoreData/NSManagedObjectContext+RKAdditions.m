//
//  NSManagedObjectContext+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <objc/runtime.h>
#import "NSManagedObjectContext+RKAdditions.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKLog.h"

@implementation NSManagedObjectContext (RKAdditions)

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

    NSFetchRequest *fetchRequest = [NSFetchRequest new];
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
