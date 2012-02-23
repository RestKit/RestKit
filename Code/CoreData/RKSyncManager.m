//
//  RKSyncManager.m
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKSyncManager.h"

@implementation RKSyncManager

@synthesize objectManager = _objectManager;

- (id)initWithObjectManager:(RKObjectManager*)objectManager {
    self = [super init];
	if (self) {
        _objectManager = [objectManager retain];
        
        //Register for notifications from the managed object context associated with the object manager
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(contextDidSave:) 
                                                     name: NSManagedObjectContextDidSaveNotification
                                                   object: self.objectManager.objectStore.managedObjectContext];
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_objectManager release];
    _objectManager = nil;
    
    [super dealloc];
}

- (void)contextDidSave:(NSNotification *)notification {
    //Insert changes into queue
    NSSet *insertedObjects = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    
    NSSet *allObjects = [[insertedObjects setByAddingObjectsFromSet:updatedObjects] setByAddingObjectsFromSet:deletedObjects];
    
    for (NSManagedObject *object in allObjects) {
        if (![object isKindOfClass:[RKManagedObjectSyncQueue class]]) {
            //push new object onto queue
            RKManagedObjectSyncQueue *newRecord = [RKManagedObjectSyncQueue object];
            if ([insertedObjects containsObject:object]) {
                newRecord.syncStatus = [NSNumber numberWithInt:RKSyncStatusPost];
            }
            if ([updatedObjects containsObject:object]) {
                newRecord.syncStatus = [NSNumber numberWithInt:RKSyncStatusPut];
            }
            if ([deletedObjects containsObject:object]) {
                newRecord.syncStatus = [NSNumber numberWithInt:RKSyncStatusDelete];
            }
            
            newRecord.queuePosition = [NSNumber numberWithInt: [self highestQueuePosition] + 1];
            
            RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)[[_objectManager mappingProvider] objectMappingForClass:[object class]];
            newRecord.primaryKeyString = [[object valueForKey:[mapping primaryKeyAttribute]] stringValue];
            newRecord.objectIDString = [[[object objectID] URIRepresentation] absoluteString];
            
            NSLog(@"Writing to queue: %@", newRecord);
            NSError *error = nil;
            [[newRecord managedObjectContext] save:&error];
            if (error) {
                NSLog(@"Error! %@", error);
            }
        }
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
@end
