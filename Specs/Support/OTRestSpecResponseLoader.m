//
//  OTRestSpecResponseLoader.m
//  OTRestFramework
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Objective 3. All rights reserved.
//

#import "OTRestSpecResponseLoader.h"


@implementation OTRestSpecResponseLoader

@synthesize response = _response;

- (void)dealloc {
	[_response release];
	[super dealloc];
}

- (void)waitForResponse {
	_awaitingResponse = YES;
	while (_awaitingResponse == YES) {
		[[NSRunLoop currentRunLoop] runUntilDate:
		 [NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
}

- (void)loadResponse:(id)response {
	NSLog(@"The response: %@", response);
	_response = [response retain];
	_awaitingResponse = NO;
}

@end
