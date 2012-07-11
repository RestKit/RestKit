//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2012 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockClassObject.h"
#import "OCClassMockRecorder.h"


@implementation OCClassMockRecorder
/*
- (id)andForwardToRealObject
{
	[invocationHandlers addObject:[[[OCMRealObjectForwarder	alloc] init] autorelease]];
	return self;
}
*/

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[super forwardInvocation:anInvocation];
	// not as clean as I'd wish...
	[(OCMockClassObject *)signatureResolver setupForwarderForSelector:[anInvocation selector]];
}

@end
