
#import "UIExpectation.h"
// #import "UIRedoer.h"
// #import "UIQueryExpectation.h"
#import "NSNumberCreator.h"

@implementation UIExpectation

+(id)withValue:(const void *)aValue objCType:(const char *)aTypeDescription file:(const char *)aFile line:(int)aLine isFailureTest:(BOOL)failureTest{
    // if (*aTypeDescription == '@' && ([*(id *)aValue isKindOfClass:[UIQuery class]] || [*(id *)aValue isKindOfClass:[UIRedoer class]])) {
    //  return [[[UIQueryExpectation alloc] initWithValue:aValue objCType:aTypeDescription file:aFile line:aLine isFailureTest:failureTest] autorelease];
    // }
	return [[[self alloc] initWithValue:aValue objCType:aTypeDescription file:aFile line:aLine isFailureTest:failureTest] autorelease];
}

-(id)initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription file:(const char *)aFile line:(int)aLine isFailureTest:(BOOL)failureTest{
	if (self = [super init]) {
		//NSLog(@" UIExpectation initWithValue %s, %s, %d", aTypeDescription, aFile, aLine);
		typeDescription = aTypeDescription;
		value = [[NSNumberCreator numberWithValue:aValue objCType:aTypeDescription] retain];
		file = aFile;
		line = aLine;
		isFailureTest = failureTest;
	}
	return self;
}

-(UIExpectation *)not {
	isNot = YES;
	return self;
}

-(UIExpectation *)should {
	return self;
}

-(UIExpectation *)shouldNot {
	return [self not];
}

-(UIExpectation *)have {
	isHave = YES;
	isBe = NO;
	return self;
}

-(UIExpectation *)be {
	isBe = YES;
	isHave = NO;
	return self;
}

-(void)should:(UIMatcher *)matcher {
	if (![matcher matches:value]) {
		if (!isFailureTest) {
			[NSException raise:nil format:@"%@\n%s:%d", matcher.errorMessage, file, line];
		}
	} else if (isFailureTest) {
		[NSException raise:nil format:@"%@\n%s:%d", @"expected: Failure, got: Success", file, line];\
	}
}

-(void)shouldNot:(UIMatcher *)matcher {
	if ([matcher matches:value]) {
		if (!isFailureTest) {
			[NSException raise:nil format:@"not %@\n%s:%d", matcher.errorMessage, file, line];
		}
	} else if (isFailureTest) {
		[NSException raise:nil format:@"%@\n%s:%d", @"expected: Failure, got: Success", file, line];\
	}
}

-(void)not:(UIMatcher *)matcher {
	[self shouldNot:matcher];
}

-(void)be:(SEL)sel {
	NSString *origSelector = NSStringFromSelector(sel);
	if (![value respondsToSelector:sel] && [value respondsToSelector:[UIExpectation makeIsSelector:sel]]) {
		sel = [UIExpectation makeIsSelector:sel];
	}
	BOOL result = [value performSelector:sel];
	if ((result == YES && isNot) || (result == NO && !isNot)) {
		if (!isFailureTest) {
			[NSException raise:nil format:@"%@ did not pass condition: [%@ be %@]\n%s:%d", [self valueAsString], (isNot ? @"should not" : @"should"), origSelector, file, line];
		}
	} else if (isFailureTest) {
		[NSException raise:nil format:@"%@\n%s:%d", @"expected: Failure, got: Success", file, line];\
	}
}

-(void)have:(NSInvocation *)invocation {
	NSMutableString *selector = [NSMutableString stringWithString:NSStringFromSelector([invocation selector])];
	NSArray *selectors = [selector componentsSeparatedByString:@":"];
	BOOL foundErrors = NO;
	NSMutableArray *errors = [NSMutableArray array];
	int i = 2;
	const void * expected = nil;
	for (NSString *key in selectors) {
		if (![key isEqualToString:@""]) {
			SEL selector = NSSelectorFromString(key);
			if (![value respondsToSelector:selector]) {
				[errors addObject:[NSString stringWithFormat:@"%@ doesn't respond to %@", [self valueAsString], key]];
				foundErrors = YES;
				continue;
			}
			[invocation getArgument:&expected atIndex:i];
			NSString *returnType = [NSString stringWithFormat:@"%s", [[value methodSignatureForSelector:selector] methodReturnType]];
			if ([returnType isEqualToString:@"@"]) {
				if ([expected isKindOfClass:[NSString class]]) {
					if ([[value performSelector:selector] rangeOfString:expected].length == 0) {
						[errors addObject:[NSString stringWithFormat:@"%@ : '%@' doesn't contain '%@'", key, [value performSelector:selector], expected]];
						foundErrors = YES;
						continue;
					}
				} else if (![[value performSelector:selector] isEqual:expected]) {
					[errors addObject:[NSString	stringWithFormat:@"%@ : %@ is not equal to %@", key, [value performSelector:selector], expected]];
					foundErrors = YES;
					continue;
				}
			} else if ([value performSelector:selector] != expected) {
				[errors addObject:[NSString	stringWithFormat:@"%@ is not equal to value", key]];
				foundErrors = YES;
				continue;
			}
		}
	}
	if (foundErrors) {
		if (!isFailureTest) {
			[NSException raise:nil format:@"%@ should have %@ but %@\n%s:%d\n", [self valueAsString], selector, errors, file, line];
		}
	} else if (isFailureTest) {
		[NSException raise:nil format:@"%@\n%s:%d", @"expected: Failure, got: Success", file, line];\
	}
}

-(NSString *)valueAsString {
	return [value description];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	NSMutableString *selector = NSStringFromSelector(aSelector);
	if (isBe) {
		if (![value respondsToSelector:aSelector] && [value respondsToSelector:[UIExpectation makeIsSelector:aSelector]]) {
			aSelector = [UIExpectation makeIsSelector:aSelector];
		}
		//NSLog(@"isBe value = %@, selecotr = %@", value, NSStringFromSelector(aSelector));
		return [value methodSignatureForSelector:aSelector];
	}else if (isHave) {
		if (isNot) {
			[NSException raise:nil format:@"not isn't supported yet for something like [should.not.have foo:1]"];
		}
		NSString *selector = NSStringFromSelector(aSelector);
		NSRange whereIsSet = [selector rangeOfString:@":"];
		if (whereIsSet.length != 0) {
			NSArray *selectors = [NSStringFromSelector(aSelector) componentsSeparatedByString:@":"];
			NSMutableString *signature = [NSMutableString stringWithString:@"@@:"];
			for (NSString *selector in selectors) {
				if ([selector length] > 0) {
					[signature appendString:@"@"];
				}
			}
			//NSLog(@"signature = %@", signature);
			return [NSMethodSignature signatureWithObjCTypes:[signature cStringUsingEncoding:NSUTF8StringEncoding]]; 
		}
	}
	return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	NSMutableString *selector = [NSMutableString stringWithString:NSStringFromSelector([anInvocation selector])];
	if (isBe) {
		[self be:[anInvocation selector]];
	} else if (isHave) {
		[self have:anInvocation];
	}
}

+(SEL)makeIsSelector:(SEL)aSelector {
	NSString *selector = NSStringFromSelector(aSelector);
	return NSSelectorFromString([NSString stringWithFormat:@"is%@", [selector stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[selector substringWithRange:NSMakeRange(0,1)] uppercaseString]]]);
}

@end
