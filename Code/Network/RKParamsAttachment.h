//
//  RKParamsAttachment.h
//  RestKit
//
//  Created by Blake Watters on 8/6/09.
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
 Models an individual part of a multi-part MIME document. These attachments are
 stacked together within the RKParams document to allow for uploading files via
 HTTP.

 Typically, interactions with the RKParamsAttachment are accomplished through
 the RKParams class and there shouldn't be much need to deal directly with this
 class.
 */
@interface RKParamsAttachment : NSObject {
    @private
    NSData *_body;
    NSInputStream *_bodyStream;
    NSData *_MIMEHeader;
    NSUInteger _MIMEHeaderLength;
    NSUInteger _bodyLength;
    NSUInteger _length;
    NSUInteger _delivered;
}


///-----------------------------------------------------------------------------
/// @name Creating an Attachment
///-----------------------------------------------------------------------------

/**
 Returns a newly initialized attachment with a given parameter name and value.

 @param name The parameter name of this attachment in the multi-part document.
 @param value A value that is used to create the attachment body
 @return An initialized attachment with the given name and value.
 */
- (id)initWithName:(NSString *)name value:(id<NSObject>)value;

/**
 Returns a newly initialized attachment with a given parameter name and the data
 stored in an NSData object.

 @param name The parameter name of this attachment in the multi-part document.
 @param data The data that is used to create the attachment body.
 @return An initialized attachment with the given name and data.
 */
- (id)initWithName:(NSString *)name data:(NSData *)data;

/**
 Returns a newly initialized attachment with a given parameter name and the data
 stored on disk at the given file path.

 @param name The parameter name of this attachment in the multi-part document.
 @param filePath The complete path of a file to use its data contents as the
 attachment body.
 @return An initialized attachment with the name and the contents of the file at
 the path given.
 */
- (id)initWithName:(NSString *)name file:(NSString *)filePath;


///-----------------------------------------------------------------------------
/// @name Working with the Attachment
///-----------------------------------------------------------------------------

/**
 The parameter name of this attachment in the multi-part document.
 */
@property (nonatomic, retain) NSString *name;

/**
 The MIME type of the attached file in the MIME stream. MIME Type will be
 auto-detected from the file extension of the attached file.

 **Default**: nil
 */
@property (nonatomic, retain) NSString *MIMEType;

/**
 The MIME boundary string
 */
@property (nonatomic, readonly) NSString *MIMEBoundary;

/**
 The complete path to the attached file on disk.
 */
@property (nonatomic, readonly) NSString *filePath;

/**
 The name of the attached file in the MIME stream

 **Default**: The name of the file attached or nil if there is not one.
 */
@property (nonatomic, retain) NSString *fileName;

/**
 The value that is set when initialized through initWithName:value:
 */
@property (nonatomic, retain) id<NSObject> value;

/**
 Open the attachment stream to begin reading. This will generate a MIME header
 and prepare the attachment for writing to an RKParams stream.
 */
- (void)open;

/**
 The length of the entire attachment including the MIME header and the body.

 @return Unsigned integer of the MIME header and the body.
 */
- (NSUInteger)length;

/**
 Calculate and return an MD5 checksum for the body of this attachment.

 This works for simple values, NSData structures in memory, or by efficiently
 streaming a file and calculating an MD5.
 */
- (NSString *)MD5;


///-----------------------------------------------------------------------------
/// @name Input streaming
///-----------------------------------------------------------------------------

/**
 Read the attachment body in a streaming fashion for NSInputStream.

 @param buffer A data buffer. The buffer must be large enough to contain the
 number of bytes specified by len.
 @param len The maximum number of bytes to read.
 @return A number indicating the outcome of the operation:

 - A positive number indicates the number of bytes read;
 - 0 indicates that the end of the buffer was reached;
 - A negative number means that the operation failed.
 */
- (NSUInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;

@end
