//
//  UIViewController+RKLoading.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/12/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "UIViewController+RKLoading.h"
#import <Three20/Three20.h>

static NSInteger const kOverlayViewTag = 66;
static NSInteger const kProgressViewTag = 67;

@implementation UIViewController (RKLoading)

- (void)requestDidStartLoad:(RKRequest*)request {
	UIView* overlayView = [self.view viewWithTag:kOverlayViewTag];
	if (overlayView == nil) {
		overlayView = [[TTActivityLabel alloc] initWithFrame:self.view.bounds style:TTActivityLabelStyleBlackBox text:@"Loading..."];
		overlayView.backgroundColor = [UIColor blackColor];
		overlayView.alpha = 0.5;
		overlayView.tag = kOverlayViewTag;

		[self.view addSubview:overlayView];
	}
}

- (void)request:(RKRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	UIProgressView* progressView = (UIProgressView*)[self.view viewWithTag:kProgressViewTag];
	if (progressView == nil) {
		if (totalBytesWritten >= totalBytesExpectedToWrite) {
			// Uploaded all data at once. don't need a progress bar.
			return;
		}
		progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 100, 300, 20)];
		progressView.tag = kProgressViewTag;
		[self.view addSubview:progressView];
	}
	
	progressView.progress = totalBytesWritten / (float)totalBytesExpectedToWrite;
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
	UIView* overlayView = [self.view viewWithTag:kOverlayViewTag];
	UIView* progressView = [self.view viewWithTag:kProgressViewTag];
	[overlayView removeFromSuperview];
	[overlayView release];
	[progressView removeFromSuperview];
	[progressView release];
}

@end
