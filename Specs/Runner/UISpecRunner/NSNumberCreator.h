// This code is in the public domain, use it as you like.
// Created by Martin Häcker

/*
 Use like this:
 id dict = [NSDictionary dictionary];
 NSNumber *ten = NMMakeNumber(10.0f);
 [dict setObject:ten forKey:@"numberOfFingers"];
 [dict setObject:NMMakeNumber(23) forKey:@"fnord"];
 [dict setObject:NMMakeNumber(YES) forKey:@"wantFries"];
 */

#define N(aValue) ({ \
/* The stack var is here, so this macro can accept constants directly. */ \
__typeof__(aValue) __aValue = (aValue); \
[NSNumberCreator numberWithValue:&__aValue objCType:@encode(__typeof__(aValue))]; \
}) \

@interface NSNumberCreator : NSObject
+ numberWithValue:(const void *)aValue objCType:(const char *)aTypeDescription;
- initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription;
@end
