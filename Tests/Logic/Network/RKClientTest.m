//
//  RKClientTest.m
//  RestKit
//
//  Created by Blake Watters on 1/31/11.
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

#import <SenTestingKit/SenTestingKit.h>
#import "RKTestEnvironment.h"
#import "RKURL.h"

@interface RKClientTest : RKTestCase
@end


@implementation RKClientTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testShouldDetectNetworkStatusWithAHostname
{
    RKClient *client = [[RKClient alloc] initWithBaseURLString:@"http://restkit.org"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    RKReachabilityNetworkStatus status = [client.reachabilityObserver networkStatus];
    assertThatInt(status, is(equalToInt(RKReachabilityReachableViaWiFi)));
    [client release];
}

- (void)testShouldDetectNetworkStatusWithAnIPAddressBaseName
{
    RKClient *client = [[RKClient alloc] initWithBaseURLString:@"http://173.45.234.197"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    RKReachabilityNetworkStatus status = [client.reachabilityObserver networkStatus];
    assertThatInt(status, isNot(equalToInt(RKReachabilityIndeterminate)));
    [client release];
}

- (void)testShouldSetTheCachePolicyOfTheRequest
{
    RKClient *client = [RKClient clientWithBaseURLString:@"http://restkit.org"];
    client.cachePolicy = RKRequestCachePolicyLoadIfOffline;
    RKRequest *request = [client requestWithResourcePath:@""];
    assertThatInt(request.cachePolicy, is(equalToInt(RKRequestCachePolicyLoadIfOffline)));
}

- (void)testShouldInitializeTheCacheOfTheRequest
{
    RKClient *client = [RKClient clientWithBaseURLString:@"http://restkit.org"];
    client.requestCache = [[[RKRequestCache alloc] init] autorelease];
    RKRequest *request = [client requestWithResourcePath:@""];
    assertThat(request.cache, is(equalTo(client.requestCache)));
}

- (void)testShouldLoadPageWithNoContentTypeInformation
{
    RKClient *client = [RKClient clientWithBaseURLString:@"http://www.semiose.fr"];
    client.defaultHTTPEncoding = NSISOLatin1StringEncoding;
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKRequest *request = [client requestWithResourcePath:@"/"];
    request.delegate = loader;
    [request send];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
    assertThat([loader.response bodyEncodingName], is(nilValue()));
    assertThatInteger([loader.response bodyEncoding], is(equalToInteger(NSISOLatin1StringEncoding)));
}

- (void)testShouldAllowYouToChangeTheBaseURL
{
    RKClient *client = [RKClient clientWithBaseURLString:@"http://www.google.com"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    assertThatBool([client isNetworkReachable], is(equalToBool(YES)));
    client.baseURL = [RKURL URLWithString:@"http://www.restkit.org"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    assertThatBool([client isNetworkReachable], is(equalToBool(YES)));
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKRequest *request = [client requestWithResourcePath:@"/"];
    request.delegate = loader;
    [request send];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldLetYouChangeTheHTTPAuthCredentials
{
    RKClient *client = [RKTestFactory client];
    client.authenticationType = RKRequestAuthenticationTypeHTTP;
    client.username = @"invalid";
    client.password = @"password";
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    [client get:@"/authentication/basic" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(NO)));
    assertThat(responseLoader.error, is(notNilValue()));
    client.username = @"restkit";
    client.password = @"authentication";
    [client get:@"/authentication/basic" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldSuspendTheQueueOnBaseURLChangeWhenReachabilityHasNotBeenEstablished
{
    RKClient *client = [RKClient clientWithBaseURLString:@"http://www.google.com"];
    client.baseURL = [RKURL URLWithString:@"http://restkit.org"];
    assertThatBool(client.requestQueue.suspended, is(equalToBool(YES)));
}

- (void)testShouldNotSuspendTheMainQueueOnBaseURLChangeWhenReachabilityHasBeenEstablished
{
    RKReachabilityObserver *observer = [RKReachabilityObserver reachabilityObserverForInternet];
    [observer getFlags];
    assertThatBool([observer isReachabilityDetermined], is(equalToBool(YES)));
    RKClient *client = [RKClient clientWithBaseURLString:@"http://www.google.com"];
    assertThatBool(client.requestQueue.suspended, is(equalToBool(YES)));
    client.reachabilityObserver = observer;
    assertThatBool(client.requestQueue.suspended, is(equalToBool(NO)));
}

- (void)testShouldAllowYouToChangeTheTimeoutInterval
{
    RKClient *client = [RKClient clientWithBaseURLString:@"http://restkit.org"];
    client.timeoutInterval = 20.0;
    RKRequest *request = [client requestWithResourcePath:@""];
    assertThatFloat(request.timeoutInterval, is(equalToFloat(20.0)));
}

- (void)testShouldPerformAPUTWithParams
{
    NSLog(@"PENDING ---> FIX ME!!!");
    return;
    RKClient *client = [RKClient clientWithBaseURLString:@"http://ohblockhero.appspot.com/api/v1"];
    client.cachePolicy = RKRequestCachePolicyNone;
    RKParams *params = [RKParams params];
    [params setValue:@"username" forParam:@"username"];
    [params setValue:@"Dear Daniel" forParam:@"fullName"];
    [params setValue:@"aa@aa.com" forParam:@"email"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [client put:@"/userprofile" params:params delegate:loader];
    STAssertNoThrow([loader waitForResponse], @"");
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(NO)));
}

- (void)testShouldAllowYouToChangeTheCacheTimeoutInterval
{
    RKClient *client = [RKClient clientWithBaseURLString:@"http://restkit.org"];
    client.cacheTimeoutInterval = 20.0;
    RKRequest *request = [client requestWithResourcePath:@""];
    assertThatFloat(request.cacheTimeoutInterval, is(equalToFloat(20.0)));
}

- (void)testThatRunLoopModePropertyRespected
{
    NSString * const dummyRunLoopMode = @"dummyRunLoopMode";
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKClient *client = [RKTestFactory client];
    client.runLoopMode = dummyRunLoopMode;
    [client get:[[RKTestFactory baseURL] absoluteString] delegate:loader];
    while ([[NSRunLoop currentRunLoop] runMode:dummyRunLoopMode beforeDate:[[NSRunLoop currentRunLoop] limitDateForMode:dummyRunLoopMode]])
        ;
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

@end
