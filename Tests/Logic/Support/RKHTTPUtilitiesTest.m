//
//  RKHTTPUtilitiesTest.m
//  RestKit
//
//  Created by Blake Watters on 10/14/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKHTTPUtilities.h"

@interface RKHTTPUtilitiesTest : RKTestCase

@end

@implementation RKHTTPUtilitiesTest

#pragma mark - RKPathAndQueryStringFromURLRelativeToURL

- (void)testThatYesIsReturnedWhenTheGivenRequestMethodIsAnExactMatch
{
    expect(RKIsSpecificRequestMethod(RKRequestMethodPOST)).to.beTruthy();
}

- (void)testThatNoIsReturnedWhenTheGivenRequestMethodIsAny
{
    expect(RKIsSpecificRequestMethod(RKRequestMethodAny)).to.beFalsy();
}

- (void)testThatNoIsReturnedWhenTheGivenRequestMethodIsNotAnExactMatch
{
    expect(RKIsSpecificRequestMethod(RKRequestMethodGET | RKRequestMethodPOST)).to.beFalsy();
}

- (void)testThatNilIsReturnedWhenTheGivenURLIsNotRelativeToTheBaseURL
{
    NSURL *baseURL = [NSURL URLWithString:@"http://google.com/path"];
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/path"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.beNil();
}

- (void)testReturningThePathAndQueryParametersWithANilBaseURLForURLWithNoPath
{
    NSURL *baseURL = nil;
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"");
}

- (void)testReturningThePathAndQueryParametersWithANilBaseURLForURLWithASingleSlashAsThePath
{
    NSURL *baseURL = nil;
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"/");
}

- (void)testReturningThePathAndQueryParametersWithANilBaseURLForURLWithAPath
{
    NSURL *baseURL = nil;
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/the/path"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"/the/path");
}

- (void)testReturningThePathAndQueryParametersWithANilBaseURLForURLWithAPathAndQueryString
{
    NSURL *baseURL = nil;
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/search?this=that&type=search"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"/search?this=that&type=search");
}

- (void)testShouldReturnAnEmptyStringGivenAURLEqualToTheBaseURLWithNoPath
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"");
}

- (void)testShouldReturnAnEmptyStringGivenAURLEqualToTheBaseURLWithASingleSlashAsThePath
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/"];
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"");
}

- (void)testShouldReturnTheCompletePathAndQueryStringGivenABaseURLWithNoPath
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/search?this=that&type=search"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"/search?this=that&type=search");
}

- (void)testShouldReturnJustTheRelativePathGivenABaseURLWithASingleTrailingSlash
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/"];
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/search?this=that&type=search"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"search?this=that&type=search");
}

- (void)testShouldReturnTheCompletePathAndQueryStringGivenABaseURLWithAComplexPathWithNoTrailingSlash
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1"];
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/api/v1/search?this=that&type=search"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"/search?this=that&type=search");
}

- (void)testShouldReturnTheCompletePathAndQueryStringGivenABaseURLWithAComplexPathWithATrailingSlash
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/api/v1/search?this=that&type=search"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, baseURL);
    expect(pathAndQueryString).to.equal(@"search?this=that&type=search");
}

- (void)testShouldNotDropTheTrailingSlashFromThePathOfAURLThatIncludesAQueryString
{
    NSURL *testURL = [NSURL URLWithString:@"http://restkit.org/api/v1/search/?this=that&type=search"];
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(testURL, nil);
    expect(pathAndQueryString).to.equal(@"/api/v1/search/?this=that&type=search");
}

- (void)testRequestMethodStringForSimpleValue
{
    expect(RKStringFromRequestMethod(RKRequestMethodGET)).to.equal(@"GET");
}

- (void)testRequestMethodStringForCompoundValueReturnsNil
{
    expect(RKStringFromRequestMethod(RKRequestMethodGET|RKRequestMethodDELETE)).to.beNil();
}

- (void)testRKDateFromHTTPDateString
{
    void (^testBlock)(NSDateComponents *) = ^void(NSDateComponents *dateComponents) {
        NSDateFormatter * const dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        dateFormatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss z";
        
        NSCalendar * const calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        NSDate * const sourceDate = [calendar dateFromComponents:dateComponents];
        NSString * const sourceString = [dateFormatter stringFromDate:sourceDate];
        NSDate * const destdate = RKDateFromHTTPDateString(sourceString);
        expect(destdate).to.equal(sourceDate);
    };
    
    NSDateComponents * const dateComponents = [[NSDateComponents alloc] init];
    dateComponents.hour = 0; dateComponents.minute = 0; dateComponents.second = 0;
    
    // epoch
    dateComponents.year = 1970; dateComponents.month = 1; dateComponents.day = 1;
    testBlock(dateComponents);
    
    // pre epoc
    dateComponents.year = 1969; dateComponents.month = 1; dateComponents.day = 27;
    testBlock(dateComponents);
    
    // release of U2's Achtung Baby album
    dateComponents.year = 1991; dateComponents.month = 11; dateComponents.day = 18;
    dateComponents.hour = 12; dateComponents.minute = 34; dateComponents.second = 56;
    testBlock(dateComponents);
}

- (void)testRKHTTPCacheExpirationDateFromHeadersWithStatusCode
{
	const NSInteger maxAge = 3600;
    NSDate * const date = [NSDate dateWithTimeIntervalSinceReferenceDate:1234];

    NSDateFormatter * const dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    dateFormatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss z";

	NSMutableDictionary * const headers = [[NSMutableDictionary alloc] initWithDictionary:@{
    	@"Cache-Control" : [NSString stringWithFormat:@"public, max-age=%d", maxAge],
        @"Date" : [dateFormatter stringFromDate:date]
    }];
    
    expect(RKHTTPCacheExpirationDateFromHeadersWithStatusCode(headers, 200)).to.equal([date dateByAddingTimeInterval:maxAge]);
    
    [headers setObject:[NSNumber numberWithInteger:(maxAge + 60)] forKey:@"Age"];
    expect(RKHTTPCacheExpirationDateFromHeadersWithStatusCode(headers, 200)).to.beLessThan(NSDate.date);

    [headers setObject:[NSNumber numberWithInteger:(maxAge - 60)] forKey:@"Age"];
    expect(RKHTTPCacheExpirationDateFromHeadersWithStatusCode(headers, 200)).to.beGreaterThan(NSDate.date);
}

@end
