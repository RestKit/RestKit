//
//  RKManagedObjectSyncQueue.h
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit.
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
#import "NSManagedObject+ActiveRecord.h"

@interface RKManagedObjectSyncQueue : NSManagedObject

@property (nonatomic, retain) NSNumber * queuePosition;
@property (nonatomic, retain) NSNumber * syncMethod;
@property (nonatomic, retain) NSNumber * syncMode;
@property (nonatomic, retain) NSString * objectIDString;
@property (nonatomic, retain) NSString * className;
@property (nonatomic, retain) NSString * objectRoute;

/**
 The queue for `RKSyncManager` is created dynamically right before the Persistent Store is created.
 This method returns the proper NSEntityDescription for `RKManagedObjectSyncQueue` so that it can be
 inserted.
 */
+ (NSEntityDescription *)entityDescription;

@end
