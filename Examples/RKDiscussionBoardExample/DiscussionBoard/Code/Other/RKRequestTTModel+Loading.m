//
//  RKRequestTTModel+Loading.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/12/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKRequestTTModel+Loading.h"


@implementation RKRequestTTModel (Loading)

- (void)requestDidStartLoad:(RKRequest*)request {
	NSLog(@"Request Start Load");
}

- (void)request:(RKRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	NSLog(@"Request Did Send Body Data");
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
	NSLog(@"Request Did Load Response");
}

@end
