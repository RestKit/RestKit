//
//  RKTestFixture.h
//  RestKit
//
//  Created by Blake Watters on 2/1/12.
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
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

/**
 Provides a static method API for conveniently accessing fixture data contained within a designated `NSBundle`. Useful when writing unit tests that leverage fixture data for testing parsing and object mapping operations.
 */
@interface RKTestFixture : NSObject

/**
 Returns the NSBundle object designated as the source location for unit testing fixture data.

 @return The NSBundle object designated as the source location for unit testing fixture data
    or nil if none has been configured.
 */
+ (NSBundle *)fixtureBundle;

/**
 Designates the specified NSBundle object as the source location for unit testing fixture data.

 @param bundle The new fixture NSBundle object.
 */
+ (void)setFixtureBundle:(NSBundle *)bundle;

/**
 Returns the full path to the specified fixture file on within the fixture bundle.

 @param fixtureName The name of the fixture file.
 @return The full path to the specified fixture file or nil if it cannot be located.
 */
+ (NSString *)pathForFixture:(NSString *)fixtureName;

/**
 Creates and returns a string object by reading data from the fixture identified by the specified file name using UTF-8 encoding.

 @param fixtureName The name of the fixture file.
 @return A string created by reading data from the specified fixture file using the NSUTF8StringEncoding.
 */
+ (NSString *)stringWithContentsOfFixture:(NSString *)fixtureName;

/**
 Creates and returns a data object by reading every byte from the fixture identified by the specified file name.

 @param fixtureName The name of the resource file.
 @return A data object by reading every byte from the fixture file.
 */
+ (NSData *)dataWithContentsOfFixture:(NSString *)fixtureName;

/**
 Returns the MIME Type for the fixture identified by the specified name.

 @param fixtureName The name of the fixture file.
 @return The MIME Type for the resource file or nil if the file could not be located.
 */
+ (NSString *)MIMETypeForFixture:(NSString *)fixtureName;

/**
 Creates and returns an object representation of the data from the fixture identified by the specified file name by reading the data as a string and parsing it using a parser appropriate for the MIME Type of the file.

 @param fixtureName The name of the resource file.
 @return A new image object for the specified file, or nil if the method could not initialize the image from the specified file.
 @see `RKMIMETypeSerialization`
 */
+ (id)parsedObjectWithContentsOfFixture:(NSString *)fixtureName;

@end
