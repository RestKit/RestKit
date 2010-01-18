//
//  OTRestParamsFileAttachment.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "OTRestParamsFileAttachment.h"

@implementation OTRestParamsFileAttachment

@synthesize filePath = _filePath;

- (void)dealloc {
	[_filePath release];
	[super dealloc];
}

- (void)writeAttachmentToHTTPBody:(NSMutableData*)HTTPBody {
	NSInputStream *stream = [[[NSInputStream alloc] initWithFileAtPath:_filePath] autorelease];
	[stream open];
	int bytesRead;
	while ([stream hasBytesAvailable]) {		
		unsigned char buffer[1024*256];
		bytesRead = [stream read:buffer maxLength:sizeof(buffer)];
		if (bytesRead == 0) {
			break;
		}
		[HTTPBody appendData:[NSData dataWithBytes:buffer length:bytesRead]];
	}
	[stream close];
}

@end
