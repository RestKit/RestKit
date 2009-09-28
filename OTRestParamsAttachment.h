//
//  OTRestParamsAttachment.h
//  OTRestFramework
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRestParamsAttachment : NSObject {
	NSString* _fileName;
	NSString* _MIMEType;
}

/**
 * The name of the attached file in the MIME stream
 * Defaults to 'file' if not specified
 */
@property (nonatomic, retain) NSString* fileName;

/**
 * The MIME type of the attached file in the MIME stream
 * Defaults to 'application/octet-stream' if not specified
 */
@property (nonatomic, retain) NSString* MIMEType;

/**
 * Returns an autoreleased attachment object
 */
+ (id)attachment;

/**
 * Abstract method implementing writing this attachment into an HTTP stream
 */
- (void)writeAttachmentToHTTPBody:(NSMutableData*)HTTPBody;

@end
