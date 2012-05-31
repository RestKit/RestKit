//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCClassMockObject.h"

@interface OCPartialMockObject : OCClassMockObject
{
	NSObject	*realObject;
}

- (id)initWithObject:(NSObject *)anObject;

- (NSObject *)realObject;

- (void)stop;

- (void)setupSubclassForObject:(id)anObject;
- (void)setupForwarderForSelector:(SEL)selector;

@end


extern NSString *OCMRealMethodAliasPrefix;
