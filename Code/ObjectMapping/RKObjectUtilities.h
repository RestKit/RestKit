//
//  RKObjectUtilities.h
//  RestKit
//
//  Created by Blake Watters on 9/30/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

///----------------
/// @name Functions
///----------------

/**
 Returns a Boolean value that indicates whether the given objects are equal.
 
 The actual method of comparison is dependendent upon the class of the objects given. For example, given two `NSString` objects equality would be tested using `isEqualToString:`.
 
 @param object The first object to compare.
 @param anotherObject The second object to compare.
 @return `YES` if the objects are equal, otherwise `NO`.
 */
BOOL RKObjectIsEqualToObject(id object, id anotherObject);

/**
 Returns a Boolean value that indicates if the given class is a collection.
 
 The following classes are considered collections:
 
 1. `NSSet`
 1. `NSArray`
 1. `NSOrderedSet`
 
 `NSDictionary` objects are **not** considered collections as they are typically object representations.
 
 @param aClass The class to check.
 @return `YES` if the given class is a collection.
 */
BOOL RKClassIsCollection(Class aClass);

/**
 Returns a Boolean value that indicates if the given object is a collection.
 
 Implemented by invoking `RKClassIsCollection` with the class of the given object.
 @param object The object to be tested.
 @return `YES` if the given object is a collection, else `NO`.
 @see `RKClassIsCollection`
 */
BOOL RKObjectIsCollection(id object);

/**
 Returns a Boolean value that indicates if the given object is collection containing only instances of `NSManagedObject` or a class that inherits from `NSManagedObject`.
 
 @param object The object to be tested.
 @return `YES` if the object is a collection containing only `NSManagedObject` derived objects.
 */
BOOL RKObjectIsCollectionContainingOnlyManagedObjects(id object);
