//
//  RKSyncManager.m
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKSyncManager.h"

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
                                                   object: self.objectManager.objectStore.managedObjectContext];
        
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
            ![object isKindOfClass:[RKDeletedObject class]] && 
            mapping.syncMode != RKSyncModeNone) {
            
            //if we find important changes, we should transparent sync
            shouldTransparentSync = YES;
            
            RKDeletedObject *newDeletedObject = nil;
            
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
                    //Archive deleted objects
                    newDeletedObject = [RKDeletedObject object];
                    newDeletedObject.data = [object toDictionary];
                    NSLog(@"Archiving deleted object: %@", newDeletedObject);
                    NSError *error = nil;
                    [[newDeletedObject managedObjectContext] save:&error];
                    if (error) {
                        NSLog(@"Error! %@", error);
                    }
                    newRecord.objectIDString = [[[newDeletedObject objectID] URIRepresentation] absoluteString];
                }
                newRecord.syncStatus = [NSNumber numberWithInt:RKSyncStatusDelete];
            }
            
            newRecord.queuePosition = [NSNumber numberWithInt: [self highestQueuePosition] + 1];

            if (!newDeletedObject) {
                newRecord.objectIDString = [[[object objectID] URIRepresentation] absoluteString];
            }
            newRecord.className = NSStringFromClass([object class]);
            
            NSLog(@"Writing to queue: %@", newRecord);
            NSError *error = nil;
            [[newRecord managedObjectContext] save:&error];
            if (error) {
                NSLog(@"Error! %@", error);
            }
        }
    }
    //transparent sync needs to be called on every nontrivial save and every network change
    if (shouldTransparentSync) {
        [self transparentSync];
    }
    
}

- (int)highestQueuePosition {
    //Taken directly from apple docs
    
    NSManagedObjectContext *context = self.objectManager.objectStore.managedObjectContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKManagedObjectSyncQueue" inManagedObjectContext:context];
    [request setEntity:entity];
    
    // Specify that the request should return dictionaries.
    [request setResultType:NSDictionaryResultType];
    
    // Create an expression for the key path.
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"queuePosition"];
    
    // Create an expression to represent the function you want to apply
    NSExpression *expression = [NSExpression expressionForFunction:@"max:"
                                                         arguments:[NSArray arrayWithObject:keyPathExpression]];
    
    // Create an expression description using the minExpression and returning a date.
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    
    // The name is the key that will be used in the dictionary for the return value.
    [expressionDescription setName:@"maxQueuePosition"];
    [expressionDescription setExpression:expression];
    [expressionDescription setExpressionResultType:NSInteger32AttributeType]; // For example, NSDateAttributeType
    
    // Set the request's properties to fetch just the property represented by the expressions.
    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
    
    // Execute the fetch.
    NSError *error;
    id requestedValue = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        // Handle the error.
    }
    else {
        if ([objects count] > 0) {
            requestedValue = [[objects objectAtIndex:0] valueForKey:@"maxQueuePosition"];
        }
    }
    
    [expressionDescription release];
    [request release];
    return [requestedValue intValue];
}

- (void)sync {
    //This will sync objects set to manual
    NSManagedObjectContext *context = _objectManager.objectStore.managedObjectContext;
    [_queue removeAllObjects];
    [_queue addObjectsFromArray:[RKManagedObjectSyncQueue findAllSortedBy:@"queuePosition" ascending:NO inContext:context]];
    [self performSelector:@selector(pushObjects) onThread:[NSThread currentThread] withObject:nil waitUntilDone:YES];
    [self performSelector:@selector(pullObjectsWithSyncMode:) onThread:[NSThread currentThread] withObject:[NSNumber numberWithInt:RKSyncModeManual] waitUntilDone:YES];
}

- (void)transparentSync {
    //only syncs objects with syncMode = RKSyncModeTransparent, called whenever network access is available
    if ([_objectManager.client.reachabilityObserver isNetworkReachable]) {
        NSManagedObjectContext *context = _objectManager.objectStore.managedObjectContext;
        [_queue removeAllObjects];
        
        NSMutableArray *allObjects = [[NSMutableArray alloc] initWithArray:[RKManagedObjectSyncQueue findAllSortedBy:@"queuePosition" ascending:NO inContext:context]];
        
        BOOL shouldPush = NO;
        for (RKManagedObjectSyncQueue *item in allObjects) {
            Class objectClass = NSClassFromString(item.className);
            RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:objectClass];
            if (mapping.syncMode == RKSyncModeTransparent) {
                shouldPush = YES;
                [_queue addObject:item];
            }
        }
        
        [allObjects release];
        
        if (shouldPush) {
            [self performSelector:@selector(pushObjects) onThread:[NSThread currentThread] withObject:nil waitUntilDone:YES];
            [self performSelector:@selector(pullObjectsWithSyncMode:) onThread:[NSThread currentThread] withObject:[NSNumber numberWithInt:RKSyncModeTransparent] waitUntilDone:YES];
        }
    }
}

- (void)pushObjects {
    NSManagedObjectContext *context = _objectManager.objectStore.managedObjectContext;
    while ([_queue lastObject]) {
        RKManagedObjectSyncQueue *item = (RKManagedObjectSyncQueue*)[_queue lastObject];
        NSManagedObjectID *itemID = [_objectManager.objectStore.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:item.objectIDString]];
        id object = [context objectWithID:itemID];
        
        switch ([item.syncStatus intValue]) {
            case RKSyncStatusPost:
                [_objectManager postObject:object delegate:self];
                break;
            case RKSyncStatusPut:
                [_objectManager putObject:object delegate:self];
                break;
            case RKSyncStatusDelete:
            {
                Class objectClass = NSClassFromString(item.className);
                RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:objectClass];
                NSManagedObject *toDelete = [[objectClass alloc] initWithEntity:mapping.entity insertIntoManagedObjectContext:nil];
                [toDelete populateFromDictionary:((RKDeletedObject*)object).data];
                
                //We don't use deleteObject so that Restkit doesn't try to clean up our transient nsmanagedobject
                [[_objectManager client] delete:[_objectManager.router resourcePathForObject:toDelete method:RKRequestMethodDELETE] delegate:self];
                [toDelete release];
                break;
            }
            default:
                break;
        }
        
        [_queue removeObject:item];
        [item deleteInContext:context];
        NSError *error = nil;
        [context save:&error];
        if (error) {
            NSLog(@"Error removing queue item! %@", error);
        }
    }
    [RKManagedObjectSyncQueue truncateAllInContext:context];
}

- (void)pullObjectsWithSyncMode:(NSNumber *)syncMode {
    NSDictionary *mappings = _objectManager.mappingProvider.mappingsByKeyPath;
    for (id key in mappings) {
        RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[mappings objectForKey:key];
        if (mapping.syncMode == [syncMode intValue]) {
            NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:mapping.entity insertIntoManagedObjectContext:nil]; 
            NSString *resourcePath = [_objectManager.router resourcePathForObject:object method:RKRequestMethodGET]; 
            [object release];
            [_objectManager loadObjectsAtResourcePath:resourcePath delegate:self];
        }
    }
}

#pragma mark RKObjectLoaderDelegate (RKRequestDelegate) methods

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader {
    if ([objectLoader.response isSuccessful]) {
        if ([objectLoader isPOST] || [objectLoader isPUT] || [objectLoader isDELETE]) {
            [_objectManager.objectStore save];
            
            NSLog(@"Total unsynced objects: %i", [objectLoader.queue loadingCount]);
            
        } else if ([objectLoader isGET]) {
            //A GET request means everything has been pushed and now we're pulling
            if (_delegate && [_delegate respondsToSelector:@selector(didFinishSyncing)]) {
                [_delegate didFinishSyncing];
            }
        }
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    if (_delegate && [_delegate respondsToSelector:@selector(didFailSyncingWithError:)]) {
        [_delegate didFailSyncingWithError:error];
    }
}

@end