//
//  UIExpection.h
//  UISpec
//
//  Created by Brian Knorr <btknorr@gmail.com>
//  Copyright(c) 2009 StarterStep, Inc., Some rights reserved.
//

#define expectThat(aValue) ({ \
/* The stack var is here, so this macro can accept constants directly. */ \
__typeof__(aValue) __aValue = (aValue); \
[UIExpectation withValue:&__aValue objCType:@encode(__typeof__(aValue)) file:__FILE__ line:__LINE__ isFailureTest:NO]; \
}) \

#define expectFailureWhen(aValue) ({ \
/* The stack var is here, so this macro can accept constants directly. */ \
__typeof__(aValue) __aValue = (aValue); \
[UIExpectation withValue:&__aValue objCType:@encode(__typeof__(aValue)) file:__FILE__ line:__LINE__ isFailureTest:YES]; \
}) \

#define be(aValue) ({ \
__typeof__(aValue) __aValue = (aValue); \
[UIMatcher withValue:&__aValue objCType:@encode(__typeof__(aValue)) matchSelector:@selector(be:)]; \
}) \


#import "UIMatcher.h"

@interface UIExpectation : NSObject {
	BOOL exist, isNot, isHave, isBe, isFailureTest;
	UIExpectation *not, *have, *be, *should, *shouldNot;
	id value;
	const char * typeDescription;
	const char * file;
	int line;
}

@property(nonatomic, readonly) UIExpectation *not, *have, *be, *should, *shouldNot;
@property(nonatomic, readonly) BOOL exist;

+(id)withValue:(const void *)aValue objCType:(const char *)aTypeDescription file:(const char *)aFile line:(int)aLine isFailureTest:(BOOL)failureTest;
+(SEL)makeIsSelector:(SEL)aSelector;

-(id)initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription file:(const char *)aFile line:(int)aLine isFailureTest:(BOOL)failureTest;
-(UIExpectation *)not;
-(UIExpectation *)should;
-(UIExpectation *)shouldNot;
-(UIExpectation *)have;
-(UIExpectation *)be;
-(void)should:(UIMatcher *)matcher;
-(void)shouldNot:(UIMatcher *)matcher;
-(void)not:(UIMatcher *)matcher;
-(void)be:(SEL)sel;
-(void)have:(NSInvocation *)invocation;
-(NSString *)valueAsString;
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
-(void)forwardInvocation:(NSInvocation *)anInvocation;

@end
