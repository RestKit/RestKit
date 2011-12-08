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

- (void)testShouldInstantiateAFormatterWithDefaultGMTTimeZone {
    RKDotNetDateFormatter *formatter = [RKDotNetDateFormatter dotNetDateFormatter];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"]; 
    assertThat(formatter, isNot(equalTo(nil)));
    assertThat(formatter.timeZone, is(equalTo(timeZone)));
}


- (void)testShouldInstantiateAFormatterWithATimeZone {
    NSTimeZone *timeZoneCST = [NSTimeZone timeZoneWithAbbreviation:@"CST"]; 
    RKDotNetDateFormatter *formatter = [RKDotNetDateFormatter dotNetDateFormatterWithTimeZone:timeZoneCST];
    assertThat(formatter, isNot(equalTo(nil)));
    assertThat(formatter.timeZone, is(equalTo(timeZoneCST)));
}

- (void)testShouldCreateADateFromDotNetThatWithAnOffset {
    NSString *dotNetString = @"/Date(1000212360000-0400)/";
    RKDotNetDateFormatter *formatter = [RKDotNetDateFormatter dotNetDateFormatter];
    NSDate *date = [formatter dateFromString:dotNetString];
    assertThat([date description], is(equalTo(@"2001-09-11 12:46:00 +0000")));
}

- (void)testShouldCreateADateFromDotNetWithoutAnOffset {
    NSString *dotNetString = @"/Date(1112715000000)/";
    RKDotNetDateFormatter *formatter = [RKDotNetDateFormatter dotNetDateFormatter];
    NSDate *date = [formatter dateFromString:dotNetString];
    assertThat([date description], is(equalTo(@"2005-04-05 15:30:00 +0000")));
}

- (void)testShouldFailToCreateADateFromInvalidStrings {
    RKDotNetDateFormatter *formatter = [RKDotNetDateFormatter dotNetDateFormatter];
    NSDate *date = [formatter dateFromString:nil];
    assertThat(date, is(equalTo(nil)));
    date = [formatter dateFromString:@"(null)"];
    assertThat(date, is(equalTo(nil)));
    date = [formatter dateFromString:@"1112715000-0500"];
    assertThat(date, is(equalTo(nil)));
}

- (void)testShouldCreateADotNetStringFromADateWithATimeZone {
    NSTimeZone *timeZoneEST = [NSTimeZone timeZoneWithAbbreviation:@"EST"]; 
    RKDotNetDateFormatter *formatter = [RKDotNetDateFormatter dotNetDateFormatterWithTimeZone:timeZoneEST];
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:1000212360];
    NSString *string = [formatter stringFromDate:referenceDate];
    assertThat(formatter.timeZone, is(equalTo(timeZoneEST)));
    assertThat(string, is(equalTo(@"/Date(1000212360000-0400)/")));
}


@end
