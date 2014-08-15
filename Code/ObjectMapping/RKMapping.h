//
//  RKMapping.h
//  RestKit
//
//  Created by Blake Watters on 7/31/11.
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

#import <Foundation/Foundation.h>

/**
 `RKMapping` is an abstract class for objects defining RestKit object mappings. Its interface is common to all object mapping classes, including its concrete subclasses `RKObjectMapping` and `RKDynamicMapping`.
 */
@interface RKMapping : NSObject

///---------------------------------
/// @name Forcing Collection Mapping
///---------------------------------

/**
 Forces the mapper to treat the mapped keyPath as a collection even if it does not return an array or a set of objects. This permits mapping where a dictionary identifies a collection of objects.

 When enabled, each key/value pair in the resolved dictionary will be mapped as a separate entity. This is useful when you have a JSON structure similar to:

     { "users": {
        "blake":  { "id": 1234, "email": "blake@restkit.org" },
        "rachit": { "id": 5678, "email": "rachit@restkit.org" }
        }
     }

 By enabling `forceCollectionMapping`, RestKit will map "blake" => attributes and "rachit" => attributes as independent objects. This can be combined with `mapKeyOfNestedDictionaryToAttribute:` to properly map these sorts of structures.

 @default `NO`
 @see `mapKeyOfNestedDictionaryToAttribute`
 */
@property (nonatomic, assign) BOOL forceCollectionMapping;


///-------------------------
/// @name Comparing Mappings
///-------------------------

/**
 Returns `YES` if the receiver and the specified mapping are considered equivalent.

 **NOTE**: Must be implemented in subclass.
 */
- (BOOL)isEqualToMapping:(RKMapping *)otherMapping;

@end
