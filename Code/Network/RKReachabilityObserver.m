//
//  RKReachabilityObserver.m
//  RestKit
//
//  Created by Blake Watters on 9/14/10.
//  Copyright 2010 RestKit. All rights reserved.
//

#import "RKReachabilityObserver.h"
#import <UIKit/UIKit.h>
#include <netdb.h>
#include <arpa/inet.h>

// Constants
NSString* const RKReachabilityStateChangedNotification = @"RKReachabilityStateChangedNotification";
static bool hasNetworkAvailabilityBeenDetermined = NO;

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
#pragma unused (target, flags)
	// We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
	// in case someone uses the Reachablity object in a different thread.
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	RKReachabilityObserver* observer = (RKReachabilityObserver*) info;
	
	hasNetworkAvailabilityBeenDetermined = YES;
	
	// Post a notification to notify the client that the network reachability changed.
	[[NSNotificationCenter defaultCenter] postNotificationName:RKReachabilityStateChangedNotification object:observer];
	
	[pool release];
}

#pragma mark -

@interface RKReachabilityObserver (Private)

// Internal initializer
- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef;
- (void)scheduleObserver;
- (void)unscheduleObserver;

@end

@implementation RKReachabilityObserver

+ (RKReachabilityObserver*)reachabilityObserverWithHostName:(NSString*)hostName {
	RKReachabilityObserver* observer = nil;
	SCNetworkReachabilityRef reachabilityRef;
	
	// Try to determine if we have an IP address or a hostname
	struct sockaddr_in sa;
    char* hostNameOrIPAddress = (char*) [hostName UTF8String];
	int result = inet_pton(AF_INET, hostNameOrIPAddress, &(sa.sin_addr));
	
	if (result != 0) {
		// IP Address
		struct sockaddr_in remote_saddr;
		
		bzero(&remote_saddr, sizeof(struct sockaddr_in));
		remote_saddr.sin_len = sizeof(struct sockaddr_in);
		remote_saddr.sin_family = AF_INET;
		inet_aton(hostNameOrIPAddress, &(remote_saddr.sin_addr));
		
		reachabilityRef = SCNetworkReachabilityCreateWithAddress(CFAllocatorGetDefault(), (struct sockaddr*)&remote_saddr);
		
		// We can immediately determine reachability to an IP address
		hasNetworkAvailabilityBeenDetermined = YES;
	} else {
		// Hostname
		reachabilityRef = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), hostNameOrIPAddress);
	}
	
	if (nil != reachabilityRef) {
		observer = [[[self alloc] initWithReachabilityRef:reachabilityRef] autorelease];
	}
	return observer;
}

- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef {
	if (self = [self init]) {
		_reachabilityRef = reachabilityRef;
		[self scheduleObserver];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self unscheduleObserver];
	if (_reachabilityRef) {
		CFRelease(_reachabilityRef);
	}
	[super dealloc];
}

- (RKReachabilityNetworkStatus)networkStatus {
	NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef");
	RKReachabilityNetworkStatus status = RKReachabilityNotReachable;
	SCNetworkReachabilityFlags flags;
	
	if (!hasNetworkAvailabilityBeenDetermined) {
		return RKReachabilityIndeterminate;
	}
	
	
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {		
		if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
			// if target host is not reachable
			return RKReachabilityNotReachable;
		}
		
		if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
			// if target host is reachable and no connection is required
			//  then we'll assume (for now) that your on Wi-Fi
			status = RKReachabilityReachableViaWiFi;
		}
		
		
		if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
			 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
			// ... and the connection is on-demand (or on-traffic) if the
			//     calling application is using the CFSocketStream or higher APIs
			
			if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
				// ... and no [user] intervention is needed
				status = RKReachabilityReachableViaWiFi;
			}
		}
		
		if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
			// ... but WWAN connections are OK if the calling application
			//     is using the CFNetwork (CFSocketStream?) APIs.
			status = RKReachabilityReachableViaWWAN;
		}
	}
	return status;	
}

- (BOOL)isNetworkReachable {
	return (RKReachabilityNotReachable != [self networkStatus]);
}

- (BOOL)isConnectionRequired {
	NSAssert(_reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
	}
	return NO;
}

#pragma mark Observer scheduling

- (void)scheduleObserver {
	SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
	if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
		if (NO == SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
			NSLog(@"Warning -- Unable to schedule reachability observer in current run loop.");
		}
	}
}

- (void)unscheduleObserver {
	if (nil != _reachabilityRef) {
		SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
}

@end
