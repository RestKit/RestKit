//
//  RKClientSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
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
	RKReachabilityNetworkStatus status = [client.baseURLReachabilityObserver networkStatus];
	[expectThat(status) shouldNot:be(RKReachabilityIndeterminate)];	
}

- (void)itShouldDetectNetworkStatusWithAnIPAddressBaseName {
	RKClient* client = [RKClient clientWithBaseURL:@"http://173.45.234.197"];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
	RKReachabilityNetworkStatus status = [client.baseURLReachabilityObserver networkStatus];
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
    client.cache = [[[RKRequestCache alloc] init] autorelease];
    RKRequest* request = [client requestWithResourcePath:@"" delegate:nil];
	[expectThat(request.cache) should:be(client.cache)];
}

- (void)itShouldAllowYouToChangeTheBaseURL {
    NSLog(@"PENDING -> Unable to get this test to pass reliably...");
    return;
    RKClient* client = [RKClient clientWithBaseURL:@"http://www.google.com"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:15]]; // Let the runloop cycle
    [expectThat([client isNetworkAvailable]) should:be(YES)];
    client.baseURL = @"http://www.google.com";
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.5]]; // Let the runloop cycle
    [expectThat([client isNetworkAvailable]) should:be(YES)];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [client requestWithResourcePath:@"/" delegate:loader];
    [request send];
    [loader waitForResponse];
    assertThatBool(loader.success, is(equalToBool(YES)));
}

- (void)itShouldSuspendTheMainQueueOnBaseURLChangeWhenReachabilityHasNotBeenEstablished {
    RKClient* client = [RKClient clientWithBaseURL:@"http://www.google.com"];
    client.baseURL = @"http://restkit.org";
    assertThatBool([RKRequestQueue sharedQueue].suspended, is(equalToBool(YES)));
}

- (void)itShouldNotSuspendTheMainQueueOnBaseURLChangeWhenReachabilityHasBeenEstablished {
    RKClient* client = [RKClient clientWithBaseURL:@"http://www.google.com"];
    client.baseURL = @"http://127.0.0.1";
    assertThatBool([RKRequestQueue sharedQueue].suspended, is(equalToBool(NO)));
}

- (void)itShouldPerformAPUTWithParams {
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
