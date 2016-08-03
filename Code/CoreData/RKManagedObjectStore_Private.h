//
//  RKManagedObjectStore_Private.h
//  RestKit
//
//  Created by Alexander Edge on 03/08/2016.
//  Copyright © 2016 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NSSet *RKSetOfManagedObjectIDsFromManagedObjectContextDidSaveNotification(NSNotification *notification);
NSSet *RKSetOfManagedObjectIDsFromManagedObjectContextDidSaveNotification(NSNotification *notification)
{
    NSMutableSet <NSManagedObjectID *> *objectIDs = [NSMutableSet set];
    
    void (^unionObjectIDs)(NSMutableSet *, NSSet *) = ^(NSMutableSet *objectIDs, NSSet *objects) {
        if (objects != nil) {
            [objectIDs unionSet:[objects valueForKey:NSStringFromSelector(@selector(objectID))]];
        }
    };
    
    unionObjectIDs(objectIDs,notification.userInfo[NSInsertedObjectsKey]);
    unionObjectIDs(objectIDs,notification.userInfo[NSUpdatedObjectsKey]);
    unionObjectIDs(objectIDs,notification.userInfo[NSDeletedObjectsKey]);
    
    return objectIDs;
}
