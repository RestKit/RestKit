//
//  RKRequestSerialization.h
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

#import "RKRequestSerializable.h"

/**
 A simple implementation of the RKRequestSerializable protocol suitable for
 wrapping a MIME Type string and HTTP Body into a format that can be sent as the
 params of an RKRequest.

 @see RKRequestSerializable
 */
@interface RKRequestSerialization : NSObject <RKRequestSerializable>


///-----------------------------------------------------------------------------
/// @name Creating a Serialization
///-----------------------------------------------------------------------------

/**
 Creates and returns a new serialization enclosing an NSData object with the
 specified MIME type.

 @param data An NSData object to initialize the serialization with.
 @param MIMEType A string of the MIME type of the provided data.
 @return An autoreleased RKRequestSerialization object with the data and MIME
 type set.
 */
+ (id)serializationWithData:(NSData *)data MIMEType:(NSString *)MIMEType;

/**
 Returns a new serialization enclosing an NSData object with the specified MIME
 type.

 @param data An NSData object to initialize the serialization with.
 @param MIMEType A string of the MIME type of the provided data.
 @return An RKRequestSerialization object with the data and MIME type set.
 */
- (id)initWithData:(NSData *)data MIMEType:(NSString *)MIMEType;


///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 Returns the data enclosed in this serialization.
 */
@property (nonatomic, readonly) NSData *data;

/**
 Returns the MIME type of the data in this serialization.
 */
@property (nonatomic, readonly) NSString *MIMEType;

@end
