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

- (void)contextDidSave:(NSNotification *)notification {
    //Insert changes into queue
    NSSet *insertedObjects = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    
    NSSet *allObjects = [[insertedObjects setByAddingObjectsFromSet:updatedObjects] setByAddingObjectsFromSet:deletedObjects];
    
    BOOL shouldTransparentSync = NO;
    
    for (NSManagedObject *object in allObjects) {
        RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:[object class]];
        
        //don't check housekeeping objects
        if (![object isKindOfClass:[RKManagedObjectSyncQueue class]] && 
            mapping.syncMode != RKSyncModeNone) {
            
            //if we find important changes, we should transparent sync
            shouldTransparentSync = YES;
            
            //push new item onto queue
            RKManagedObjectSyncQueue *newRecord = [RKManagedObjectSyncQueue object];
            
            //new objects should be posted
            if ([insertedObjects containsObject:object]) {
                newRecord.syncStatus = [NSNumber numberWithInt:RKSyncStatusPost];
            }
            
            //updated objects should be put, unless there's already a post or a delete
            if ([updatedObjects containsObject:object]) {
                RKManagedObjectSyncQueue *existingRecord = [RKManagedObjectSyncQueue findFirstWithPredicate:[NSPredicate predicateWithFormat:@"objectIDString == %@", [[[object objectID] URIRepresentation] absoluteString], nil]];
                //if object is modified but already has an entry for something, skip it
                if (existingRecord) {
                    [newRecord deleteEntity];
                     continue;
                } 
                newRecord.syncStatus = [NSNumber numberWithInt:RKSyncStatusPut];
            }
            
            //deleted objects should remove other entries
            //if a post record exists, we can just delete locally
            //if a put exists without a post, we need to send the delete to the server
            if ([deletedObjects containsObject:object]) {
                NSArray *existingRecords = [RKManagedObjectSyncQueue findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectIDString == %@", [[[object objectID] URIRepresentation] absoluteString], nil]];
                BOOL newExists = NO;
                
                //remove existing records if we're sending a delete request
                if ([existingRecords count] > 0) {
                    for (RKManagedObjectSyncQueue *record in existingRecords) {
                        if ([record.syncStatus intValue] == RKSyncStatusPost) {
                            newExists = YES;
                        } 
                        [record deleteEntity];
                    }
                }
                
                //if a post record existed in the queue, remove the delete request - nothing on the server to delete yet
                if (newExists) {
                    [newRecord deleteEntity];
                    continue;
                } else {
                    //save the delete route
                    newRecord.objectRoute = [_objectManager.router resourcePathForObject:object method:RKRequestMethodDELETE];
                }
                newRecord.syncStatus = [NSNumber numberWithInt:RKSyncStatusDelete];
            }
            
            newRecord.queuePosition = [NSNumber numberWithInt: [[RKManagedObjectSyncQueue maxValueFor:@"queuePosition"] intValue] + 1];
            newRecord.objectIDString = [[[object objectID] URIRepresentation] absoluteString];
            newRecord.className = NSStringFromClass([object class]);
            newRecord.syncMode = [NSNumber numberWithInt:mapping.syncMode];
            
            RKLogTrace(@"Writing to queue: %@", newRecord);
            NSError *error = nil;
            [[newRecord managedObjectContext] save:&error];
            if (error) {
                RKLogError(@"Error writing queue item: %@", error);
            }
        }
    }
    //transparent sync needs to be called on every nontrivial save and every network change
    if (shouldTransparentSync) {
        [self transparentSync];
    }
    
}

- (void)syncObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass {
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

#pragma mark RKObjectLoaderDelegate (RKRequestDelegate) methods

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