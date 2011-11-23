//
//  RKObjectSerializer.h
//  RestKit
//
//  Created by Blake Watters on 5/2/11.
//  Copyright 2011 Two Toasters
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

#import "RKObjectMapping.h"
#import "RKObjectMappingOperation.h"
#import "RKRequestSerializable.h"

/**
 Performs a serialization of an object and its relationships back into
 a dictionary representation according to the mappings specified. The
 transformed object is then enclosed in an RKRequestSerializable representation
 that is suitable for inclusion in an RKRequest.
 */
@interface RKObjectSerializer : NSObject <RKObjectMappingOperationDelegate> {
    id _object;
    RKObjectMapping* _mapping;
}

@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) RKObjectMapping* mapping;

+ (id)serializerWithObject:(id)object mapping:(RKObjectMapping*)mapping;
- (id)initWithObject:(id)object mapping:(RKObjectMapping*)mapping;

/**
 Return a serialized representation of the source object by applying an object mapping
 with a target object type of NSMutableDictionary. The serialized object will contain attributes
 and relationships composed of simple KVC compliant Cocoa types.
 */
- (NSMutableDictionary*)serializedObject:(NSError**)error;

/**
 Return a serialized representation of the source object by mapping it into a NSMutableDictionary and
 then encoding it into the destination MIME Type via an instance of RKParser that is registered
 for the specified MIME Type
 */
- (NSString*)serializedObjectForMIMEType:(NSString*)MIMEType error:(NSError**)error;

/**
 Return a request serialization for the source object by mapping it to an NSMutableDictionary, encoding
 the data via a parser into the specified MIME Type, and wrapping it into a serializable format that can
 be used as the params of an RKRequest or RKObjectLoader
 */
- (id<RKRequestSerializable>)serializationForMIMEType:(NSString*)mimeType error:(NSError**)error;

@end
