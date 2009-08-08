//
//  OTRestParamsDataAttachment.m
//  gateguru
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestParamsDataAttachment.h"

@implementation OTRestParamsDataAttachment

@synthesize data = _data;

- (void)dealloc {
	[_data release];
	[super dealloc];
}

- (void)writeAttachmentToHTTPBody:(NSMutableData*)HTTPBody {
	if ([_data length] == 0) {
		return;
	}	
	[HTTPBody appendData:_data];
}

@end
