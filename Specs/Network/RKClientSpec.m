//
//  RKClientSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/31/11.
//  Copyright 2011 Two Toasters
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

#import "RKSpecEnvironment.h"
#import "RKURL.h"

@interface RKClientSpec : RKSpec {
}

@end


@implementation RKClientSpec

- (void)itShouldDetectNetworkStatusWithAHostname {
	RKClient* client = [RKClient clientWithBaseURL:@"http://restkit.org"];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
	RKReachabilityNetworkStatus status = [client.reachabilityObserver networkStatus];
	[expectThat(status) shouldNot:be(RKReachabilityIndeterminate)];	
}

- (void)itShouldDetectNetworkStatusWithAnIPAddressBaseName {
	RKClient* client = [RKClient clientWithBaseURL:@"http://173.45.234.197"];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
	RKReachabilityNetworkStatus status = [client.reachabilityObserver networkStatus];
	[expectThat(status) shouldNot:be(RKReachabilityIndeterminate)];	
}
- (void)itShouldSetTheCachePolicyOfTheRequest {
    RKClient* client = [RKClient clientWithBaseURL:@"http://restkit.org"];
    client.cachePolicy = RKRequestCachePolicyLoadIfOffline;
    RKRequest* request = [client requestWithResourcePath:@"" delegate:nil];
	[expectThat(request.cachePolicy) should:be(RKRequestCachePolicyLoadIfOffline)];
}

- (void)itShouldInitializeTheCacheOfTheRequest {
    RKClient* client = [RKClient clientWithBaseURL:@"http://restkit.org"];
    client.requestCache = [[[RKRequestCache alloc] init] autorelease];
    RKRequest* request = [client requestWithResourcePath:@"" delegate:nil];
	[expectThat(request.cache) should:be(client.requestCache)];
}

- (void)itShouldAllowYouToChangeTheBaseURL {
    RKClient* client = [RKClient clientWithBaseURL:@"http://www.google.com"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    [expectThat([client isNetworkReachable]) should:be(YES)];
    client.baseURL = @"http://www.restkit.org";
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    [expectThat([client isNetworkReachable]) should:be(YES)];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [client requestWithResourcePath:@"/" delegate:loader];
    [request send];
    [loader waitForResponse];
    assertThatBool(loader.success, is(equalToBool(YES)));
}

- (void)itShouldLetYouChangeTheHTTPAuthCredentials {
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKClient *client = RKSpecNewClient();
    client.authenticationType = RKRequestAuthenticationTypeHTTP;
    client.username = @"invalid";
    client.password = @"password";
    RKSpecResponseLoader *responseLoader = [RKSpecResponseLoader responseLoader];
    [client get:@"/authentication/basic" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.success, is(equalToBool(NO)));
    assertThat(responseLoader.failureError, is(notNilValue()));
    client.username = @"restkit";
    client.password = @"authentication";
    [client get:@"/authentication/basic" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.success, is(equalToBool(YES)));
    RKLogConfigureByName("RestKit/Network", RKLogLevelInfo);
}

- (void)itShouldSuspendTheQueueOnBaseURLChangeWhenReachabilityHasNotBeenEstablished {
    RKClient* client = [RKClient clientWithBaseURL:@"http://www.google.com"];
    client.baseURL = @"http://restkit.org";
    assertThatBool(client.requestQueue.suspended, is(equalToBool(YES)));
}

- (void)itShouldNotSuspendTheMainQueueOnBaseURLChangeWhenReachabilityHasBeenEstablished {
    RKReachabilityObserver *observer = [RKReachabilityObserver reachabilityObserverForInternet];
    [observer getFlags];
    assertThatBool([observer isReachabilityDetermined], is(equalToBool(YES)));
    RKClient *client = [RKClient clientWithBaseURL:@"http://www.google.com"];
    assertThatBool(client.requestQueue.suspended, is(equalToBool(YES)));
    client.reachabilityObserver = observer;
    assertThatBool(client.requestQueue.suspended, is(equalToBool(NO)));
}

- (void)itShouldPerformAPUTWithParams {
    NSLog(@"PENDING ---> FIX ME!!!");
    return;
    RKClient* client = [RKClient clientWithBaseURL:@"http://ohblockhero.appspot.com/api/v1"];
    client.cachePolicy = RKRequestCachePolicyNone;
    RKParams *params=[RKParams params];
    [params setValue:@"username" forParam:@"username"];
    [params setValue:@"Dear Daniel" forParam:@"fullName"];
    [params setValue:@"aa@aa.com" forParam:@"email"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
//    loader.timeout = 15;
    [client put:@"/userprofile" params:params delegate:loader];    
    [loader waitForResponse];
    assertThatBool(loader.success, is(equalToBool(NO)));
}

@end
