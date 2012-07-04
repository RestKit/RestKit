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

typedef void (^RKSyncNetworkOperationBlock)(void);

@interface RKSyncManager (Private)

@property (nonatomic, assign, readwrite) __block NSInteger networkOperationCount;

- (void)contextDidSave:(NSNotification*)notification;

//Shortcut for transparent syncing; used for notification call
- (void)transparentSync;

// Helper method for getting the unique ID of a managed object as a string
- (NSString *)IDStringForObject:(NSManagedObject *)object;

- (BOOL)addQueueItemForObject:(NSManagedObject *)object syncMethod:(RKRequestMethod)syncMethod syncMode:(RKSyncMode)syncMode;
- (NSArray *)queueItemsForObject:(NSManagedObject *)object;

// Returns YES if we should create a queue object for this object on update
- (BOOL)shouldUpdateObject:(NSManagedObject *)object strategy:(RKSyncStrategy)strategy;
- (BOOL)shouldDeleteObject:(NSManagedObject *)object strategy:(RKSyncStrategy)strategy;
- (BOOL) removeExistingQueueItemsForObject:(NSManagedObject *)object;
- (void)_reachabilityChangedNotificationReceived:(NSNotification *)reachabilityNotification;

- (void)addCompletedQueueItem:(RKManagedObjectSyncQueue *) item;
- (void)addFailedQueueItem:(RKManagedObjectSyncQueue *) item;
- (void)checkIfQueueFinishedWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

- (void)sendObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

@end

@implementation RKSyncManager

@synthesize objectManager = _objectManager, delegate = _delegate;
@synthesize networkOperationQueue = _networkOperationQueue, networkOperationCount = _networkOperationCount;
@synthesize defaultSyncMode = _defaultSyncMode, defaultSyncStrategy = _defaultSyncStrategy, defaultSyncDirection = _defaultSyncDirection;
@synthesize syncEnabled;

#pragma mark - Init & Dealloc

- (id)initWithObjectManager:(RKObjectManager*)objectManager {
    self = [super init];
    if (self) {
        // By default, don't sync objects
        _defaultSyncMode = RKSyncModeNone;
        // By default, batch similar objects together & reduce network calls if possible.
        _defaultSyncStrategy = RKSyncStrategyBatch;
        // By default, push AND pull objects from the server at the same time
        _defaultSyncDirection = RKSyncDirectionBoth;
        
        _networkOperationQueue = dispatch_queue_create("com.RestKit.Syncing.NetworkOperationsQueue", DISPATCH_QUEUE_CONCURRENT);
        _networkOperationCount = 0;
        
        _objectManager = [objectManager retain];
        _queue = [[NSMutableArray alloc] init];
        _completedQueueItems = [[NSMutableArray alloc] init];
        _failedQueueItems = [[NSMutableArray alloc] init];
      
        // Turn us on by default - this can be disabled by the client code if necessary
        self.syncEnabled = YES;

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
    
    [_queue release];
    _queue = nil;
    
    dispatch_release(_networkOperationQueue);
    _networkOperationQueue = nil;
    
    [_completedQueueItems release];
    _completedQueueItems = nil;
    
    [_failedQueueItems release];
    _failedQueueItems = nil;
    
    [super dealloc];
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
- (BOOL)shouldUpdateObject:(NSManagedObject *)object strategy:(RKSyncStrategy)strategy {
    BOOL shouldUpdate = YES;
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
- (BOOL)shouldDeleteObject:(NSManagedObject *)object  strategy:(RKSyncStrategy)strategy {
    BOOL shouldDelete = YES;
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
    
    //TODO: We have to do the following two steps a lot, pull it out into a method
    //e.g. syncStrategy:forClass: (Private)
    RKManagedObjectMapping *mapping = ((RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:objectClass]);
    RKSyncStrategy strategy = (mapping.syncStrategy == RKSyncStrategyDefault) ? _defaultSyncStrategy : mapping.syncStrategy;;
    
    if (queueCount > 0)
    {
        // weak reference
        __block RKSyncManager *blocksafeSelf = self;
        __block NSObject<RKSyncManagerDelegate> *blocksafeDelegate = _delegate;
        
        NSManagedObjectContext *context = _objectManager.objectStore.managedObjectContextForCurrentThread;
        
        //Build set of objects that will be synced (deleted objects not garaunteed to exist)
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
        
        
        //These network operations can run concurrently, and so are added normally to the networkOperationsQueue
        for (__block RKManagedObjectSyncQueue *item in _queue) {
            NSManagedObject *object = [context objectWithID:[self objectIDWithString:item.objectIDString]];
            
            //TODO: if statement should be refactored so that it only creates the blocks
            
            // Depending on what type of item this is, make the appropriate RestKit call 
            RKRequestMethod method = [item.syncMethod integerValue];
            if (method == RKRequestMethodPOST) {
                RKSyncNetworkOperationBlock postBlock = ^{
                    _networkOperationCount++;
                    [_objectManager postObject:object usingBlock:^(RKObjectLoader *loader){
                        loader.onDidLoadObject = ^ (id object){
                            _networkOperationCount--;
                            [blocksafeSelf addCompletedQueueItem: item];
                            [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                        };
                        loader.onDidFailWithError = ^ (NSError *error){
                            _networkOperationCount--;
                            [blocksafeSelf addFailedQueueItem: item];
                            [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                            if (blocksafeDelegate && [blocksafeDelegate respondsToSelector:@selector(syncManager:didFailSyncingQueueItem:withError:)]) {
                                [blocksafeDelegate syncManager:self didFailSyncingQueueItem:item withError:error];
                            }
                        };
                    }];
                };
                
                //if we're using proxy only, it's important that each operation happen in order.
                if (strategy == RKSyncStrategyBatch) {
                    dispatch_async(_networkOperationQueue, postBlock);
                } else if (strategy == RKSyncStrategyProxyOnly){
                    dispatch_barrier_async(_networkOperationQueue, postBlock);
                }
                
            } else if (method == RKRequestMethodPUT) {
                RKSyncNetworkOperationBlock putBlock = ^{
                    _networkOperationCount++;
                    [_objectManager putObject:object usingBlock:^(RKObjectLoader *loader){
                        loader.onDidLoadObject = ^ (id object){
                            _networkOperationCount--;
                            [blocksafeSelf addCompletedQueueItem: item];
                            [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                        };
                        loader.onDidFailWithError = ^ (NSError *error){
                            _networkOperationCount--;
                            [blocksafeSelf addFailedQueueItem: item];
                            [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                            if (blocksafeDelegate && [blocksafeDelegate respondsToSelector:@selector(syncManager:didFailSyncingQueueItem:withError:)]) {
                                [blocksafeDelegate syncManager:self didFailSyncingQueueItem:item withError:error];
                            }
                        };
                    }];
                }; 
                
                //if we're using proxy only, it's important that each operation happen in order.
                if (strategy == RKSyncStrategyBatch) {
                    dispatch_async(_networkOperationQueue, putBlock);
                } else if (strategy == RKSyncStrategyProxyOnly){
                    dispatch_barrier_async(_networkOperationQueue, putBlock);
                }
                
            } else if (method == RKRequestMethodDELETE) {
                //The object doesn't necessarily exist if the context has been saved since it was deleted, so we send using the stored route
                RKSyncNetworkOperationBlock deleteBlock = ^{
                    _networkOperationCount++;
                    [[_objectManager client] delete:item.objectRoute usingBlock: ^(RKRequest *request ){
                        request.onDidLoadResponse = ^ (RKResponse *response){
                            _networkOperationCount--;
                            if ([response isSuccessful]) {
                                [blocksafeSelf addCompletedQueueItem: item];
                                [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                            } else {
                                [blocksafeSelf addFailedQueueItem: item];
                                [blocksafeSelf checkIfQueueFinishedWithSyncMode:syncMode andClass:objectClass];
                                if (blocksafeDelegate && [blocksafeDelegate respondsToSelector:@selector(syncManager:didFailSyncingQueueItem:withError:)]) {
                                    [blocksafeDelegate syncManager:self didFailSyncingQueueItem:item withError:nil];
                                }
                            }
                        };
                    }];
                };
 
                //if we're using proxy only, it's important that each operation happen in order.
                if (strategy == RKSyncStrategyBatch) {
                    dispatch_async(_networkOperationQueue, deleteBlock);
                } else if (strategy == RKSyncStrategyProxyOnly){
                    dispatch_barrier_async(_networkOperationQueue, deleteBlock);
                }
            }
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
        
        // We've been working with a transient queue: delete the items from the core data queue now.
        for (RKManagedObjectSyncQueue *item in _completedQueueItems) {
            [item deleteEntity];
        }
        
        [_queue removeAllObjects];
        [_completedQueueItems removeAllObjects];
        [_failedQueueItems removeAllObjects];
        
        if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPushObjects:withSyncMode:)]) {
            [_delegate syncManager:self didPushObjects:(NSSet *)objectSet withSyncMode:syncMode];
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
  
    BOOL somethingAddedToQueue = NO;
    BOOL shouldPull = NO;
  
    // Iterate through each type of object change, and then iterate the objects for each type.
    for (NSString *changeType in objectKeys)
    {
        NSSet *objects = [[notification userInfo] objectForKey:changeType];
        for (NSManagedObject *object in objects)
        {
            RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:[object class]];
            RKSyncDirection direction = (mapping.syncDirection == RKSyncDirectionDefault) ? _defaultSyncDirection : mapping.syncDirection;
            RKSyncMode mode = (mapping.syncMode == RKSyncModeDefault) ? _defaultSyncMode : mapping.syncMode;
            if (mode == RKSyncModeNone || [object isKindOfClass:[RKManagedObjectSyncQueue class]]) {
                // Ignore objects that are non-syncing, or are internal storage for this class.
                continue;
            } else if (direction == RKSyncDirectionPull) {
                // If we are only pulling, note that, but don't generate any queue items.
                shouldPull = YES;
            } else {
                RKSyncStrategy strategy = (mapping.syncStrategy == RKSyncStrategyDefault) ? _defaultSyncStrategy : mapping.syncStrategy;
                // Depending on the change type, enqueue an object with a different method.  In Delete & Update cases,
                // first call -shouldDelete/-shouldUpdate to determine whether we should even bother (depends on strategy)
                if ([changeType isEqualToString:NSInsertedObjectsKey])
                {
                    BOOL added = [self addQueueItemForObject:object syncMethod:RKRequestMethodPOST syncMode:mode];
                  somethingAddedToQueue = (somethingAddedToQueue || added);
                }
                else if ([changeType isEqualToString:NSDeletedObjectsKey] && [self shouldDeleteObject:object strategy:strategy])
                {
                  BOOL added = [self addQueueItemForObject:object syncMethod:RKRequestMethodDELETE syncMode:mode];
                  somethingAddedToQueue = (somethingAddedToQueue || added);
                }
                else if ([changeType isEqualToString:NSUpdatedObjectsKey] && [self shouldUpdateObject:object strategy:strategy])
                {
                  BOOL added = [self addQueueItemForObject:object syncMethod:RKRequestMethodPUT syncMode:mode];
                  somethingAddedToQueue = (somethingAddedToQueue || added);
                }
            }
        }
    }
  
    // transparent sync needs to be called on every nontrivial save and every network change - but only if something was added,
    // otherwise we will end up in an infinite loop, as the other parts of RestKit also save the MOC when this is called.
    if (somethingAddedToQueue || shouldPull)
    {
      [self transparentSync];
    }
}

#pragma mark - Sync Methods

- (void)syncObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willSyncWithSyncMode:andClass:)]) {
        [_delegate syncManager:self willSyncWithSyncMode:syncMode andClass:objectClass];
    }
    
    [self sendObjectsWithSyncMode:syncMode andClass:objectClass];
    [self pullObjectsWithSyncMode:syncMode andClass:objectClass];
  
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didSyncWithSyncMode:andClass:)]) {
        [_delegate syncManager:self didSyncWithSyncMode:syncMode andClass:objectClass];
    }
}

- (void)pushObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    //This is the front-facing method, it should only be called when you don't want to pull after pushing (sync)
    [self sendObjectsWithSyncMode:syncMode andClass:objectClass];
}

- (void)pullObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
    NSAssert(syncMode || objectClass,@"Either syncMode or objectClass must be passed to this method.");
    
    __block NSObject<RKSyncManagerDelegate> *blocksafeDelegate = _delegate;
    
    NSDictionary *mappings = _objectManager.mappingProvider.mappingsByKeyPath;
    for (id key in mappings) {
        RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[mappings objectForKey:key];
        BOOL classMatches = (objectClass == nil || mapping.objectClass == objectClass);
        
        RKSyncMode mappingSyncMode = (mapping.syncMode == RKSyncModeDefault) ? _defaultSyncMode : mapping.syncMode;
        if (mappingSyncMode == syncMode && classMatches) {
            NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:mapping.entity insertIntoManagedObjectContext:nil]; 
            NSString *resourcePath = [_objectManager.router resourcePathForObject:object method:RKRequestMethodGET]; 
            [object release];
            
            RKSyncDirection direction = (mapping.syncDirection == RKSyncDirectionDefault) ? _defaultSyncDirection : mapping.syncDirection;
            if ((direction & RKSyncDirectionPull)) {
              if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPullObjectsOfClass:withSyncMode:)]) {
                [_delegate syncManager:self willPullObjectsOfClass:objectClass withSyncMode:syncMode];
              }
                
                //Pull requests create a barrier in the queue. We need all push requests to finish before we pull so that the server can respond with all of the data that has been sent.
                dispatch_barrier_async(_networkOperationQueue, ^{
                    [_objectManager loadObjectsAtResourcePath:resourcePath usingBlock:^(RKObjectLoader *loader) {
                        _networkOperationCount++;
                        loader.onDidLoadObjects = ^(NSArray *objects){
                            //TODO: delegate call
                            _networkOperationCount--;
                        };
                        loader.onDidFailWithError = ^(NSError *error){
                            _networkOperationCount--;
                            if (blocksafeDelegate && [blocksafeDelegate respondsToSelector:@selector(syncManager:didFailSyncingWithError:)]) {
                                //TODO: Need a good delegate call (no syncQueueItem in this case)
                                //[blocksafeDelegate syncManager:self didFailSyncingQueueItem withError:<#(NSError *)#> WithError:error];
                            }
                        };
                    }];
                });
                
              
              if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didPullObjectsOfClass:withSyncMode:)]) {
                [_delegate syncManager:self didPullObjectsOfClass:objectClass withSyncMode:syncMode];
              }
            }
        }
    }
}

- (void)transparentSync {
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