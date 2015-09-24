//
//  RKInMemoryManagedObjectCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
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

#import <RestKit/CoreData/RKManagedObjectCaching.h>

/**
 Provides a fast managed object cache where-in object instances are retained in memory to avoid hitting the Core Data persistent store. Performance is greatly increased over fetch request based strategy at the expense of memory consumption.
 */
@interface RKInMemoryManagedObjectCache : NSObject <RKManagedObjectCaching>

- (instancetype)init __attribute__((unavailable("Invoke initWithManagedObjectContext: instead.")));

///---------------------------
/// @name Initializing a Cache
///---------------------------

/**
 Initializes the receiver with a managed object context that is to be observed and used to populate the in memory cache. The receiver may then be used to fulfill cache requests for child contexts of the given managed object context.

 @param managedObjectContext The managed object context with which to initialize the receiver.
 @return The receiver, initialized with the given managed object context.
 */
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;

@end
