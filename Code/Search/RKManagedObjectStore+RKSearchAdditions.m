//
//  RKManagedObjectStore+RKSearchAdditions.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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
#import "RKManagedObjectStore+RKSearchAdditions.h"
#import "RKSearchWordEntity.h"

static char searchIndexerAssociationKey;

@implementation RKManagedObjectStore (RKSearchAdditions)

- (RKSearchIndexer *)searchIndexer
{
    return (RKSearchIndexer *)objc_getAssociatedObject(self, &searchIndexerAssociationKey);
}

- (void)setSearchIndexer:(RKSearchIndexer *)searchIndexer
{
    objc_setAssociatedObject(self,
                             &searchIndexerAssociationKey,
                             searchIndexer,
                             OBJC_ASSOCIATION_RETAIN);
}

- (void)createSearchIndexer
{
    RKSearchIndexer *searchIndexer = [RKSearchIndexer new];
    self.searchIndexer = searchIndexer;
}

- (void)addSearchIndexingToEntityForName:(NSString *)entityName onAttributes:(NSArray *)attributes
{
    NSAssert(! self.persistentStoreCoordinator, @"Add indexing to your entities before adding persistent stores. The managed object model must be mutable to add indexing.");

    if (! self.searchIndexer) [self createSearchIndexer];

    NSEntityDescription *entity = [[self.managedObjectModel entitiesByName] objectForKey:entityName];
    [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:attributes];
}

- (void)startIndexingPersistentStoreManagedObjectContext
{
    [self.searchIndexer startObservingManagedObjectContext:self.persistentStoreManagedObjectContext];
}

- (void)stopIndexingPersistentStoreManagedObjectContext
{
    [self.searchIndexer stopObservingManagedObjectContext:self.persistentStoreManagedObjectContext];
}

@end
