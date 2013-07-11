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

@end
