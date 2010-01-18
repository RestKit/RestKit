//---------------------------------------------------------------------------------------
//  $Id: OCMockRecorder.h 50 2009-07-16 06:48:19Z erik $
//  Copyright (c) 2004-2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockRecorder : NSProxy 
{
	id				signatureResolver;
	NSInvocation	*recordedInvocation;
	NSMutableArray	*invocationHandlers;
}

- (id)initWithSignatureResolver:(id)anObject;

- (BOOL)matchesInvocation:(NSInvocation *)anInvocation;
- (void)releaseInvocation;

- (id)andReturn:(id)anObject;
- (id)andReturnValue:(NSValue *)aValue;
- (id)andThrow:(NSException *)anException;
- (id)andPost:(NSNotification *)aNotification;
- (id)andCall:(SEL)selector onObject:(id)anObject;

- (NSArray *)invocationHandlers;

@end
