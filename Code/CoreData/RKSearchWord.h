//
//  RKSearchWord.m
//  RestKit
//
//  Created by Jeff Arena on 3/31/11.
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

#import "NSManagedObject+ActiveRecord.h"
#import "RKSearchableManagedObject.h"

extern NSString * const RKSearchWordPrimaryKeyAttribute;

@interface RKSearchWord : NSManagedObject

@property (nonatomic, retain) NSString *word;
@property (nonatomic, retain) NSSet *searchableManagedObjects;

@end

@interface RKSearchWord (SearchableManagedObjectsAccessors)

- (void)addSearchableManagedObjectsObject:(RKSearchableManagedObject *)searchableManagedObject;
- (void)removeSearchableManagedObjectsObject:(RKSearchableManagedObject *)searchableManagedObject;
- (void)addSearchableManagedObjects:(NSSet *)searchableManagedObjects;
- (void)removeSearchableManagedObjects:(NSSet *)searchableManagedObjects;

@end
