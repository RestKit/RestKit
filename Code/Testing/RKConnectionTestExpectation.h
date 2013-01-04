//
//  RKConnectionTestExpectation.h
//  RestKit
//
//  Created by Blake Watters on 12/8/12.
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

#ifdef _COREDATADEFINES_H

#import <Foundation/Foundation.h>

/**
 An `RKConnectionTestExpectation` object defines an expectation that a Core Data relationship is connected during the execution of a `RKMappingTest`. These expectation are used to unit test a connection specified via an `RKConnectionDescription` object.
 
 @see `RKMappingTest`
 @see `RKConnectionDescription`
 */
@interface RKConnectionTestExpectation : NSObject

///----------------------------
/// @name Creating Expectations
///----------------------------

/**
 Creates and returns a connection expectation for the specified relationship name, attributes dictionary, and value.
 
 @param relationshipName The name of the relationship expected to be connected.
 @param attributes A dictionary specifying the attributes that are expected to be used to establish the connection.
 @param value The value that is expected to be set for the relationship when the connection is established.
 @return A newly constructed connection expectation, initialized with the given relationship name, attributes dictionary, and expected value.
 */
+ (instancetype)expectationWithRelationshipName:(NSString *)relationshipName attributes:(NSDictionary *)attributes value:(id)value;

/**
 Initializes the receiver with the given relationship name, attributes dictionary, and value.
 
 @param relationshipName The name of the relationship expected to be connected.
 @param attributes A dictionary specifying the attributes that are expected to be used to establish the connection.
 @param value The value that is expected to be set for the relationship when the connection is established.
 @return The receiver, initialized with the given relationship name, attributes dictionary, and expected value.
 */
- (id)initWithRelationshipName:(NSString *)relationshipName attributes:(NSDictionary *)attributes value:(id)value;

///------------------------------------
/// @name Accessing Expectation Details
///------------------------------------

/**
 The name of the relationship that is expected to be connected. Cannot be `nil`.
 */
@property (nonatomic, copy, readonly) NSString *relationshipName;

/**
 The dictionary of attributes that are expected to be used when the connection is established. May be `nil`.
 */
@property (nonatomic, copy, readonly) NSDictionary *attributes;

/**
 The value that is expected to be set for the relationship when connected. May be `nil`.
 
 A value of `nil` indicates that expectation does not specify an exact value for the connection, only that it was set during the execution of the test. A value of `[NSNull null]` indicates that the connection is expected to be connected to a nil value.
 */
@property (nonatomic, strong, readonly) id value;

/**
 Returns a string summary of the connection that is expected to be established.
 
 @return A string describing the expected connection.
 */
- (NSString *)summary;

@end

#endif
