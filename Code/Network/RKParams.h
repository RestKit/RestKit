//
//  RKParams.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters
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
#import "RKRequestSerializable.h"
#import "RKParamsAttachment.h"

/**
 * Provides support for creating multi-part request body for RKRequest
 * objects.
 */
@interface RKParams : NSInputStream <RKRequestSerializable> {
	NSMutableArray* _attachments;
	
	@private
	NSStreamStatus _streamStatus;
	NSData* _footer;
	NSUInteger _bytesDelivered;
	NSUInteger _length;
	NSUInteger _footerLength;
	NSUInteger _currentPart;
}

/**
 * Returns an empty params object ready for population
 */
+ (RKParams*)params;

/**
 * Initialize a params object from a dictionary of key/value pairs
 */
+ (RKParams*)paramsWithDictionary:(NSDictionary*)dictionary;

/**
 * Initalize a params object from a dictionary of key/value pairs
 */
- (RKParams*)initWithDictionary:(NSDictionary*)dictionary;

/**
 * Sets the value for a named parameter
 */
- (RKParamsAttachment*)setValue:(id <NSObject>)value forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to the data contained in a file at the given path
 */
- (RKParamsAttachment*)setFile:(NSString*)filePath forParam:(NSString*)param;

/**
 * Sets the value to the data object for a named parameter. A default MIME type of
 * application/octet-stream will be used.
 */
- (RKParamsAttachment*)setData:(NSData*)data forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to an NSData object with a specific MIME type
 */
- (RKParamsAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to a data object with the specified MIME Type and attachment file name
 *
 * @deprecated Set the MIMEType and fileName on the returned RKParamsAttachment instead
 */
- (RKParamsAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param DEPRECATED_ATTRIBUTE;

/**
 * Sets the value for a named parameter to the data contained in a file at the given path with the specified MIME Type and attachment file name
 *
 *  @deprecated Set the MIMEType and fileName on the returned RKParamsAttachment instead
 */
- (RKParamsAttachment*)setFile:(NSString*)filePath MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param DEPRECATED_ATTRIBUTE;

/**
 * Resets the state of the RKParams stream
 */
- (void)reset;

@end
