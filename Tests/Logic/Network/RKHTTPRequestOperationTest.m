//
//  RKHTTPRequestOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 12/11/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKHTTPRequestOperation.h"

@interface RKHTTPRequestOperationTest : XCTestCase

@end

@implementation RKHTTPRequestOperationTest

- (void)testThatLoadingAnUnexpectedContentTypeReturnsCorrectErrorMessage
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/XML/channels.xml" relativeToURL:[RKTestFactory baseURL]]];
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    requestOperation.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"Expected content type {(\n    \"application/json\"\n)}, got application/xml");
}

- (void)testThatLoadingAnUnexpectedStatusCodeReturnsCorrectErrorMessage
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/503" relativeToURL:[RKTestFactory baseURL]]];
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.acceptableContentTypes = [NSSet setWithObject:@"text/xml"];
    requestOperation.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"Expected status code in (200), got 503");
}

- (void)testThatLoadingAHeadResponseWithNoContentTypeDoesNotReturnAnError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/no_content_type/200" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = RKStringFromRequestMethod(RKRequestMethodHEAD);
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.acceptableContentTypes = [NSSet setWithObject:@"text/xml"];
    requestOperation.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).to.beNil();
}

- (void)testThatLoadingAGetResponseWithNoContentTypeDoesNotReturnAnError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/no_content_type/200" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = RKStringFromRequestMethod(RKRequestMethodGET);
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.acceptableContentTypes = [NSSet setWithObject:@"text/xml"];
    requestOperation.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).to.beNil();
}

- (void)testThatLoadingA304StatusDoesNotReturnExpectedContentTypeErrorWithMissingContentType
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/no_content_type/304" relativeToURL:[RKTestFactory baseURL]]];
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.acceptableContentTypes = [NSSet setWithObject:@"text/xml"];
    requestOperation.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:304];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).to.beNil();
}

- (void)testThatLoadingA204StatusDoesNotReturnExpectedContentTypeErrorWithMissingContentType
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/no_content_type/204" relativeToURL:[RKTestFactory baseURL]]];
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.acceptableContentTypes = [NSSet setWithObject:@"text/xml"];
    requestOperation.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:204];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).to.beNil();
}

- (void)testThatLoadingA202StatusDoesNotReturnExpectedContentTypeErrorWithMissingContentType
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/no_content_type/202" relativeToURL:[RKTestFactory baseURL]]];
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.acceptableContentTypes = [NSSet setWithObject:@"text/xml"];
    requestOperation.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:202];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).to.beNil();
}

@end
