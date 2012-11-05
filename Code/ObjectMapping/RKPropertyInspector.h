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
- (Class)typeForProperty:(NSString *)propertyName ofClass:(Class)objectClass;

///------------------------------------------------------
/// @name Retrieving the Properties and Types for a Class
///------------------------------------------------------

/**
 Returns the name of a property when provided the name of a property obtained via the `property_getAttributes` reflection API.

 @param attributeString A string object encoding attribute information.
 @return The class name for the property type encoded in the given attribute string or `@"NULL"` if the property does not have an object type (the declared property is for a primitive type).
 */
+ (NSString *)propertyTypeFromAttributeString:(NSString *)attributeString;

/**
 Returns an appropriate class to use for KVC access based on the Objective C runtime type encoding.
 
 Objective C Runtime type encodings: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 KVC Scalar/Structure support: http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/KeyValueCoding/Articles/DataTypes.html#//apple_ref/doc/uid/20002171-BAJEAIEE
 
 @param type An Objective C Runtime type encoding
 @return The class name for the property type encoded in the given attribute string, an appropriate class for wrapping/unwrapping the primitive type, or `Nil` when no transformation is required or possible.
 */
+ (Class)kvcClassForObjCType:(const char *)type;

/**
 Returns an appropriate class to use for KVC access based on the output obtained via the `property_getAttributes` reflection API.
 
 @param attributeString A c string containing encoding attribute information.
 @return The class name for the property type encoded in the given attribute string, an appropriate class for wrapping/unwrapping the primitive type, or `Nil` when no transformation is required or possible.
 */
+ (Class)kvcClassFromPropertyAttributes:(const char *)attr;

@end
