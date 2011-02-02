//
//  RKClientSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import <RestKit/RestKit.h>

@interface RKClientSpec : NSObject <UISpec> {
}

@end


@implementation RKClientSpec

- (void)itShouldDetectNetworkStatusWithAHostname {
	RKClient* client = [RKClient clientWithBaseURL:@"http://restkit.org"];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; // Let the runloop cycle
	RKReachabilityNetworkStatus status = [client.baseURLReachabilityObserver networkStatus];
	[expectThat(status) shouldNot:be(RKReachabilityIndeterminate)];	
}

- (void)itShouldDetectNetworkStatusWithAnIPAddressBaseName {
	RKClient* client = [RKClient clientWithBaseURL:@"http://192.168.1.177"];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; // Let the runloop cycle
	RKReachabilityNetworkStatus status = [client.baseURLReachabilityObserver networkStatus];
	[expectThat(status) shouldNot:be(RKReachabilityIndeterminate)];	
}

@end
