//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCPartialMockRecorder.h"
#import "OCPartialMockObject.h"


@interface OCPartialMockObject (Private)
- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation;
@end


NSString *OCMRealMethodAliasPrefix = @"ocmock_replaced_";

@implementation OCPartialMockObject


#pragma mark  Mock table

static NSMutableDictionary *mockTable;

+ (void)initialize
{
	if(self == [OCPartialMockObject class])
		mockTable = [[NSMutableDictionary alloc] init];
}

+ (void)rememberPartialMock:(OCPartialMockObject *)mock forObject:(id)anObject
{
	[mockTable setObject:[NSValue valueWithNonretainedObject:mock] forKey:[NSValue valueWithNonretainedObject:anObject]];
}

+ (void)forgetPartialMockForObject:(id)anObject
{
	[mockTable removeObjectForKey:[NSValue valueWithNonretainedObject:anObject]];
}

+ (OCPartialMockObject *)existingPartialMockForObject:(id)anObject
{
	OCPartialMockObject *mock = [[mockTable objectForKey:[NSValue valueWithNonretainedObject:anObject]] nonretainedObjectValue];
	if(mock == nil)
		[NSException raise:NSInternalInconsistencyException format:@"No partial mock for object %p", anObject];
	return mock;
}



#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithObject:(NSObject *)anObject
{
	[super initWithClass:[anObject class]];
	realObject = [anObject retain];
	[[self class] rememberPartialMock:self forObject:anObject];
	[self setupSubclassForObject:realObject];
	return self;
}

- (void)dealloc
{
	if(realObject != nil)
		[self stop];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCPartialMockObject[%@]", NSStringFromClass(mockedClass)];
}

- (NSObject *)realObject
{
	return realObject;
}

- (void)stop
{
	object_setClass(realObject, [self mockedClass]);
	[realObject release];
	[[self class] forgetPartialMockForObject:realObject];
	realObject = nil;
}


#pragma mark  Subclass management

- (void)setupSubclassForObject:(id)anObject
{
	Class realClass = [anObject class];
	double timestamp = [NSDate timeIntervalSinceReferenceDate];
	const char *className = [[NSString stringWithFormat:@"%@-%p-%f", realClass, anObject, timestamp] cString];
	Class subclass = objc_allocateClassPair(realClass, className, 0);
	objc_registerClassPair(subclass);
	object_setClass(anObject, subclass);

	Method forwardInvocationMethod = class_getInstanceMethod([self class], @selector(forwardInvocationForRealObject:));
	IMP forwardInvocationImp = method_getImplementation(forwardInvocationMethod);
	const char *forwardInvocationTypes = method_getTypeEncoding(forwardInvocationMethod);
	class_addMethod(subclass, @selector(forwardInvocation:), forwardInvocationImp, forwardInvocationTypes);
}

- (void)setupForwarderForSelector:(SEL)selector
{
	Class subclass = [[self realObject] class];
	Method originalMethod = class_getInstanceMethod([subclass superclass], selector);
	IMP originalImp = method_getImplementation(originalMethod);

	IMP forwarderImp = [subclass instanceMethodForSelector:@selector(aMethodThatMustNotExist)];
	class_addMethod(subclass, method_getName(originalMethod), forwarderImp, method_getTypeEncoding(originalMethod));

	SEL aliasSelector = NSSelectorFromString([OCMRealMethodAliasPrefix stringByAppendingString:NSStringFromSelector(selector)]);
	class_addMethod(subclass, aliasSelector, originalImp, method_getTypeEncoding(originalMethod));
}

- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real object, not the mock
	OCPartialMockObject *mock = [OCPartialMockObject existingPartialMockForObject:self];
	if([mock handleInvocation:anInvocation] == NO)
		[NSException raise:NSInternalInconsistencyException format:@"Ended up in subclass forwarder for %@ with unstubbed method %@",
		 [self class], NSStringFromSelector([anInvocation selector])];
}



#pragma mark  Overrides

- (id)getNewRecorder
{
	return [[[OCPartialMockRecorder alloc] initWithSignatureResolver:self] autorelease];
}

- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:realObject];
}


@end
