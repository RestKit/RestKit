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

#import <CoreData/CoreData.h>

/*
 `RKSearchWord` implements a managed object subclass for representing search words contained in designated string attributes of entities indexed by an instance of `RKSearchIndexer`.

 @see `RKSearchIndexer`
 */
@interface RKSearchWord : NSManagedObject

///------------------------------------------
/// @name Accessing the Search Word Attribute
///------------------------------------------

/**
 A single search word extracted from an indexed entity.
 */
@property (nonatomic, strong) NSString *word;

@end
