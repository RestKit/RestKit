//
//  RKHTTPRequestOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 12/11/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKHTTPRequestOperation.h"

@interface RKHTTPRequestOperationTest : SenTestCase

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

@end
