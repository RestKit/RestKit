//
//  RKParams.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRequestSerializable.h"
#import "RKParamsFileAttachment.h"
#import "RKParamsDataAttachment.h"

@interface RKParams : NSObject <RKRequestSerializable> {
	NSMutableDictionary* _valueData;
	NSMutableDictionary* _fileData;
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
- (void)setValue:(id <NSObject>)value forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to the data contained in a file at the given path
 */
- (RKParamsFileAttachment*)setFile:(NSString*)filePath forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to the data contained in a file at the given path with the specified MIME Type and attachment file name
 */
- (RKParamsFileAttachment*)setFile:(NSString*)filePath MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param;

/**
 * Sets the value to the data object for a named parameter
 */
- (RKParamsDataAttachment*)setData:(NSData*)data forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to a data object with the specified MIME Type and attachment file name
 */
- (RKParamsDataAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param;

/**
 * Returns the value for the Content-Type header for these params
 */
- (NSString*)ContentTypeHTTPHeader;

/**
 * Returns the data contained in this params object as a MIME string
 */
- (NSData*)HTTPBody;

@end
