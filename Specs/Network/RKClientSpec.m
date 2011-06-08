//
//  RKClientSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"

@interface RKClientSpec : NSObject <UISpec> {
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

@end
