//
//  RKParams.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
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
+ (id)params;

/**
 * Initialize a params object from a dictionary of key/value pairs
 */
+ (id)paramsWithDictionary:(NSDictionary*)dictionary;

/**
 * Initalize a params object from a dictionary of key/value pairs
 */
- (id)initWithDictionary:(NSDictionary*)dictionary;

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

@end
