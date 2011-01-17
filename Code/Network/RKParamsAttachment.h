//
//  RKParamsAttachment.h
//  RestKit
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Models an individual part of a multi-part MIME document. These
 * attachments are stacked together within the RKParams document to
 * allow for uploading files via HTTP
 */
@interface RKParamsAttachment : NSObject {
	NSString* _name;
	NSString* _boundary;
	NSString* _fileName;
	NSString* _MIMEType;

	@private
	NSData*			_MIMEHeader;
	NSUInteger		_MIMEHeaderLength;
	NSInputStream*  _bodyStream;
	NSUInteger		_bodyLength;
	NSUInteger		_length;
	NSUInteger		_delivered;
}

/**
 * The parameter name of this attachment in the multi-part document
 */
@property (nonatomic, retain) NSString* name;

/**
 * The name of the attached file in the MIME stream
 * Defaults to the name of the file attached or nil if there is not one.
 */
@property (nonatomic, retain) NSString* fileName;

/**
 * The MIME type of the attached file in the MIME stream. MIME Type will be
 * auto-detected from the file extension of the attached file.
 *
 * Defaults to nil
 */
@property (nonatomic, retain) NSString* MIMEType;

/**
 * The MIME boundary string
 */
@property (nonatomic, readonly) NSString* MIMEBoundary;

/**
 * Initialize a new attachment with a given parameter name and a value
 */
- (id)initWithName:(NSString*)name value:(id<NSObject>)value;

/**
 * Initialize a new attachment with a given parameter name and the data stored in an NSData object
 */
- (id)initWithName:(NSString*)name data:(NSData*)data;

/**
 * Initialize a new attachment with a given parameter name and the data stored on disk at the given file path
 */
- (id)initWithName:(NSString*)name file:(NSString*)filePath;

/**
 * Open the attachment stream to begin reading. This will generate a MIME header and prepare the
 * attachment for writing to an RKParams stream
 */
- (void)open;

/**
 * The length of the entire attachment (including the MIME Header and the body)
 */
- (NSUInteger)length;

/**
 * Read the attachment body in a streaming fashion
 */
- (NSUInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;

@end
