//
//  OTRestAttachment.m
//  gateguru
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestParamsAttachment.h"

@implementation OTRestParamsAttachment

@synthesize fileName = _fileName, MIMEType = _MIMEType;

+ (id)attachment {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (self = [super init]) {
		self.fileName = @"file";
		self.MIMEType = @"application/octet-stream";
	}
	
	return self;
}

- (void)dealloc {
	[_fileName release];
	[_MIMEType release];
	[super dealloc];
}

- (void)writeAttachmentToHTTPBody:(NSMutableData*)HTTPBody {
	[self doesNotRecognizeSelector:_cmd];
}

@end
