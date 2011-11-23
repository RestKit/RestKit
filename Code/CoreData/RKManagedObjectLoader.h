//
//  RKManagedObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright 2011 Two Toasters
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

#import "RKObjectLoader.h"
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
