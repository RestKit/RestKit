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
 * The object used to store attributes for each property; used as the value in the class dictionary.
 */
@interface RKPropertyInspectorPropertyInfo : NSObject

/**
 Creates a new RKPropertyInspectorPropertyInfo instance with the given information
 */
+ (instancetype)propertyInfoWithName:(NSString *)name keyValueClass:(Class)kvClass isPrimitive:(BOOL)isPrimitive;

/**
 The name of the property
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 The class used for key-value coding access to the property.
 
 If the property is an object type, then the class set for this key will be the type of the property. If the property is a primitive, then the class set for the key will be the boxed type used for KVC access to the property. For example, an `NSInteger` property is boxed to an `NSNumber` for KVC purposes.
 */
@property (nonatomic, strong, readonly) Class keyValueCodingClass;

/**
 A BOOL value that indicates if the property is a primitive (non-object) value.
 */
@property (nonatomic, readonly) BOOL isPrimitive;

@end


/**
 The `RKPropertyInspector` class provides an interface for introspecting the properties and attributes of classes using the reflection capabilities of the Objective-C runtime. Once inspected, the properties inspection details are cached.
 */
@interface RKPropertyInspector : NSObject

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
 Returns a dictionary keyed by property name that includes the key-value coding class of the property and a Boolean indicating if the property is backed by a primitive (non-object) value. The RKPropertyInspectorPropertyInfo object for each property includes details about the key-value coding class representing the property and if the property is backed by a primitive type.
 
 @param objectClass The class to inspect the properties of.
 @return A dictionary keyed by property name that includes details about all declared properties of the class.
 */
- (NSDictionary *)propertyInspectionForClass:(Class)objectClass;

/**
 Returns the `Class` object specifying the type of the property with given name on a class.

 @param propertyName The name of the property to retrieve the type of.
 @param objectClass The class to retrieve the property from.
 @param isPrimitive A pointer to a Boolean value to set indicating if the specified property is of a primitive (non-object) type.
 @return A `Class` object specifying the type of the requested property.
 */
- (Class)classForPropertyNamed:(NSString *)propertyName ofClass:(Class)objectClass isPrimitive:(BOOL *)isPrimitive;

@end

///----------------------------
/// @name Convenience Functions
///----------------------------

/**
 Returns the class of the attribute or relationship property at the key path of the given object.
 
 Given a key path to a string property, this will return an `NSString`, etc.
 
 @param keyPath The key path to the property to retrieve the class of.
 @param object The object to evaluate.
 @return The class of the property at the given key path.
 */
Class RKPropertyInspectorGetClassForPropertyAtKeyPathOfObject(NSString *keyPath, id object);

/**
 Returns a Boolean value indicating if the property at the specified key path for a given object is modeled by a primitive type.
 
 @param keyPath The key path to inspect the property of.
 @param object The object to evaluate.
 @return `YES` if the property is a primitive, else `NO`.
 */
BOOL RKPropertyInspectorIsPropertyAtKeyPathOfObjectPrimitive(NSString *keyPath, id object);
