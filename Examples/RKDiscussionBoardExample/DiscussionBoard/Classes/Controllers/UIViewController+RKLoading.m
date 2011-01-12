//
//  UIViewController+RKLoading.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIViewController+RKLoading.h"


@implementation UIViewController (RKLoading)

- (void)requestDidStartLoad:(RKRequest*)request {
	UIView* overlayView = [self.view viewWithTag:66];
	UIView* progressView = [self.view viewWithTag:67];
	if (overlayView == nil && progressView == nil) {
		overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
		overlayView.backgroundColor = [UIColor blackColor];
		overlayView.alpha = 0.5;
		overlayView.tag = 66;
		progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 100, 300, 20)];
		progressView.tag = 67;
		
		[self.view addSubview:overlayView];
		[self.view addSubview:progressView];
	}
}

- (void)request:(RKRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	UIProgressView* progressView = (UIProgressView*)[self.view viewWithTag:67];
	progressView.progress = totalBytesWritten / (float)totalBytesExpectedToWrite;
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
	UIView* overlayView = [self.view viewWithTag:66];
	UIView* progressView = [self.view viewWithTag:67];
	[overlayView removeFromSuperview];
	[overlayView release];
	[progressView removeFromSuperview];
	[progressView release];
}

@end
