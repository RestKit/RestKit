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

#define EXIT_IF_SYNCING if ([_queue count] > 0) {\
    RKLogWarning(@"Sync manager is currently in a syncing state.");\
    return;\
}\

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
- (BOOL)shouldDeleteObject:(NSManagedObject *)object;
- (BOOL) removeExistingQueueItemsForObject:(NSManagedObject *)object;
- (void)_reachabilityChangedNotificationReceived:(NSNotification *)reachabilityNotification;

- (void)addCompletedQueueItem:(RKManagedObjectSyncQueue *) item;
- (void)addFailedQueueItem:(RKManagedObjectSyncQueue *) item;
- (void)checkIfQueueFinishedWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

- (void)sendObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;
@end

@implementation RKSyncManager

@synthesize objectManager = _objectManager, delegate = _delegate;
@synthesize defaultSyncStrategy = _defaultSyncStrategy, defaultSyncDirection = _defaultSyncDirection;
@synthesize syncEnabled;

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
        
        _objectManager = [objectManager retain];
        _queue = [[NSMutableArray alloc] init];
        _completedQueueItems = [[NSMutableArray alloc] init];
        _failedQueueItems = [[NSMutableArray alloc] init];
      
        // Turn us on by default - this can be disabled by the client code if necessary
        self.syncEnabled = YES;
        
        _shouldPullAfterPush = NO;

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
  
    [_objectManager release];
    _objectManager = nil;
    
    [_strategies release];
    _strategies = nil;
  
    [_directions release];
    _directions = nil;
    
    [_queue release];
    _queue = nil;
    
    [_completedQueueItems release];
    _completedQueueItems = nil;
    
    [_failedQueueItems release];
    _failedQueueItems = nil;
    
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
    
    if (syncMethod == RKRequestMethodDELETE) {
        newQueueItem.objectRoute = [_objectManager.router resourcePathForObject:object method:RKRequestMethodDELETE];
    }
  
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


- (NSArray *) queueItemsForSyncMode:(RKSyncMode)syncMode class:(Class)objectClass {
  NSManagedObjectContext *context = _objectManager.objectStore.managedObjectContextForCurrentThread;
  
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
    return [RKManagedObjectSyncQueue findAllSortedBy:@"queuePosition" ascending:YES withPredicate:predicate inContext:context];
  }
  return [NSArray array];
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

- (void)sendObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    //This is internal, it pushes but if it's called from a "sync" method it will pull afterwards, otherwise it won't
    //This is necessary because we need to pull after all of the objects have successfully been pushed
    // i.e. it's not enough to just call push followed by pull.
    //Note that this still respects "syncDirection", because that's handled in the queue adding
    
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    
    // Get the queue of items for this 
    [_queue addObjectsFromArray:[self queueItemsForSyncMode:syncMode class:objectClass]];
    NSUInteger queueCount = [_queue count];
    
    if (queueCount > 0)
    {
        // weak reference
        __block RKSyncManager *blocksafeSelf = self;
        NSManagedObjectContext *context = _objectManager.objectStore.managedObjectContextForCurrentThread;
        
        //Build set of objects that will be synced (deleted objects not garaunteed to exist
        NSMutableSet *objectSet = [[[NSMutableSet alloc] init] autorelease];
        for (RKManagedObjectSyncQueue *item in _queue) {
            if ([item.syncMethod integerValue] != RKRequestMethodDELETE) {
                [objectSet addObject:[context objectWithID:[self objectIDWithString:item.objectIDString]]];
            }
        }
        
        // Notify the delegate of what is about to happen
        if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPushObjects:withSyncMode:)]) {
            [_delegate syncManager:self willPushObjects:(NSSet *)objectSet withSyncMode:syncMode];
        }
        
        
        
        for (__block RKManagedObjectSyncQueue *item in _queue) {
            NSManagedObject *object = [context objectWithID:[self objectIDWithString:item.objectIDString]];
            
            // Depending on what type of item this is, make the appropriate RestKit call 
            RKRequestMethod method = [item.syncMethod integerValue];
            if (method == RKRequestMethodPOST) {
                [_objectManager postObject:object usingBlock:^(RKObjectLoader *loader){
                    loader.onDidLoadObject = ^ (id object){
                        [blocksafeSelf addCompletedQueueItem: item];
                        [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                    };
                    loader.onDidFailWithError = ^ (id object){
                        [blocksafeSelf addFailedQueueItem: item];
                        [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                    };
                }];
            } else if (method == RKRequestMethodPUT) {
                [_objectManager putObject:object usingBlock:^(RKObjectLoader *loader){
                    loader.onDidLoadObject = ^ (id object){
                        [blocksafeSelf addCompletedQueueItem: item];
                        [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                    };
                    loader.onDidFailWithError = ^ (id object){
                        [blocksafeSelf addFailedQueueItem: item];
                        [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                    };
                }];
            } else if (method == RKRequestMethodDELETE) {
                //The object doesn't necessarily exist if the context has been saved since it was deleted, so we send using the stored route
                [[_objectManager client] delete:item.objectRoute usingBlock: ^(RKRequest *request ){
                    request.onDidLoadResponse = ^ (RKResponse *response){
                        if ([response isSuccessful]) {
                            [blocksafeSelf addCompletedQueueItem: item];
                            [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                        } else {
                            [blocksafeSelf addFailedQueueItem: item];
                            [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                        }
                    };
                }];
            }
        }
    } else {
        if (_shouldPullAfterPush) {
            [self pullObjectsWithSyncMode:syncMode andClass:objectClass];
        }
    }
}

- (void)addCompletedQueueItem:(RKManagedObjectSyncQueue *)item {
    [_completedQueueItems addObject:item];
}

- (void)addFailedQueueItem:(RKManagedObjectSyncQueue *)item {
    [_failedQueueItems addObject:item];
}

- (void)checkIfQueueFinishedWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    //If every queue item has been processed, clean up the queue
    if ([_completedQueueItems count] + [_failedQueueItems count] == [_queue count]) {
        // If some of the requests failed, report an error
        if ([_failedQueueItems count] > 0) {
            RKLogError(@"There was an error sending some items in the queue: %@", _failedQueueItems);
        }
        
        // We've been working with a transient queue: delete the items from the core data queue now.
        for (RKManagedObjectSyncQueue *item in _completedQueueItems) {
            [item deleteEntity];
        }
        
        NSError *error = nil;
        if ([_objectManager.objectStore save:&error] == NO) {
            RKLogError(@"Error removing items from queue: %@", error);
        }
        
        //Get a set of the objects that were successfully sent, in order to notify the delegate
        NSMutableSet *objectSet = [[[NSMutableSet alloc] init] autorelease];
        for (RKManagedObjectSyncQueue *item in _completedQueueItems) {
            if ([item.syncMethod integerValue] != RKRequestMethodDELETE) {
                [objectSet addObject:[_objectManager.objectStore.managedObjectContextForCurrentThread objectWithID:
                                      [self objectIDWithString:item.objectIDString]]];
            }
        }
        
        [_queue removeAllObjects];
        [_completedQueueItems removeAllObjects];
        [_failedQueueItems removeAllObjects];
        
        if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPushObjects:withSyncMode:)]) {
            [_delegate syncManager:self didPushObjects:(NSSet *)objectSet withSyncMode:syncMode];
        }
        
        if (_shouldPullAfterPush) {
            [self pullObjectsWithSyncMode:syncMode andClass:objectClass];
        }
    }
}

#pragma mark - NSManagedObjectContextDidSaveNotification Observer

- (void)contextDidSave:(NSNotification *)notification {
    // If the Sync Manager is currently turned off, just quick return
    if (self.syncEnabled == NO) {
        return;
    }
  
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
                  BOOL added = [self addQueueItemForObject:object syncMethod:RKRequestMethodPOST syncMode:mode];
                  somethingAdded = (somethingAdded || added);
                }
                else if ([changeType isEqualToString:NSDeletedObjectsKey] && [self shouldDeleteObject:object])
                {
                  BOOL added = [self addQueueItemForObject:object syncMethod:RKRequestMethodDELETE syncMode:mode];
                  somethingAdded = (somethingAdded || added);
                }
                else if ([changeType isEqualToString:NSUpdatedObjectsKey] && [self shouldUpdateObject:object])
                {
                  BOOL added = [self addQueueItemForObject:object syncMethod:RKRequestMethodPUT syncMode:mode];
                  somethingAdded = (somethingAdded || added);
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

#pragma mark - Sync Methods

- (void)syncObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    
    EXIT_IF_SYNCING
    
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willSyncWithSyncMode:andClass:)]) {
        [_delegate syncManager:self willSyncWithSyncMode:syncMode andClass:objectClass];
    }
    
    _shouldPullAfterPush = YES;
    [self sendObjectsWithSyncMode:syncMode andClass:objectClass];
  
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didSyncWithSyncMode:andClass:)]) {
        [_delegate syncManager:self didSyncWithSyncMode:syncMode andClass:objectClass];
    }
}

- (void)pushObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    //This is the front-facing method, it should only be called when you don't want to pull after pushing (sync)
    EXIT_IF_SYNCING
    _shouldPullAfterPush = NO;
    [self sendObjectsWithSyncMode:syncMode andClass:objectClass];
}

- (void)pullObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    
    EXIT_IF_SYNCING
    
    // We can save ourselves a lot of processing if we were provided a class & we have a direction for it.
    if (objectClass) {
      RKSyncDirection direction = [self syncDirectionForClass:objectClass];
      if ((direction & RKSyncDirectionPull) == NO) {
        // They don't need us to sync pulls, so we are fine to return.
        return;
      }
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
              if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPullObjectsOfClass:withSyncMode:)]) {
                [_delegate syncManager:self willPullObjectsOfClass:objectClass withSyncMode:syncMode];
              }

              [_objectManager loadObjectsAtResourcePath:resourcePath delegate:nil];
              
              if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPullObjectsOfClass:withSyncMode:)]) {
                [_delegate syncManager:self didPullObjectsOfClass:objectClass withSyncMode:syncMode];
              }
            }
        }
    }
}

- (void)transparentSync {
    EXIT_IF_SYNCING
    //Syncs objects set to RKSyncModeTransparent. Called on reachability notification
    if ([_objectManager.client.reachabilityObserver isNetworkReachable]) {
        [self syncObjectsWithSyncMode:RKSyncModeTransparent andClass:nil];
    }
}

- (void) _reachabilityChangedNotificationReceived:(NSNotification *)reachabilityNotification
{
    [self transparentSync];
}

#pragma mark - Convenience Syncing Methods

- (void)sync {
    [self syncObjectsOfClass:nil];
}

- (void)intervalSyncForClass:(Class)objectClass {
    [self syncObjectsWithSyncMode:RKSyncModeInterval andClass:objectClass];
}

- (void)syncObjectsOfClass:(Class)objectClass {
    [self syncObjectsWithSyncMode:RKSyncModeManual andClass:objectClass];
}

- (void)push {
    [self pushObjectsWithSyncMode:RKSyncModeManual andClass:nil];
}

- (void)pull {
    [self pullObjectsWithSyncMode:RKSyncModeManual andClass:nil];
}

@end