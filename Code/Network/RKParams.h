//
//  RKParams.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
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
#import "RKRequestSerializable.h"
#import "RKParamsAttachment.h"

/**
 This helper class implements the RKRequestSerializable protocol to provide
 support for creating the multi-part request body for RKRequest objects.

 RKParams enables simple support for file uploading from NSData objects and
 files stored locally. RKParams will serialize these objects into a multi-part
 form representation that is suitable for submission to a remote web server for
 processing. After creating the RKParams object, use
 [RKClient post:params:delegate:] as the example below does.

 **Example**:

    RKParams *params = [RKParams params];
    NSData *imageData = UIImagePNGRepresentation([_imageView image]);
    [params setData:imageData MIMEType:@"image/png" forParam:@"image1"];

    UIImage *image = [UIImage imageNamed:@"RestKit.png"];
    imageData = UIImagePNGRepresentation(image);
    [params setData:imageData MIMEType:@"image/png" forParam:@"image2"];

    [_client post:@"/RKParamsExample" params:params delegate:self];

 It is also used internally by RKRequest for its OAuth1 implementation.

 */
@interface RKParams : NSInputStream <RKRequestSerializable> {
 @private
    NSMutableArray *_attachments;
    NSStreamStatus _streamStatus;
    NSData *_footer;
    NSUInteger _bytesDelivered;
    NSUInteger _length;
    NSUInteger _footerLength;
    NSUInteger _currentPart;
}


///-----------------------------------------------------------------------------
/// @name Creating an RKParams object
///-----------------------------------------------------------------------------

/**
 Creates and returns an RKParams object that is ready for population.

 @return An RKParams object to be populated.
 */
+ (RKParams *)params;

/**
 Creates and returns an RKParams object created from a dictionary of key/value
 pairs.

 @param dictionary NSDictionary of key/value pairs to add as RKParamsAttachment
 objects.
 @return An RKParams object with the key/value pairs of the dictionary.
 */
+ (RKParams *)paramsWithDictionary:(NSDictionary *)dictionary;

/**
 Initalize an RKParams object from a dictionary of key/value pairs

 @param dictionary NSDictionary of key/value pairs to add as RKParamsAttachment
 objects.
 @return An RKParams object with the key/value pairs of the dictionary.
 */
- (RKParams *)initWithDictionary:(NSDictionary *)dictionary;


///-----------------------------------------------------------------------------
/// @name Working with attachments
///-----------------------------------------------------------------------------

/**
 Array of all RKParamsAttachment attachments
 */
@property (nonatomic, readonly) NSMutableArray *attachments;

/**
 Creates a new RKParamsAttachment from the key/value pair passed in and adds it
 to the attachments array.

 @param value Value of the attachment to add
 @param param Key name of the attachment to add
 @return the new RKParamsAttachment that was added to the attachments array
 */
- (RKParamsAttachment *)setValue:(id <NSObject>)value forParam:(NSString *)param;

/**
 Creates a new RKParamsAttachment for a named parameter with the data contained
 in the file at the given path and adds it to the attachments array.

 @param filePath String of the path to the file to be attached
 @param param Key name of the attachment to add
 @return the new RKParamsAttachment that was added to the attachments array
 */
- (RKParamsAttachment *)setFile:(NSString *)filePath forParam:(NSString *)param;

/**
 Creates a new RKParamsAttachment for a named parameter with the data given and
 adds it to the attachments array.

 A default MIME type of application/octet-stream will be used.

 @param data NSData object of the data to be attached
 @param param Key name of the attachment to add
 @return the new RKParamsAttachment that was added to the attachments array
 */
- (RKParamsAttachment *)setData:(NSData *)data forParam:(NSString *)param;

/**
 Creates a new RKParamsAttachment for a named parameter with the data given and
 the MIME type specified and adds it to the attachments array.

 @param data NSData object of the data to be attached
 @param MIMEType String of the MIME type of the data
 @param param Key name of the attachment to add
 @return the new RKParamsAttachment that was added to the attachments array
 */
- (RKParamsAttachment *)setData:(NSData *)data MIMEType:(NSString *)MIMEType forParam:(NSString *)param;

/**
 Creates a new RKParamsAttachment and sets the value for a named parameter to a
 data object with the specified MIME Type and attachment file name.

 @bug **DEPRECATED**: Use [RKParams setData:MIMEType:forParam:] and set the
 fileName on the returned RKParamsAttachment instead.

 @param data NSData object of the data to be attached
 @param MIMEType String of the MIME type of the data
 @param fileName String of the attachment file name
 @param param Key name of the attachment to add
 @return the new RKParamsAttachment that was added to the attachments array
 */
- (RKParamsAttachment *)setData:(NSData *)data MIMEType:(NSString *)MIMEType fileName:(NSString *)fileName forParam:(NSString *)param DEPRECATED_ATTRIBUTE;

/**
 Creates a new RKParamsAttachment and sets the value for a named parameter to
 the data contained in a file at the given path with the specified MIME Type and
 attachment file name.

 @bug **DEPRECATED**: Use [RKParams setFile:forParam:] and set the MIMEType and
 fileName on the returned RKParamsAttachment instead.

 @param filePath String of the path to the file to be attached
 @param MIMEType String of the MIME type of the data
 @param fileName String of the attachment file name
 @param param Key name of the attachment to add
 @return the new RKParamsAttachment that was added to the attachments array
 */
- (RKParamsAttachment *)setFile:(NSString *)filePath MIMEType:(NSString *)MIMEType fileName:(NSString *)fileName forParam:(NSString *)param DEPRECATED_ATTRIBUTE;

/**
 Get the dictionary of params which are plain text as specified by
 [RFC 5849](http://tools.ietf.org/html/rfc5849#section-3.4.1.3).

 This is largely used for RKClient's OAuth1 implementation.

 The params in this dictionary include those where:

 - The entity-body is single-part.
 - The entity-body follows the encoding requirements of the
 "application/x-www-form-urlencoded" content-type as defined by
 [W3C.REC-html40-19980424].
 - The HTTP request entity-header includes the "Content-Type" header field set
 to "application/x-www-form-urlencoded".

 @return NSDictionary of key/values extracting from the RKParamsAttachment
 objects that meet the plain text criteria
 */
- (NSDictionary *)dictionaryOfPlainTextParams;


///-----------------------------------------------------------------------------
/// @name Resetting and checking states
///-----------------------------------------------------------------------------

/**
 Resets the state of the RKParams stream.
 */
- (void)reset;

/**
 Return a composite MD5 checksum value for all attachments.
 */
- (NSString *)MD5;

@end
