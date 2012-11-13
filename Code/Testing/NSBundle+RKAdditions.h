//
//  NSBundle+RKAdditions.h
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

/**
 Provides convenience methods for accessing data in resources within an `NSBundle`.
 */
@interface NSBundle (RKAdditions)

/**
 Returns the MIME Type for the resource identified by the specified name and file extension.

 @param name The name of the resource file.
 @param extension If extension is an empty string or nil, the extension is assumed not to exist and the file is the first file encountered that exactly matches name.
 @return The MIME Type for the resource file or nil if the file could not be located.
 */
- (NSString *)MIMETypeForResource:(NSString *)name withExtension:(NSString *)extension;

/**
 Creates and returns a data object by reading every byte from the resource identified by the specified name and file extension.

 @param name The name of the resource file.
 @param extension If extension is an empty string or nil, the extension is assumed not to exist and the file is the first file encountered that exactly matches name.
 @return A data object by reading every byte from the resource file.
 */
- (NSData *)dataWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension;

/**
 Creates and returns a string object by reading data from the resource identified by the specified name and file extension using a given encoding.

 @param name The name of the resource file.
 @param extension If extension is an empty string or nil, the extension is assumed not to exist and the file is the first file encountered that exactly matches name.
 @param encoding The encoding of the resource file.
 @return A string created by reading data from the resource file using the encoding.
 */
- (NSString *)stringWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension encoding:(NSStringEncoding)encoding;

/**
 Creates and returns an object representation of the data from the resource identified by the specified name and file extension by reading the
 data as a string and parsing it using a parser appropriate for the MIME Type of the file.

 @param name The name of the resource file.
 @param extension If extension is an empty string or nil, the extension is assumed not to exist and the file is the first file encountered that exactly matches name.
 @return A new image object for the specified file, or nil if the method could not initialize the image from the specified file.
 @see RKMIMETypeSerialization
 */
- (id)parsedObjectWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension;

@end
