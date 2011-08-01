#import "NSNumberCreator.h"

@implementation NSNumberCreator
+ numberWithValue:(const void *)aValue objCType:(const char *)aTypeDescription;
{
	return [[[self alloc] initWithValue:aValue objCType:aTypeDescription] autorelease];
}

/// For the constants see: <http://developer.apple.com/documentation/Cocoa/Conceptual/ObjectiveC/Articles/chapter_14_section_9.html>
- initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription;
{
	if ('^' == *aTypeDescription
		&& nil == *(id *)aValue) return nil; // nil should stay nil, even if it's technically a (void *)
	id number = [NSNumber alloc];
	switch (*aTypeDescription) 
	{
		case 'c': // BOOL, char
			return [number initWithChar:*(char *)aValue];
		case 'C': return [number initWithUnsignedChar:*(unsigned char *)aValue];
		case 's': return [number initWithShort:*(short *)aValue];
		case 'S': return [number initWithUnsignedShort:*(unsigned short *)aValue];
		case 'i': return [number initWithInt:*(int *)aValue];
		case 'I': return [number initWithUnsignedInt:*(unsigned *)aValue];
		case 'l': return [number initWithLong:*(long *)aValue];
		case 'L': return [number initWithUnsignedLong:*(unsigned long *)aValue];
		case 'q': return [number initWithLongLong:*(long long *)aValue];
		case 'Q': return [number initWithUnsignedLongLong:*(unsigned long long *)aValue];
		case 'f': return [number initWithFloat:*(float *)aValue];
		case 'd': return [number initWithDouble:*(double *)aValue];
		case '@': return *(id *)aValue;
		case '^': // pointer, no string stuff supported right now
		case '{': // struct, only simple ones containing only basic types right now
		case '[': // array, of whatever, just gets the address
			return [[NSValue alloc] initWithBytes:aValue objCType:aTypeDescription];
	}

	return [[NSValue alloc] initWithBytes:aValue objCType:aTypeDescription];	
}
@end

// The ... is just to silence compiler warnings about multiple arguments if commas are used
//#define test(result...) ({ \
//if ( ! (result)) \
//printf("%s:%d: %s\n", __FILE__, __LINE__, #result); \
//})
//
//int main (int argc, const char * argv[]) {
//    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
//	
//	// Creating NSValues
//	void *voidPointer = main;
//	test(main == [NMMakeNumber(voidPointer) pointerValue]);
//	
//	NSPoint pointVal = NSMakePoint(2,3);
//	NSPoint boxedPoint = [NMMakeNumber(pointVal) pointValue];
//	test(pointVal.x == boxedPoint.x);
//	test(pointVal.y == boxedPoint.y);
//	
//	NSRange rangeVal = NSMakeRange(2, 3);
//	NSRange boxedRange = [NMMakeNumber(rangeVal) rangeValue];
//	test(rangeVal.location == boxedRange.location);
//	test(rangeVal.length == boxedRange.length);
//	
//	NSRect rectVal = NSMakeRect(1, 2, 3, 4);
//	NSRect boxedRect = [NMMakeNumber(rectVal) rectValue];
//	test(rectVal.origin.x == boxedRect.origin.x);
//	
//	NSSize sizeVal = NSMakeSize(2, 3);
//	NSSize boxedSize = [NMMakeNumber(sizeVal) sizeValue];
//	test(sizeVal.width == boxedSize.width);
//	
//	// Creating NSNumbers
//	test( YES == [NMMakeNumber((BOOL)YES) boolValue]);
//	test( nil != NMMakeNumber((BOOL)NO));
//	test( nil != NMMakeNumber(NO));
//	test( -23 == [NMMakeNumber((char)-23) charValue]);
//	test( -23 == [NMMakeNumber((int)-23) intValue]);
//	test( -23 == [NMMakeNumber((NSInteger)-23) integerValue]);
//	test( -23 == [NMMakeNumber((long)-23) longValue]);
//	test( -23 == [NMMakeNumber((long long)-23) longLongValue]);
//	test( 23 == [NMMakeNumber((short)23) shortValue]);
//	test( 23 == [NMMakeNumber((unsigned char)23) unsignedCharValue]);
//	test( 23 == [NMMakeNumber((unsigned short)23) unsignedShortValue]);
//	test( 23 == [NMMakeNumber((unsigned int)23) unsignedIntValue]);
//	test( 23 == [NMMakeNumber((NSUInteger)23) unsignedIntegerValue]);
//	test( 23 == [NMMakeNumber((unsigned long)23) unsignedLongValue]);
//	test( 23 == [NMMakeNumber((unsigned long long)23) unsignedLongLongValue]);
//	
//	test( 23.1f == [NMMakeNumber((float)23.1) floatValue]);
//	test( 23.1F == [NMMakeNumber((double)23.1F) doubleValue]);
//	
//	test(nil == NMMakeNumber(nil));
//	test([@"fnord" isEqual:NMMakeNumber(@"fnord")]);
//	// REFACT: consider changing cStrings to objCStrings. Not sure if I want this though
//	
//	test( 23 == [NMMakeNumber(23.1F) intValue]);
//	test( -23.0f == [NMMakeNumber(-23) floatValue]);
//	//	test( 23 == [NMMakeNumber((int)-23) unsignedIntValue]);
//	// TODO: propper conversion of NSNumbers so the test above doesn't fail anymore
//	
//    [pool drain];
//    return 0;
//}
