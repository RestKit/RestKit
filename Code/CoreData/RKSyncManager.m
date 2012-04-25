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
@end

@implementation RKSyncManager

@synthesize objectManager = _objectManager, delegate = _delegate;

- (id)initWithObjectManager:(RKObjectManager*)objectManager {
    self = [super init];
	if (self) {
        _objectManager = [objectManager retain];
        _queue = [[NSMutableArray alloc] init];

        //Register for notifications from the managed object context associated with the object manager
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(contextDidSave:) 
                                                     name: NSManagedObjectContextDidSaveNotification
                                                   object: self.objectManager.objectStore.managedObjectContextForCurrentThread];
        
        //Register for reachability changes for transparent syncing
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(transparentSync) 
                                                     name:RKReachabilityDidChangeNotification 
                                                   object: self.objectManager.client.reachabilityObserver];
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_objectManager release];
    _objectManager = nil;
    
    [_queue release];
    _queue = nil;
    
    _delegate = nil;
    
    [super dealloc];
}

- (NSString *)IDStringForObject:(NSManagedObject *)object {
    return [[[object objectID] URIRepresentation] absoluteString];
}

#pragma mark - Queue Management

- (BOOL)addQueueItemForObject:(NSManagedObject *)object syncStatus:(RKSyncStatus)syncStatus syncMode:(RKSyncMode)syncMode {
    RKManagedObjectSyncQueue *newQueueItem = [RKManagedObjectSyncQueue object];
    newQueueItem.syncStatus = [NSNumber numberWithInt:syncStatus];
    newQueueItem.queuePosition = [NSNumber numberWithInt: [[RKManagedObjectSyncQueue maxValueFor:@"queuePosition"] intValue] + 1];
    newQueueItem.objectIDString = [self IDStringForObject:object];
    newQueueItem.className = NSStringFromClass([object class]);
    newQueueItem.syncMode = [NSNumber numberWithInt:syncMode];
    if (syncStatus == RKSyncStatusDelete) {
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

- (BOOL)shouldUpdateObject:(NSManagedObject *)object {
    BOOL shouldUpdate = YES;
    // Find any existing records on the queue
    NSArray *queueItems = [self queueItemsForObject:object];
    for (RKManagedObjectSyncQueue *queuedRequest in queueItems) {
      // Quick return if we already have an update request in the sync queue
      if ([queuedRequest.syncStatus intValue] == RKSyncStatusPut) {
        RKLogTrace(@"'Update' item exists in sync queue for object: %@", object);
        shouldUpdate = NO;
      }
    }
    return shouldUpdate;
}

- (BOOL) deleteQueueItemsForObject:(NSManagedObject *)object
{
  // Check if there is something on the queue
  NSArray *queueItems = [self queueItemsForObject:object];

  // Assume that it exists on the server until we find out otherwise
  BOOL existsOnServer = YES;

  // Remove any preceding queue items for this object, since we're just going to delete it anyway with this request.
  for (RKManagedObjectSyncQueue *queuedRequest in queueItems)
  {
    if ([queuedRequest.syncStatus intValue] == RKSyncStatusPost)
    {
      RKLogTrace(@"Object's lifecycle exists solely in sync queue, deleting w/o sync: %@", object);
      existsOnServer = NO;
    }
    [queuedRequest deleteEntity];
  }
  
  // Return YES if there is a need to create a DELETE queue item
  return existsOnServer;
}

- (BOOL) syncObject:(NSManagedObject *)object syncMode:(RKSyncMode)mode changeType:(NSString *)changeType
{
  BOOL shouldSync = NO;
  
  if ([changeType isEqualToString:NSInsertedObjectsKey])
  {
    shouldSync = [self addQueueItemForObject:object syncStatus:RKSyncStatusPost syncMode:mode];
  }
  else if ([changeType isEqualToString:NSDeletedObjectsKey])
  {
    //deleted objects should remove other entries
    //if a post record exists, we can just delete locally
    //otherwise we need to send the delete to the server
    BOOL existsOnServer = [self deleteQueueItemsForObject:object];
    if (existsOnServer)
    {
      shouldSync = [self addQueueItemForObject:object syncStatus:RKSyncStatusDelete syncMode:mode];
    }
  }
  //updated objects should be put, unless there's already a post or a delete
  else if ([changeType isEqualToString:NSUpdatedObjectsKey] && [self shouldUpdateObject:object])
  {
      shouldSync = [self addQueueItemForObject:object syncStatus:RKSyncStatusPut syncMode:mode];
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
        [_queue addObjectsFromArray:[RKManagedObjectSyncQueue findAllSortedBy:@"queuePosition" ascending:NO withPredicate:predicate inContext:context]];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:willPushObjectsInQueue:withSyncMode:andClass:)]) {
        [_delegate syncManager:self willPushObjectsInQueue:_queue withSyncMode:syncMode andClass:objectClass];
    }
    
    while ([_queue lastObject]) {
        RKManagedObjectSyncQueue *item = (RKManagedObjectSyncQueue*)[_queue lastObject];
        NSManagedObjectID *itemID = [_objectManager.objectStore.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:item.objectIDString]];
        
        switch ([item.syncStatus intValue]) {
            case RKSyncStatusPost:
                [_objectManager postObject:[context objectWithID:itemID] delegate:self];
                break;
            case RKSyncStatusPut:
                [_objectManager putObject:[context objectWithID:itemID] delegate:self];
                break;
            case RKSyncStatusDelete:
                [[_objectManager client] delete:item.objectRoute delegate:self];
                break;
            default:
                break;
        }
        
        [_queue removeObject:item];
        [item deleteInContext:context];
        NSError *error = nil;
        [context save:&error];
        if (error) {
            RKLogError(@"Error removing queue item: %@", error);
        }
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
    if ([objectLoader.response isSuccessful]) {
        if ([objectLoader isPOST] || [objectLoader isPUT] || [objectLoader isDELETE]) {
            NSError *error = nil;
            [_objectManager.objectStore save:&error];
            if (error) {
                RKLogError(@"Error saving store: %@", error);
            }
            RKLogTrace(@"Total unsynced objects: %i", [objectLoader.queue loadingCount]);
            
        }
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    if (_delegate && [_delegate respondsToSelector:@selector(syncManager:didFailSyncingWithError:)]) {
        [_delegate syncManager:self didFailSyncingWithError:error];
    }
}

@end