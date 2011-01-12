//
//  RKReachabilityObserver.m
//  RestKit
//
//  Created by Blake Watters on 9/14/10.
//
//

#import "RKReachabilityObserver.h"
#import <UIKit/UIKit.h>

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
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
	
	if (nil != reachabilityRef) {
		observer = [[[self alloc] initWithReachabilityRef:reachabilityRef] autorelease];
	}
	return observer;
}

- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef {
	if (self = [self init]) {
		_reachabilityRef = reachabilityRef;
		[self scheduleObserver];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(scheduleObserver)
													 name:UIApplicationDidBecomeActiveNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(unscheduleObserver)
													 name:UIApplicationWillResignActiveNotification
												   object:nil];
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
