//
//  RKObjectLoaderTTModel+Loading.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/12/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectLoaderTTModel+Loading.h"

@implementation RKObjectLoaderTTModel (Loading)

- (void)requestDidStartLoad:(RKRequest*)request {
	RKLogDebug(@"Request Start Load");
}

- (void)request:(RKRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	RKLogDebug(@"Request Did Send Body Data");
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
	RKLogDebug(@"Request Did Load Response");
}

@end
