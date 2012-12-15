//
//  RKValueTransformers.m
//  RestKit
//
//  Created by Blake Watters on 11/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKValueTransformers.h"
#import "RKMacros.h"

// Implementation lives in RKObjectMapping.m at the moment
NSDate *RKDateFromStringWithFormatters(NSString *dateString, NSArray *formatters);

@implementation RKDateToStringValueTransformer

+ (Class)transformedValueClass
{
    return [NSDate class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)initWithDateToStringFormatter:(NSFormatter *)dateToStringFormatter stringToDateFormatters:(NSArray *)stringToDateFormatters
{
    self = [self init];
    if (self) {
        self.dateToStringFormatter = dateToStringFormatter;
        self.stringToDateFormatters = stringToDateFormatters;
    }
    return self;
}

- (id)transformedValue:(id)value
{
    NSAssert(self.stringToDateFormatters, @"Cannot transform an `NSDate` to an `NSString`: stringToDateFormatters is nil");
    RKAssertValueIsKindOfClass(value, [NSString class]);
    return RKDateFromStringWithFormatters(value, self.stringToDateFormatters);
}

- (id)reverseTransformedValue:(id)value
{
    NSAssert(self.dateToStringFormatter, @"Cannot transform an `NSDate` to an `NSString`: dateToStringFormatter is nil");
    RKAssertValueIsKindOfClass(value, [NSDate class]);
    @synchronized(self.dateToStringFormatter) {
        return [self.dateToStringFormatter stringForObjectValue:value];
    }
}

@end
