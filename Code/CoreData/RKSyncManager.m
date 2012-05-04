//
//  RKSyncManager.m
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit.
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

#import "RKSyncManager.h"


@interface RKSyncManager (Private)
- (void)contextDidSave:(NSNotification*)notification;

//Shortcut for transparent syncing; used for notification call
- (void)transparentSync;

// Helper method for getting the unique ID of a managed object as a string
- (NSString *)IDStringForObject:(NSManagedObject *)object;

- (BOOL)addQueueItemForObject:(NSManagedObject *)object syncMethod:(RKRequestMethod)syncMethod syncMode:(RKSyncMode)syncMode;
- (NSArray *)queueItemsForObject:(NSManagedObject *)object;
// Returns YES if we should create a queue object for this object on update
- (BOOL)shouldUpdateObject:(NSManagedObject *)object;
@end

@implementation RKSyncManager

@synthesize objectManager = _objectManager, delegate = _delegate, defaultSyncStrategy = _defaultSyncStrategy;

#pragma mark - Init & Dealloc

- (id)initWithObjectManager:(RKObjectManager*)objectManager {
    self = [super init];
    if (self) {
        // By default this class will batch similar objects together & reduce network calls if possible.
        _defaultSyncStrategy = RKSyncStrategyBatch;
        _strategies = [[NSMutableDictionary alloc] init];
    
        _objectManager = [objectManager retain];
        _queue = [[NSMutableArray alloc] init];

        //Register for notifications from the managed object context associated with the object manager
        NSManagedObjectContext *moc = self.objectManager.objectStore.managedObjectContextForCurrentThread;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:) 
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:moc];
        
        //Register for reachability changes for transparent syncing
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(transparentSync) 
                                                     name:RKReachabilityDidChangeNotification 
                                                   object:self.objectManager.client.reachabilityObserver];
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_objectManager release];
    _objectManager = nil;
    
    [_queue release];
    _queue = nil;
    
    [_strategies release];
    _strategies = nil;
  
    _delegate = nil;
    
    [super dealloc];
}

#pragma - Queue Strategies

- (void)setDefaultSyncStrategy:(RKSyncStrategy)syncStrategy {
    return [self setSyncStrategy:syncStrategy forClass:nil];
}

- (void)setSyncStrategy:(RKSyncStrategy)syncStrategy forClass:(Class)objectClass {
    NSString *className = NSStringFromClass(objectClass);
    if (className) {
        // Check that we don't have any queue items with this object type -- that really could cause problems
        for (RKManagedObjectSyncQueue *queueItem in _queue) {
            NSAssert(([queueItem.className isEqualToString:className] == NO),@"Cannot set RKSyncStrategy on a class that already has items in the queue.");
        }
      
        [_strategies setObject:[NSNumber numberWithInt:syncStrategy] forKey:className];
    }
    else {
        // Just set the default; they passed a nil class reference
        _defaultSyncStrategy = syncStrategy;
    }
}

- (RKSyncStrategy) syncStrategyForClass:(Class)objectClass {
    RKSyncStrategy strategy = _defaultSyncStrategy;
    NSString *className = NSStringFromClass(objectClass);
    if (className) {
        NSNumber *value = [_strategies objectForKey:className];
        if (value) {
            strategy = (RKSyncStrategy)[value integerValue];
        }
    }
    return strategy;
}

#pragma mark - Object ID String Helpers

- (NSString *)IDStringForObject:(NSManagedObject *)object {
    return [[[object objectID] URIRepresentation] absoluteString];
}

- (NSManagedObjectID *)objectIDWithString:(NSString *)objIDString {
    return [_objectManager.objectStore.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:objIDString]];
}

#pragma mark - Queue Management

- (BOOL)addQueueItemForObject:(NSManagedObject *)object syncMethod:(RKRequestMethod)syncMethod syncMode:(RKSyncMode)syncMode {
    RKManagedObjectSyncQueue *newQueueItem = [RKManagedObjectSyncQueue object];
    newQueueItem.syncMethod = [NSNumber numberWithInt:syncMethod];
    newQueueItem.queuePosition = [NSNumber numberWithInt: [[RKManagedObjectSyncQueue maxValueFor:@"queuePosition"] intValue] + 1];
    newQueueItem.objectIDString = [self IDStringForObject:object];
    newQueueItem.className = NSStringFromClass([object class]);
    newQueueItem.syncMode = [NSNumber numberWithInt:syncMode];
  
    RKLogTrace(@"Adding item to queue: %@", newQueueItem);
    BOOL success = YES;
    NSError *error = nil;
    if ([[newQueueItem managedObjectContext] save:&error] == NO) {
        RKLogError(@"Error writing queue item: %@", error);
        success = NO;
    }
    return success;
}

- (NSArray *)queueItemsForObject:(NSManagedObject *)object {
    NSString *objectId = [self IDStringForObject:object];
    NSPredicate *objIdPredicate = [NSPredicate predicateWithFormat:@"objectIDString == %@",objectId, nil];
    return [RKManagedObjectSyncQueue findAllWithPredicate:objIdPredicate];
}

// updated objects should be put, unless there's already a post or a delete
- (BOOL)shouldUpdateObject:(NSManagedObject *)object {
    BOOL shouldUpdate = YES;
    RKSyncStrategy strategy = [self syncStrategyForClass:[object class]];
    if (strategy == RKSyncStrategyBatch) {
      // Find records on the queue - if an update already exists, there's no need to store another.
      NSArray *queueItems = [self queueItemsForObject:object];
      for (RKManagedObjectSyncQueue *queuedRequest in queueItems) {
        if ([queuedRequest.syncMethod intValue] == RKRequestMethodPUT) {
          RKLogTrace(@"'Update' item exists in sync queue for object: %@", object);
          shouldUpdate = NO;
        }
      }
    }
    return shouldUpdate;
}

// Check the sync strategy for this object - if it's batch, we may not send this.
- (BOOL)shouldDeleteObject:(NSManagedObject *)object {
    BOOL shouldDelete = YES;
    RKSyncStrategy strategy = [self syncStrategyForClass:[object class]];
    if (strategy == RKSyncStrategyBatch) {
        //deleted objects should remove other entries
        //if a post record exists, we can just delete locally
        //otherwise we need to send the delete to the server
        shouldDelete = [self removeExistingQueueItemsForObject:object];
    }
    return shouldDelete;
}

// Removes all existing queue items for an object.  Return YES if there was a POST request in the queue.
- (BOOL) removeExistingQueueItemsForObject:(NSManagedObject *)object
{
    // Check if there is something on the queue
    NSArray *queueItems = [self queueItemsForObject:object];

    // Assume that it exists on the server until we find out otherwise
    BOOL existsOnServer = YES;

    // Remove any preceding queue items for this object, since we're just going to delete it anyway with this request.
    for (RKManagedObjectSyncQueue *queuedRequest in queueItems) {
        if ([queuedRequest.syncMethod intValue] == RKRequestMethodPOST) {
            RKLogTrace(@"Object's lifecycle exists solely in sync queue, deleting w/o sync: %@", object);
            existsOnServer = NO;
        }
        [queuedRequest deleteEntity];
    }
    
    // Return YES if there is a need to create a DELETE queue item
    return existsOnServer;
}

// Helper method that translates a "changeType" into the proper logic for that type of change.
- (BOOL) syncObject:(NSManagedObject *)object syncMode:(RKSyncMode)mode changeType:(NSString *)changeType
{
    BOOL shouldSync = NO;
    
    if ([changeType isEqualToString:NSInsertedObjectsKey])
    {
        shouldSync = [self addQueueItemForObject:object syncMethod:RKRequestMethodPOST syncMode:mode];
    }
    else if ([changeType isEqualToString:NSDeletedObjectsKey] && [self shouldDeleteObject:object])
    {
        shouldSync = [self addQueueItemForObject:object syncMethod:RKRequestMethodDELETE syncMode:mode];
    }
    else if ([changeType isEqualToString:NSUpdatedObjectsKey] && [self shouldUpdateObject:object])
    {
        shouldSync = [self addQueueItemForObject:object syncMethod:RKRequestMethodPUT syncMode:mode];
    }
    return shouldSync;
}

#pragma mark - NSManagedObjectContextDidSaveNotification Observer

- (void)contextDidSave:(NSNotification *)notification {
    // Notification keys of the object sets we care about
    NSArray *objectKeys = [NSArray arrayWithObjects:NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey, nil];
  
    // By default, there's nothing to transparently sync
    BOOL shouldTransparentSync = NO;

    // Iterate through each type of object change, and then iterate the objects for each type.
    for (NSString *changeType in objectKeys)
    {
        NSSet *objects = [[notification userInfo] objectForKey:changeType];
        for (NSManagedObject *object in objects)
        {
            // Ignore objects that are non-syncing, or are internal storage for this class.
            RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:[object class]];
            if (mapping.syncMode == RKSyncModeNone ||
                [object isKindOfClass:[RKManagedObjectSyncQueue class]]) {
                continue;
            }
            
            // If something says we should sync (regardless of the type of change),
            // we have work to do at the end of the method, so hold the state
            shouldTransparentSync = shouldTransparentSync || [self syncObject:object syncMode:mapping.syncMode changeType:changeType];
        }
    }
  
    //transparent sync needs to be called on every nontrivial save and every network change
    if (shouldTransparentSync) {
        [self transparentSync];
    }
}

#pragma mark - Sync Methods

- (void)syncObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willSyncWithSyncMode:andClass:)]) {
        [_delegate syncManager:self willSyncWithSyncMode:syncMode andClass:objectClass];
    }
    [self pushObjectsWithSyncMode:syncMode andClass:objectClass];
    [self pullObjectsWithSyncMode:syncMode andClass:objectClass];
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didSyncWithSyncMode:andClass:)]) {
        [_delegate syncManager:self didSyncWithSyncMode:syncMode andClass:objectClass];
    }
}

- (void)pushObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    NSManagedObjectContext *context = _objectManager.objectStore.managedObjectContextForCurrentThread;
  
    // Empty the queue, we are going to re-build it based on what is in Core Data.
    [_queue removeAllObjects];
    
    //Build predicate for fetching the right records
    NSPredicate *syncModePredicate = nil;
    NSPredicate *objectClassPredicate = nil;
    NSPredicate *predicate = nil;
    if (syncMode) {
        syncModePredicate = [NSPredicate predicateWithFormat:@"syncMode == %@", [NSNumber numberWithInt:syncMode], nil];
        predicate = syncModePredicate;
    }
    if (objectClass) {
        objectClassPredicate = [NSPredicate predicateWithFormat:@"className == %@", NSStringFromClass(objectClass), nil];
        predicate = objectClassPredicate;
    }
    if (objectClass && syncMode) {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:syncModePredicate, objectClassPredicate, nil]];
    }
    if (predicate) {
        // Note that NSMutableArray doesn't have -firstObject, so instead we retrieved the array with descending order and peel off using -lastObject
        [_queue addObjectsFromArray:[RKManagedObjectSyncQueue findAllSortedBy:@"queuePosition" ascending:NO withPredicate:predicate inContext:context]];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPushObjectsInQueue:withSyncMode:andClass:)]) {
        [_delegate syncManager:self willPushObjectsInQueue:_queue withSyncMode:syncMode andClass:objectClass];
    }
    
    RKManagedObjectSyncQueue *item = nil;
    while ((item = [_queue lastObject])) {
        NSManagedObject *object = [context objectWithID:[self objectIDWithString:item.objectIDString]];
        NSAssert(object,@"Sync queue became out of date with Core Data store; referring to object: %@ that no longer exists.",item.objectIDString);
        
        // Depending on what type of item this is, make the appropriate RestKit call to send it up
        RKRequestMethod method = [item.syncMethod integerValue];
        if (method == RKRequestMethodPOST) {
            [_objectManager postObject:object delegate:self];
        } else if (method == RKRequestMethodPUT) {
            [_objectManager putObject:object delegate:self];
        } else if (method == RKRequestMethodDELETE) {
            [_objectManager deleteObject:object delegate:self];
        }
        
        // Remove this item from the in-memory queue; note this doesn't touch Core Data yet.
        [_queue removeObject:item];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPushObjectsWithSyncMode:andClass:)]) {
        [_delegate syncManager:self didPushObjectsWithSyncMode:syncMode andClass:objectClass];
    }
}

- (void)pullObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPullWithSyncMode:andClass:)]) {
        [_delegate syncManager:self willPullWithSyncMode:syncMode andClass:objectClass];
    }
    
    NSDictionary *mappings = _objectManager.mappingProvider.mappingsByKeyPath;
    for (id key in mappings) {
        RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[mappings objectForKey:key];
        if (mapping.syncMode == syncMode && (!objectClass  || mapping.objectClass == objectClass)) {
            NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:mapping.entity insertIntoManagedObjectContext:nil]; 
            NSString *resourcePath = [_objectManager.router resourcePathForObject:object method:RKRequestMethodGET]; 
            [object release];
            [_objectManager loadObjectsAtResourcePath:resourcePath delegate:self];
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPullWithSyncMode:andClass:)]) {
        [_delegate syncManager:self didPullWithSyncMode:syncMode andClass:objectClass];
    }
}

- (void)sync {
    [self syncObjectsWithSyncMode:RKSyncModeManual andClass:nil];
}

- (void)push {
    [self pushObjectsWithSyncMode:RKSyncModeManual andClass:nil];
}

- (void)pull {
    [self pullObjectsWithSyncMode:RKSyncModeManual andClass:nil];
}

- (void)transparentSync {
    //Syncs objects set to RKSyncModeTransparent. Called on reachability notification
    if ([_objectManager.client.reachabilityObserver isNetworkReachable]) {
        [self pushObjectsWithSyncMode:RKSyncModeTransparent andClass:nil];
        [self pullObjectsWithSyncMode:RKSyncModeTransparent andClass:nil];
    }
}

#pragma mark - RKObjectLoaderDelegate (RKRequestDelegate) methods

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader {
    // If the response is a failure, do not pass go, do not collect $200, and do not remove from the queue.
    if ([objectLoader.response isSuccessful] == NO) {
        return;
    }
  
    // Get the NSManagedObject we were sending
    NSManagedObject *object = (NSManagedObject *)objectLoader.sourceObject;
    NSAssert([object isKindOfClass:[NSManagedObject class]],@"Should be impossible for this to be called with other than NSManagedObject subclasses.");
  
    // Get the first matching object from the queue & remove it
    NSString *IDString = [self IDStringForObject:object];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectIDString == %@",IDString];
    RKManagedObjectSyncQueue *queueItem = (RKManagedObjectSyncQueue *)[RKManagedObjectSyncQueue findFirstWithPredicate:predicate sortedBy:@"queuePosition" ascending:NO];
    NSAssert(queueItem,@"Should be able to find queue item with ID: %@",IDString);
    [queueItem deleteEntity];
    NSError *error = nil;
    if ([_objectManager.objectStore save:&error] == NO) {
        RKLogError(@"Error removing queue item: %@", error);
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didFailSyncingWithError:)]) {
        [_delegate syncManager:self didFailSyncingWithError:error];
    }
}

@end