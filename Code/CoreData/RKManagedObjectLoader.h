//
//  RKManagedObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectLoader.h"
#import "RKManagedObjectStore.h"

@interface RKManagedObjectLoader : RKObjectLoader {
    NSManagedObjectID* _targetObjectID;
	RKManagedObjectStore* _managedObjectStore;	
}

/*
 * In cases where CoreData is used for local object storage/caching, a reference to
 * the managedObjectStore for use in retrieving locally cached objects using the store's
 * managedObjectCache property.
 */
@property (nonatomic, retain) RKManagedObjectStore* managedObjectStore;

@end
