//---------------------------------------------------------------------------------------
//  $Id: $
//  Copyright (c) 2007-2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMConstraint : NSObject 

+ (id)constraint;
- (BOOL)evaluate:(id)value;

// if you are looking for any, isNil, etc, they have moved to OCMArg

+ (id)constraintWithSelector:(SEL)aSelector onObject:(id)anObject;
+ (id)constraintWithSelector:(SEL)aSelector onObject:(id)anObject withValue:(id)aValue;

// try to use [OCMArg checkWith...] instead of constraintWithSelector in here

@end

@interface OCMAnyConstraint : OCMConstraint
@end

@interface OCMIsNilConstraint : OCMConstraint
@end

@interface OCMIsNotNilConstraint : OCMConstraint
@end

@interface OCMIsNotEqualConstraint : OCMConstraint
{
	@public
	id testValue;
}

@end

@interface OCMInvocationConstraint : OCMConstraint
{
	@public
	NSInvocation *invocation;
}

@end

#define CONSTRAINT(aSelector) [OCMConstraint constraintWithSelector:aSelector onObject:self]
#define CONSTRAINTV(aSelector, aValue) [OCMConstraint constraintWithSelector:aSelector onObject:self withValue:(aValue)]
