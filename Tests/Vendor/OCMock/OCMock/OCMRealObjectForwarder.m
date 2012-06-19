//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2010 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCPartialMockObject.h"
#import "OCMRealObjectForwarder.h"


@implementation OCMRealObjectForwarder

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	id invocationTarget = [anInvocation target];
	SEL invocationSelector = [anInvocation selector];
	SEL aliasedSelector = NSSelectorFromString([OCMRealMethodAliasPrefix stringByAppendingString:NSStringFromSelector(invocationSelector)]);

	[anInvocation setSelector:aliasedSelector];
	if([invocationTarget isProxy] && (class_getInstanceMethod([invocationTarget class], @selector(realObject))))
	{
		// the method has been invoked on the mock, we need to change the target to the real object
		[anInvocation setTarget:[(OCPartialMockObject *)invocationTarget realObject]];
	}
	[anInvocation invoke];
}


@end
