//
//  RKDotNetDateFormatterSpec.m
//  RestKit
//
//  Created by Greg Combs on 9/8/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKDotNetDateFormatter.h"

@interface RKDotNetDateFormatterSpec : RKSpec

@end

@implementation RKDotNetDateFormatterSpec

- (void)itShouldCreateADateFromDotNetWithTimeZone {
    NSString *dotNetString = @"/Date(1000212360000-0400)/";
    RKDotNetDateFormatter *formatter = [[RKDotNetDateFormatter alloc] init];
    NSDate *date = [formatter dateFromString:dotNetString];
    [formatter release];
    assertThat([date description], is(equalTo(@"2001-09-11 12:46:00 +0000")));
}

- (void)itShouldCreateADateFromDotNetWithoutTimeZoneAssumingGMT {
    NSString *dotNetString = @"/Date(1112715000000)/";
    RKDotNetDateFormatter *formatter = [[RKDotNetDateFormatter alloc] init];
    NSDate *date = [formatter dateFromString:dotNetString];
    [formatter release];
    assertThat([date description], is(equalTo(@"2005-04-05 15:30:00 +0000")));
}

- (void)itShouldFailToCreateADateFromInvalidStrings {
    RKDotNetDateFormatter *formatter = [[RKDotNetDateFormatter alloc] init];
    NSDate *date = [formatter dateFromString:nil];
    assertThat(date, is(equalTo(nil)));
    date = [formatter dateFromString:@"(null)"];
    assertThat(date, is(equalTo(nil)));
    date = [formatter dateFromString:@"1112715000-0500"];
    assertThat(date, is(equalTo(nil)));
    [formatter release];
}

- (void)itShouldCreateADotNetStringFromADateUsingATimeZoneOffset {
    RKDotNetDateFormatter *formatter = [[RKDotNetDateFormatter alloc] init];
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:1000212360];
    NSTimeZone *timeZoneEST = [NSTimeZone timeZoneWithAbbreviation:@"EST"]; 
    [formatter setTimeZone:timeZoneEST];    
    NSString *string = [formatter stringFromDate:referenceDate];
    [formatter release];
    assertThat(string, is(equalTo(@"/Date(1000212360000-0400)/")));
}


@end
