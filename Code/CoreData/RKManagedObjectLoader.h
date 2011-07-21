//
//  RKManagedObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../ObjectMapping/RKObjectLoader.h"
#import "RKManagedObjectStore.h"

/**
 A subclass of the object loader that is dispatched when you
 are loading Core Data managed objects. This differs from the
 transient object loader only by handling the special threading
 concerns imposed by Core Data.
 */
@interface RKManagedObjectLoader : RKObjectLoader {
    NSManagedObjectID* _targetObjectID;	
    NSMutableSet* _managedObjectKeyPaths;
    BOOL _deleteObjectOnFailure;
}

@property (nonatomic, readonly) RKManagedObjectStore* objectStore;

@end
