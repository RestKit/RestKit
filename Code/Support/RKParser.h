//
//  RKParser.h
//  RestKit
//
//  Created by Blake Watters on 10/1/10.
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

/**
 The RKParser protocol declares two methods that a class must implement
 so that it can provide support for parsing and serializing objects
 to and from data representations and are configured via the
 RKParserRegistry shared instance.
 */
@protocol RKParser <NSObject>

/**
 Returns an object representation of the source data encoded in the
 format provided by the parser (i.e. JSON, XML, etc).

 @param data The data representation of the object to be parsed encoded in UTF-8.
 @param error A pointer to an NSError object.
 @return The parsed object or nil if an error occurred during parsing.
 */
- (id)objectFromData:(NSData *)data error:(NSError **)error;

/**
 Returns a data representation encoded in the format
 provided by the parser (i.e. JSON, XML, etc) for the given object.

 @param object The object to be serialized.
 @param A pointer to an NSError object.
 @return A data representation of the serialized object encoded in UTF-8 or nil if an error occurred.
 */
- (NSData *)dataFromObject:(id)object error:(NSError **)error;

@end
