//
//  RKFetchRequestManagedObjectCache.h
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

#import "RKManagedObjectCaching.h"

/**
 Provides a simple managed object cache strategy in which every request for an object
 is satisfied by dispatching an NSFetchRequest against the Core Data persistent store.
 Performance can be disappointing for data sets with a large amount of redundant data
 being mapped and connected together, but the memory footprint stays flat.
 */
@interface RKFetchRequestManagedObjectCache : NSObject <RKManagedObjectCaching>

@end
