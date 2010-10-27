//
//  RKParamsAttachmentSpec.m
//  RestKit
//
//  Created by Blake Watters on 10/27/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKParamsAttachment.h"

@interface RKParamsAttachmentSpec : NSObject <UISpec> {
}

@end


@implementation RKParamsAttachmentSpec

- (void)itShouldRaiseAnExceptionWhenTheAttachedFileDoesNotExist {
	NSException* exception = nil;
	@try {
		[[RKParamsAttachment alloc] initWithName:@"woot" file:@"/this/is/an/invalid/path"];
	}
	@catch (NSException* e) {
		exception = e;
	}
	[expectThat(exception) shouldNot:be(nil)];
}

@end
