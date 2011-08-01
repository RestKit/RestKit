
#import "UIMatcher.h"
#import "NSNumberCreator.h"

@implementation UIMatcher

@synthesize errorMessage;

+(id)withValue:(const void *)aValue objCType:(const char *)aTypeDescription matchSelector:(SEL)aMatchSelector {
	return [[[self alloc] initWithValue:aValue objCType:aTypeDescription matchSelector:(SEL)aMatchSelector] autorelease];
}

-(id)initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription matchSelector:(SEL)aMatchSelector {
	if (self = [super init]) {
		expectedTypeDescription = aTypeDescription;
		expectedValue = [NSNumberCreator numberWithValue:aValue objCType:aTypeDescription];
		matchSelector = aMatchSelector;
	}
	return self;
}

-(BOOL)matches:(id)value {
	return [self performSelector:matchSelector withObject:value];
}

-(BOOL)be:(id)value {
	self.errorMessage = [NSString stringWithFormat:@"expected: %@, got: %@", expectedValue==nil?@"nil":expectedValue, value==nil?@"nil":value];
	return (expectedValue == value || [expectedValue isEqual:value]);
}

+(NSString *)valueAsString:(const void *)value objCType:(const char *)typeDescription {
	if ('^' == *typeDescription) {
		return @"nil";
	}
	if ('@' == *typeDescription) {
		return [NSString stringWithFormat:@"%@", *(id *)value];
	}
	return [[NSNumber numberWithValue:value objCType:typeDescription] stringValue];
}

- (void)dealloc {
	self.errorMessage = nil;
	[super dealloc];
}


@end
