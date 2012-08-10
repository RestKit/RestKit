//
//  RKDotNetDateFormatter.h
//  RestKit
//
//  Created by Greg Combs on 9/8/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKDotNetDateFormatter.h"
#import "RestKit.h"

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000

BOOL isValidRange(NSRange rangeOfMatch);
NSTimeInterval secondsFromMilliseconds(NSTimeInterval millisecs);
NSTimeInterval millisecondsFromSeconds(NSTimeInterval seconds);

@interface RKDotNetDateFormatter ()
- (NSString *)millisecondsFromString:(NSString *)string;
@end

@implementation RKDotNetDateFormatter

+ (RKDotNetDateFormatter *)dotNetDateFormatter
{
    return [RKDotNetDateFormatter dotNetDateFormatterWithTimeZone:nil];
}

+ (RKDotNetDateFormatter *)dotNetDateFormatterWithTimeZone:(NSTimeZone *)newTimeZone
{
    RKDotNetDateFormatter *formatter = [[[RKDotNetDateFormatter alloc] init] autorelease];
    if (newTimeZone)
        formatter.timeZone = newTimeZone;
    return formatter;
}

- (NSDate *)dateFromString:(NSString *)string
{
    NSString *milliseconds = [self millisecondsFromString:string];
    if (!milliseconds) {
        RKLogError(@"Attempted to interpret an invalid .NET date string: %@", string);
        return nil;
    }
    NSTimeInterval seconds = secondsFromMilliseconds([milliseconds doubleValue]);
    return [NSDate dateWithTimeIntervalSince1970:seconds];
}


- (NSString *)stringFromDate:(NSDate *)date
{
    if (!date) {
        RKLogError(@"Attempted to represent an invalid date: %@", date);
        return nil;
    }
    NSTimeInterval milliseconds = millisecondsFromSeconds([date timeIntervalSince1970]);
    NSString *timeZoneOffset = [super stringFromDate:date];
    return [NSString stringWithFormat:@"/Date(%1.0lf%@)/", milliseconds, timeZoneOffset];
}

- (BOOL)getObjectValue:(id *)outValue forString:(NSString *)string errorDescription:(NSString **)error
{
    NSDate *date = [self dateFromString:string];
    if (outValue)
        *outValue = date;
    return (date != nil);
}

- (id)init
{
    self = [super init];
    if (self) {
        self.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        self.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [self setDateFormat:@"ZZ"]; // GMT offset, like "-0500"
        NSString *pattern = @"\\/Date\\((-?\\d+)((?:[\\+\\-]\\d+)?)\\)\\/"; // /Date(mSecs)/ or /Date(-mSecs)/ or /Date(mSecs-0400)/
        dotNetExpression = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    }
    return self;
}


- (void)dealloc
{
    [dotNetExpression release];
    [super dealloc];
}


- (NSString *)millisecondsFromString:(NSString *)string
{
    if (!string)
        return nil;
    NSTextCheckingResult *match = [dotNetExpression firstMatchInString:string options:NSMatchingCompleted range:NSMakeRange(0, [string length])];
    if (!match)
        return nil;
    NSRange millisecRange = [match rangeAtIndex:1];
    if (!isValidRange(millisecRange))
        return nil;
    //NSRange timeZoneRange = [match rangeAtIndex:2];
    NSString *milliseconds = [string substringWithRange:millisecRange];
    return milliseconds;
}
@end


BOOL isValidRange(NSRange rangeOfMatch) {
    return (!NSEqualRanges(rangeOfMatch, NSMakeRange(NSNotFound, 0)));
}


NSTimeInterval secondsFromMilliseconds(NSTimeInterval millisecs) {
    return millisecs / 1000.f;
}


NSTimeInterval millisecondsFromSeconds(NSTimeInterval seconds) {
    return seconds *1000.f;
}

#endif
