//
//  RKManagedObjectStore+RKSearchAdditions.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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
    [searchIndexer release];
}

- (void)addSearchIndexingToEntityForName:(NSString *)entityName onAttributes:(NSArray *)attributes
{
    NSAssert(! self.persistentStoreCoordinator, @"Add indexing to your entities before adding persistent stores. The managed object model must be mutable to add indexing.");
    
    if (! self.searchIndexer) [self createSearchIndexer];
    
    NSEntityDescription *entity = [[self.managedObjectModel entitiesByName] objectForKey:entityName];
    [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:attributes];
}

- (void)startIndexingPrimaryManagedObjectContext
{
    [self.searchIndexer startObservingManagedObjectContext:self.primaryManagedObjectContext];
}

- (void)stopIndexingPrimaryManagedObjectContext
{
    [self.searchIndexer stopObservingManagedObjectContext:self.primaryManagedObjectContext];
}

@end
