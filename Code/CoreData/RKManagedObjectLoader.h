//
//  RKManagedObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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
#import "RKManagedObjectCaching.h"

/**
 A subclass of the object loader that is dispatched when you
 are loading Core Data managed objects. This differs from the
 transient object loader only by handling the special threading
 concerns imposed by Core Data.
 */
@interface RKManagedObjectLoader : RKObjectLoader

/**
 The managed object cache to consult for retrieving existing object instances. Passed
 to the underlying object mapping operation.
 */
@property (nonatomic, retain) id<RKManagedObjectCaching> managedObjectCache;

/**
 The managed object context in which a successful object load will be persisted. The managed
 object loader constructs a private child context in which the object mapping operation is
 performed. If successful, this context is saved, 'pushing' the object loader results into the
 parent context.
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/**
 A main queue managed object context used to retrieve object mapping results for the main thread. After a mapping
 operation has completed, the receiver will serialize the managed objects from the mapping result to NSManagedObjectID's,
 then jump to the main thread and fetch the managed objects from the mainQueueManagedObjectContext and call back the delegate
 with the results of the object loader.
 */
@property (nonatomic, retain) NSManagedObjectContext *mainQueueManagedObjectContext;

@end

@interface RKManagedObjectLoader (Deprecations)
+ (id)loaderWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE;
- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE;
@end
