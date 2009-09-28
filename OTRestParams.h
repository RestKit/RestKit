//
//  OTRestParams.h
//  OTRestFramework
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRestRequestSerializable.h"
#import "OTRestParamsFileAttachment.h"
#import "OTRestParamsDataAttachment.h"

@interface OTRestParams : NSObject <OTRestRequestSerializable> {
	NSMutableDictionary* _valueData;
	NSMutableDictionary* _fileData;
}

/**
 * Returns an empty params object ready for population
 */
+ (OTRestParams*)params;

/**
 * Initialize a params object from a dictionary of key/value pairs
 */
+ (OTRestParams*)paramsWithDictionary:(NSDictionary*)dictionary;

/**
 * Initalize a params object from a dictionary of key/value pairs
 */
- (OTRestParams*)initWithDictionary:(NSDictionary*)dictionary;

/**
 * Sets the value for a named parameter
 */
- (void)setValue:(id <NSObject>)value forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to the data contained in a file at the given path
 */
- (OTRestParamsFileAttachment*)setFile:(NSString*)filePath forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to the data contained in a file at the given path with the specified MIME Type and attachment file name
 */
- (OTRestParamsFileAttachment*)setFile:(NSString*)filePath MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param;

/**
 * Sets the value to the data object for a named parameter
 */
- (OTRestParamsDataAttachment*)setData:(NSData*)data forParam:(NSString*)param;

/**
 * Sets the value for a named parameter to a data object with the specified MIME Type and attachment file name
 */
- (OTRestParamsDataAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param;

/**
 * Returns the value for the Content-Type header for these params
 */
- (NSString*)ContentTypeHTTPHeader;

/**
 * Returns the data contained in this params object as a MIME string
 */
- (NSData*)HTTPBody;

@end
