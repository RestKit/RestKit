//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2012 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCClassMockRecorder.h"
#import "OCMockClassObject.h"


@implementation OCMockClassObject

#pragma mark  Mock table

static NSMutableDictionary *mockTable;

+ (void)initialize
{
	if(self == [OCMockClassObject class])
		mockTable = [[NSMutableDictionary alloc] init];
}

+ (void)rememberMock:(OCMockClassObject *)mock forClass:(Class)aClass
{
	[mockTable setObject:[NSValue valueWithNonretainedObject:mock] forKey:[NSValue valueWithNonretainedObject:aClass]];
}

+ (void)forgetMockForClass:(Class)aClass
{
	[mockTable removeObjectForKey:[NSValue valueWithNonretainedObject:aClass]];
}

+ (OCMockClassObject *)existingMockForClass:(Class)aClass
{
	OCMockClassObject *mock = [[mockTable objectForKey:[NSValue valueWithNonretainedObject:aClass]] nonretainedObjectValue];
	if(mock == nil)
		[NSException raise:NSInternalInconsistencyException format:@"No mock for class %p", aClass];
	return mock;
}


#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithClass:(Class)aClass
{
	[super init];
	mockedClass = aClass;
	[[self class] rememberMock:self forClass:aClass];
    [self setupClass:aClass];
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCMockClassObject[%@]", NSStringFromClass(mockedClass)];
}

- (Class)mockedClass
{
	return mockedClass;
}

- (void)stopMocking
{
    
}

- (void)setupClass:(Class)aClass
{
	Method myForwardInvocationMethod = class_getInstanceMethod([self class], @selector(forwardInvocationForRealObject:));
	IMP myForwardInvocationImp = method_getImplementation(myForwardInvocationMethod);
	const char *forwardInvocationTypes = method_getTypeEncoding(myForwardInvocationMethod);
    Class metaClass = objc_getMetaClass(class_getName(aClass));
	class_replaceMethod(metaClass, @selector(forwardInvocation:), myForwardInvocationImp, forwardInvocationTypes);
}
    
- (void)setupForwarderForSelector:(SEL)selector
{
	Method originalMethod = class_getClassMethod(mockedClass, selector);
    Class metaClass = objc_getMetaClass(class_getName(mockedClass));
    
	IMP forwarderImp = [metaClass instanceMethodForSelector:@selector(aMethodThatMustNotExist)];
	class_replaceMethod(metaClass, method_getName(originalMethod), forwarderImp, method_getTypeEncoding(originalMethod)); 
    
//	SEL aliasSelector = NSSelectorFromString([OCMRealMethodAliasPrefix stringByAppendingString:NSStringFromSelector(selector)]);
//	class_addMethod(subclass, aliasSelector, originalImp, method_getTypeEncoding(originalMethod));
}

- (void)forwardInvocationForRealObject:(NSInvocation *)anInvocation
{
	// in here "self" is a reference to the real class, not the mock
	OCMockClassObject *mock = [OCMockClassObject existingMockForClass:(Class)self];
	if([mock handleInvocation:anInvocation] == NO)
		[NSException raise:NSInternalInconsistencyException format:@"Ended up in subclass forwarder for %@ with unstubbed method %@",
		 [self class], NSStringFromSelector([anInvocation selector])];
}


#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [mockedClass methodSignatureForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [mockedClass respondsToSelector:selector];
}


#pragma mark  Overrides

- (id)getNewRecorder
{
	return [[[OCClassMockRecorder alloc] initWithSignatureResolver:self] autorelease];
}


@end
