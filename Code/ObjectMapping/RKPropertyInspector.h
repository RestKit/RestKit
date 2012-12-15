//
//  RKPropertyInspector.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
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

@class NSEntityDescription;

/**
 The `RKPropertyInspector` class provides an interface for introspecting the properties and attributes of classes using the reflection capabilities of the Objective-C runtime. Once inspected, the properties and types are cached.
 */
@interface RKPropertyInspector : NSObject {
  @protected
    NSCache *_propertyNamesToTypesCache;
}

///-----------------------------------------------
/// @name Retrieving the Shared Inspector Instance
///-----------------------------------------------

/**
 Returns the shared property inspector singleton instance.

 @return The shared `RKPropertyInspector` instance.
 */
+ (RKPropertyInspector *)sharedInspector;

///------------------------------------------------------
/// @name Retrieving the Properties and Types for a Class
///------------------------------------------------------

/**
 Returns a dictionary of names and types for the properties of a given class.

 @param objectClass The class to retrieve the property name and types for.
 @return A dictionary containing metadata about the properties of the given class, where the keys in the dictionary are the property names and the values are `Class` objects specifying the type of the property.
 */
- (NSDictionary *)propertyNamesAndTypesForClass:(Class)objectClass;

/**
 Returns the `Class` object specifying the type of the property with given name on a class.

 @param propertyName The name of the property to retrieve the type of.
 @param objectClass The class to retrieve the property from.
 @return A `Class` object specifying the type of the requested property.
 */
- (Class)classForPropertyNamed:(NSString *)propertyName ofClass:(Class)objectClass;

@end

///----------------------------
/// @name Convenience Functions
///----------------------------

/**
 Returns the class of the attribute or relationship property at the key path of the given object.
 
 Given a key path to a string property, this will return an `NSString`, etc.
 
 @param keyPath The key path to the property to retrieve the class of.
 @return The class of the property at the given key path.
 */
Class RKPropertyInspectorGetClassForPropertyAtKeyPathOfObject(NSString *keyPath, id object);
