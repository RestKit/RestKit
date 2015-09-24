//
//  RKMIMETypeSerialization.h
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
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

#import <RestKit/Support/RKMIMETypes.h>
#import <RestKit/Support/RKSerialization.h>

/**
 The `RKMIMETypeSerialization` class provides support for the registration of classes conforming to the `RKSerialization` protocol by MIME Type and the serialization and deserialization of content by MIME Type. Serialization implementations may be registered by an exact string match (i.e. 'application/json' for a JSON serialization implementation) or by regular expression to match MIME Type by pattern.
 */
@interface RKMIMETypeSerialization : NSObject

///---------------------------------------
/// @name Managing MIME Type Registrations
///---------------------------------------

/**
 Registers the given serialization class to handle content for the given MIME Type identifier.
 
 MIME Types may be given as either a string or as a regular expression that matches the MIME Types for which the given serialization should handle. Serializations are searched in the reverse order of their registration. If a registration is made for an already registered MIME Type, the new registration will take precedence.
 
 @param serializationClass The class conforming to the RKSerialization protocol to be registered as handling the given MIME Type.
 @param MIMETypeStringOrRegularExpression A string or regular expression specifying the MIME Type(s) that given serialization implementation is to be registered as handling.
 */
+ (void)registerClass:(Class<RKSerialization>)serializationClass forMIMEType:(id)MIMETypeStringOrRegularExpression;

/**
 Unregisters the given serialization class from handling any MIME Types.
 
 After this method is invoked, invocations of `serializationForMIMEType:` will no longer return the unregistered serialization class.
 
 @param serializationClass The class conforming to the `RKSerialization` protocol to be unregistered.
 */
+ (void)unregisterClass:(Class<RKSerialization>)serializationClass;

/**
 Returns the serialization class registered to handle the given MIME Type.
 
 Searches the registrations in reverse order for the first serialization implementation registered to handle the given MIME Type. Matches are determined by doing a lowercase string comparison if the MIME Type was registered with a string identifier or by evaluating a regular expression match against the given MIME Type if registered with a regular expression.
 
 @param MIMEType The MIME Type for which to return the registered `RKSerialization` conformant class.
 @return A class conforming to the RKSerialization protocol registered for the given MIME Type or nil if none was found.
 */
+ (Class<RKSerialization>)serializationClassForMIMEType:(NSString *)MIMEType;

/**
 Returns a set containing the string values for all MIME Types for which a serialization implementation has been registered.
 
 @return An `NSSet` object whose elements are `NSString` values enumerating the registered MIME Types.
 */
+ (NSSet *)registeredMIMETypes;

///---------------------------------------------------------
/// @name Serializing and Deserializing Content by MIME Type
///---------------------------------------------------------

/**
 Deserializes and returns a Foundation object representation of the given UTF-8 encoded data in the serialization format for the given MIME Type.
 
 On invocation, searches the registrations by invoking `serializationClassForMIMEType:` with the given MIME Type and then invokes `objectFromData:error:` on the `RKSerialization` conformant class returned. If no serialization implementation is found to handle the given MIME Type, nil is returned and the given error pointer will be set to an NSError object with the `RKMissingSerializationForMIMETypeError` code.
 
 @param data The UTF-8 encoded data representation of the object to be deserialized.
 @param MIMEType The MIME Type of the serialization format the data is in.
 @param error A pointer to an NSError object.
 @return A Foundation object from the serialized data in data, or nil if an error occurs.
 */
+ (id)objectFromData:(NSData *)data MIMEType:(NSString *)MIMEType error:(NSError **)error;

/**
 Serializes and returns a UTF-8 encoded data representation of the given Foundation object in the serialization format for the given MIME Type.
 
 On invocation, searches the registrations by invoking `serializationClassForMIMEType:` with the given MIME Type and then invokes `objectFromData:error:` on the `RKSerialization` conformant class returned. If no serialization implementation is found to handle the given MIME Type, nil is returned and the given error pointer will be set to an NSError object with the `RKMissingSerializationForMIMETypeError` code.
 
 @param object The Foundation object to serialized.
 @param MIMEType The MIME Type of the serialization format the data is in.
 @param error A pointer to an NSError object.
 @return A Foundation object from the serialized data in data, or nil if an error occurs.
 */
+ (NSData *)dataFromObject:(id)object MIMEType:(NSString *)MIMEType error:(NSError **)error;

@end
