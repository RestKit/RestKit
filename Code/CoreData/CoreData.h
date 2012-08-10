//
//  CoreData.h
//  RestKit
//
//  Created by Blake Watters on 9/30/10.
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

#import <CoreData/CoreData.h>
#import "ObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"
#import "RKManagedObjectSeeder.h"
#import "RKManagedObjectLoader.h"
#import "RKManagedObjectMapping.h"
#import "RKManagedObjectMappingOperation.h"
#import "RKManagedObjectCaching.h"
#import "RKInMemoryManagedObjectCache.h"
#import "RKFetchRequestManagedObjectCache.h"
#import "RKSearchableManagedObject.h"
#import "RKSearchWord.h"

#import "RKObjectPropertyInspector+CoreData.h"
#import "RKObjectMappingProvider+CoreData.h"
#import "NSManagedObjectContext+RKAdditions.h"
#import "NSManagedObject+RKAdditions.h"
#import "NSEntityDescription+RKAdditions.h"
