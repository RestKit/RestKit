//
//  RKSyncManager.m
//  RestKit
//
//  Created by Evan Cordell, Mark Makdad.
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

// The default time that the interval timer should wait before sending new sync requests.
#define RK_SYNC_TIMER_DEFAULT 60

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
- (void)_reachabilityChangedNotificationReceived:(NSNotification *)reachabilityNotification;
@end

@implementation RKSyncManager

@synthesize objectManager = _objectManager, delegate = _delegate;
@synthesize defaultSyncStrategy = _defaultSyncStrategy, defaultSyncDirection = _defaultSyncDirection;

#pragma mark - Init & Dealloc

- (id)initWithObjectManager:(RKObjectManager*)objectManager {
    self = [super init];
    if (self) {
        // By default, batch similar objects together & reduce network calls if possible.
        _defaultSyncStrategy = RKSyncStrategyBatch;
        // By default, push AND pull objects from the server at the same time
        _defaultSyncDirection = RKSyncDirectionBoth;
      
        _strategies = [[NSMutableDictionary alloc] init];
        _directions = [[NSMutableDictionary alloc] init];
        
        // This timer controls when items with RKSyncModeInterval will be synced.
        [self setSyncInterval:RK_SYNC_TIMER_DEFAULT];
    
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
                                                 selector:@selector(_reachabilityChangedNotificationReceived:) 
                                                     name:RKReachabilityDidChangeNotification 
                                                   object:self.objectManager.client.reachabilityObserver];
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_intervalTimer invalidate];
    [_intervalTimer release];
    _intervalTimer = nil;
  
    [_objectManager release];
    _objectManager = nil;
    
    [_queue release];
    _queue = nil;
    
    [_strategies release];
    _strategies = nil;
  
    [_directions release];
    _directions = nil;
    
    [super dealloc];
}

#pragma mark - Sync Direction

- (void)setDefaultSyncDirection:(RKSyncDirection)direction {
    return [self setSyncDirection:direction forClass:nil];
}

- (void)setSyncDirection:(RKSyncDirection)syncDirection forClass:(Class)objectClass {
    NSString *className = NSStringFromClass(objectClass);
    if (className) {
        [_strategies setObject:[NSNumber numberWithInt:syncDirection] forKey:className];
    }
    else {
      // Just set the default; they passed a nil class reference
      _defaultSyncDirection = syncDirection;
    }
}

- (RKSyncDirection) syncDirectionForClass:(Class)objectClass {
    RKSyncDirection direction = _defaultSyncDirection;
    NSString *className = NSStringFromClass(objectClass);
    if (className) {
        NSNumber *value = [_directions objectForKey:className];
        if (value) {
            direction = (RKSyncDirection)[value integerValue];
        }
    }
    return direction;
}

#pragma mark - Sync Strategy

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

#pragma mark - NSManagedObjectContextDidSaveNotification Observer

- (void)contextDidSave:(NSNotification *)notification {
    // Notification keys of the object sets we care about
    NSArray *objectKeys = [NSArray arrayWithObjects:NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey, nil];
  
    BOOL somethingAdded = NO;
    BOOL shouldPull = NO;
  
    // Iterate through each type of object change, and then iterate the objects for each type.
    for (NSString *changeType in objectKeys)
    {
        NSSet *objects = [[notification userInfo] objectForKey:changeType];
        for (NSManagedObject *object in objects)
        {
            RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:[object class]];
            RKSyncDirection direction = [self syncDirectionForClass:[object class]];
            RKSyncMode mode = mapping.syncMode;
            if (mode == RKSyncModeNone || [object isKindOfClass:[RKManagedObjectSyncQueue class]]) {
                // Ignore objects that are non-syncing, or are internal storage for this class.
                continue;
            } else if (direction == RKSyncDirectionPull) {
                // If we are only pulling, note that, but don't generate any queue items.
                shouldPull = YES;
            } else {
                // Depending on the change type, enqueue an object with a different method.  In Delete & Update cases,
                // first call -shouldDelete/-shouldUpdate to determine whether we should even bother (depends on strategy)
                if ([changeType isEqualToString:NSInsertedObjectsKey])
                {
                  somethingAdded = (somethingAdded || [self addQueueItemForObject:object syncMethod:RKRequestMethodPOST syncMode:mode]);
                }
                else if ([changeType isEqualToString:NSDeletedObjectsKey] && [self shouldDeleteObject:object])
                {
                  somethingAdded = (somethingAdded || [self addQueueItemForObject:object syncMethod:RKRequestMethodDELETE syncMode:mode]);
                }
                else if ([changeType isEqualToString:NSUpdatedObjectsKey] && [self shouldUpdateObject:object])
                {
                  somethingAdded = (somethingAdded || [self addQueueItemForObject:object syncMethod:RKRequestMethodPUT syncMode:mode]);
                }
            }
        }
    }
  
    // transparent sync needs to be called on every nontrivial save and every network change - but only if something was added,
    // otherwise we will end up in an infinite loop, as the other parts of RestKit also save the MOC when this is called.
    if (somethingAdded || shouldPull)
    {
      [self transparentSync];
    }
}

#pragma mark - Interval Sync Timer

- (void)intervalTimerFired:(NSTimer *)intervalTimer {
    [self syncObjectsWithSyncMode:RKSyncModeInterval andClass:nil];
}

- (void)setSyncInterval:(NSTimeInterval)interval {
  NSAssert((interval > 0),@"Time interval must be greater than zero.");
  
  // Stop the timer first, then re-create it.
  [_intervalTimer invalidate];
  [_intervalTimer release];
  
  _intervalTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(intervalTimerFired:)
                                                  userInfo:nil
                                                   repeats:YES];
  [_intervalTimer retain];
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
  
    // We can save ourselves a lot of processing if we were provided a class & we have a direction for it.
    if (objectClass) {
        RKSyncDirection direction = [self syncDirectionForClass:objectClass];
        if ((direction & RKSyncDirectionPush) == NO) {
            // They don't need us to sync pushes, so we are fine to return.
            return;
        }
    }
  
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
    
    // If the queue is empty, quick return here.
    if ([_queue count] == 0)
    {
      return;
    }
  
    // Put the objects all back together now so we can send them to the delegate
    NSMutableSet *objects = [NSMutableSet setWithCapacity:[_queue count]];
    NSMutableArray *tmpQueue = [[NSMutableArray alloc] initWithCapacity:[_queue count]];
    for (RKManagedObjectSyncQueue *item in _queue) {
        NSManagedObject *object = [context objectWithID:[self objectIDWithString:item.objectIDString]];
        NSAssert(object,@"Sync queue became out of date with Core Data store; referring to object: %@ that no longer exists.",item.objectIDString);
      
        RKSyncDirection direction = [self syncDirectionForClass:NSClassFromString(item.className)];
        if (direction & RKSyncDirectionPush) {
            [tmpQueue addObject:item];
            [objects addObject:object];
        }
    }
    // Now reset our queue to the new one
    [_queue release];
    _queue = tmpQueue;
  
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPushObjects:withSyncMode:)]) {
        [_delegate syncManager:self willPushObjects:(NSSet *)objects withSyncMode:syncMode];
    }
  
    RKManagedObjectSyncQueue *item = nil;
    while ((item = [_queue lastObject])) {
        NSManagedObject *object = [context objectWithID:[self objectIDWithString:item.objectIDString]];
        // Depending on what type of item this is, make the appropriate RestKit call to send it up
        RKRequestMethod method = [item.syncMethod integerValue];
        if (method == RKRequestMethodPOST) {
            [_objectManager postObject:object delegate:self];
            _requestCounter++;
        } else if (method == RKRequestMethodPUT) {
            [_objectManager putObject:object delegate:self];
            _requestCounter++;
        } else if (method == RKRequestMethodDELETE) {
            [_objectManager deleteObject:object delegate:self];
            _requestCounter++;
        }
        
        // Remove this item from the in-memory queue; note this doesn't touch Core Data yet.
        [_queue removeObject:item];
    }
  
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPushObjects:withSyncMode:)]) {
        [_delegate syncManager:self didPushObjects:(NSSet *)objects withSyncMode:syncMode];
    }
}

- (void)pullObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");

    // We can save ourselves a lot of processing if we were provided a class & we have a direction for it.
    if (objectClass) {
      RKSyncDirection direction = [self syncDirectionForClass:objectClass];
      if ((direction & RKSyncDirectionPull) == NO) {
        // They don't need us to sync pulls, so we are fine to return.
        return;
      }
    }
  
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPullObjectsOfClass:withSyncMode:)]) {
        [_delegate syncManager:self willPullObjectsOfClass:objectClass withSyncMode:syncMode];
    }
    
    NSDictionary *mappings = _objectManager.mappingProvider.mappingsByKeyPath;
    for (id key in mappings) {
        RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[mappings objectForKey:key];
        BOOL classMatches = (objectClass == nil || mapping.objectClass == objectClass);
        if (mapping.syncMode == syncMode && classMatches) {
            NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:mapping.entity insertIntoManagedObjectContext:nil]; 
            NSString *resourcePath = [_objectManager.router resourcePathForObject:object method:RKRequestMethodGET]; 
            [object release];
            
            RKSyncDirection direction = [self syncDirectionForClass:[object class]];
            if ((direction & RKSyncDirectionPull)) {
              [_objectManager loadObjectsAtResourcePath:resourcePath delegate:self];
              _requestCounter++;
            }
          
        }
    }
  
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPullObjectsOfClass:withSyncMode:)]) {
        [_delegate syncManager:self didPullObjectsOfClass:objectClass withSyncMode:syncMode];
    }
}

- (void)transparentSync {
    //Syncs objects set to RKSyncModeTransparent. Called on reachability notification
    if ([_objectManager.client.reachabilityObserver isNetworkReachable]) {
        [self pushObjectsWithSyncMode:RKSyncModeTransparent andClass:nil];
        [self pullObjectsWithSyncMode:RKSyncModeTransparent andClass:nil];
    }
}

- (void) _reachabilityChangedNotificationReceived:(NSNotification *)reachabilityNotification
{
  [self transparentSync];
}

#pragma mark - Public Syncing Methods

- (void)sync {
    [self syncObjectsOfClass:nil];
}

- (void)syncObjectsOfClass:(Class)objectClass {
    [self syncObjectsWithSyncMode:RKSyncModeManual andClass:objectClass];
}

- (void)push {
    if (_requestCounter > 0)
    {
        // Don't let this method be called repetitively if we're already running a queue.
        return;
    }
    [self pushObjectsWithSyncMode:RKSyncModeManual andClass:nil];
}

- (void)pull {
    if (_requestCounter > 0)
    {
        // Don't let this method be called repetitively if we're already running a queue.
        return;
    }
    [self pullObjectsWithSyncMode:RKSyncModeManual andClass:nil];
}

#pragma mark - RKObjectLoaderDelegate (RKRequestDelegate) methods

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader {
    // A request finished, decrement the counter
    _requestCounter--;
    NSAssert((_requestCounter >= 0),@"Request counter can never go negative.");
    
    // Only remove from the queue if we've just pushed (sourceObject exists) and the response is successful.
    if (objectLoader.sourceObject && [objectLoader.response isSuccessful]) {
        
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
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didFailSyncingWithError:)]) {
        [_delegate syncManager:self didFailSyncingWithError:error];
    }
}

@end