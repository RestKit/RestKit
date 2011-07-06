//
//  RKReachabilityObserver.m
//  RestKit
//
//  Created by Blake Watters on 9/14/10.
//  Copyright 2010 RestKit. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "RKReachabilityObserver.h"
#include <netdb.h>
#include <arpa/inet.h>
#import "../Support/RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetworkReachability

@interface RKReachabilityObserver (Private)

@property (nonatomic, assign) BOOL reachabilityEstablished;

// Internal initializer
- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef;
- (void)scheduleObserver;
- (void)unscheduleObserver;

@end

// Constants
NSString* const RKReachabilityStateChangedNotification = @"RKReachabilityStateChangedNotification";
NSString* const RKReachabilityStateWasDeterminedNotification = @"RKReachabilityStateWasDeterminedNotification";

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
#pragma unused (target, flags)
	// We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
	// in case someone uses the Reachablity object in a different thread.
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	RKReachabilityObserver* observer = (RKReachabilityObserver*) info;
	
    if (!observer.reachabilityEstablished) {
        RKLogInfo(@"Network availability has been determined for reachability observer %@", observer);
        observer.reachabilityEstablished = YES;        
    }
	
	// Post a notification to notify the client that the network reachability changed.
	[[NSNotificationCenter defaultCenter] postNotificationName:RKReachabilityStateChangedNotification object:observer];
	
	[pool release];
}

#pragma mark -

@implementation RKReachabilityObserver

@synthesize hostName = _hostName;

- (id)initWithHostname:(NSString*)hostName {
    self = [self init];    
    if (self) {
        _hostName = [hostName retain];
        
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
            
            _reachabilityRef = SCNetworkReachabilityCreateWithAddress(CFAllocatorGetDefault(), (struct sockaddr*)&remote_saddr);
            
            // We can immediately determine reachability to an IP address
            _reachabilityEstablished = YES;
            
            RKLogInfo(@"Reachability observer initialized with IP address %@.", hostName);
            RKLogDebug(@"Reachability observer initialized with IP address, automatically marking reachability as determined.");            
        } else {
            // Hostname
            _reachabilityRef = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), hostNameOrIPAddress);
            RKLogInfo(@"Reachability observer initialized with hostname %@", hostName);
        }
        
        if (_reachabilityRef) {
            [self scheduleObserver];
        } else {
            RKLogWarning(@"Unable to initialize reachability reference");
        }
    }
    
    return self;
}

- (void)dealloc {
    RKLogTrace(@"Deallocating reachability observer %@", self);

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
	
	if (!self.reachabilityEstablished) {
        RKLogTrace(@"Reachability observer %@ has not yet established reachability. networkStatus = %@", self, @"RKReachabilityIndeterminate");
		return RKReachabilityIndeterminate;
	}
	
	
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        RKLogTrace(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c \n",
                   #if TARGET_OS_IPHONE
                   (flags & kSCNetworkReachabilityFlagsIsWWAN)				  ? 'W' : '-',
                   #endif
                   (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
                   (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
                   (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
                   (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
                   (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
                   (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
                   (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
                   (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'
                   );
        
		if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
			// if target host is not reachable
            RKLogTrace(@"Reachability observer %@ determined networkStatus = %@", self, @"RKReachabilityNotReachable");
			return RKReachabilityNotReachable;
		}
		
		if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
			// if target host is reachable and no connection is required
			//  then we'll assume (for now) that your on Wi-Fi
			RKLogTrace(@"Reachability observer %@ determined networkStatus = %@", self, @"RKReachabilityReachableViaWiFi");
            status = RKReachabilityReachableViaWiFi;
		}
		
		
		if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
			 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
			// ... and the connection is on-demand (or on-traffic) if the
			//     calling application is using the CFSocketStream or higher APIs
			
			if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
				// ... and no [user] intervention is needed
				status = RKReachabilityReachableViaWiFi;
                RKLogTrace(@"Reachability observer %@ determined networkStatus = %@", self, @"RKReachabilityReachableViaWiFi");
			}
		}
        
#if TARGET_OS_IPHONE
		if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
			// ... but WWAN connections are OK if the calling application
			//     is using the CFNetwork (CFSocketStream?) APIs.
			status = RKReachabilityReachableViaWWAN;
            RKLogTrace(@"Reachability observer %@ determined networkStatus = %@", self, @"RKReachabilityReachableViaWWAN");
		}
#endif
	}
    
	return status;	
}

- (BOOL)isNetworkReachable {
    BOOL reachable = (RKReachabilityNotReachable != [self networkStatus]);
    RKLogDebug(@"Reachability observer %@ determined isNetworkReachable = %d", self, reachable);
	return reachable;
}

- (BOOL)isConnectionRequired {
	NSAssert(_reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
	SCNetworkReachabilityFlags flags;
    BOOL required = NO;
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        required = (flags & kSCNetworkReachabilityFlagsConnectionRequired);        
	}
    
    RKLogDebug(@"Reachability observer %@ determined isConnectionRequired = %d", self, required);
	return required;
}

#pragma mark Observer scheduling

- (void)scheduleObserver {
	SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
	if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
        RKLogDebug(@"Scheduling reachability observer %@ in current run loop", self);
		if (NO == SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
			RKLogWarning(@"Warning -- Unable to schedule reachability observer in current run loop.");
		}
	}
}

- (void)unscheduleObserver {    
	if (_reachabilityRef) {
        RKLogDebug(@"Unscheduling reachability observer %@ from current run loop", self);
		SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	} else {
        RKLogDebug(@"Failed to unschedule reachability observer %@: reachability reference is nil.", _reachabilityRef);
    }
}

- (BOOL)reachabilityEstablished {
    return _reachabilityEstablished;
}

- (void)setReachabilityEstablished:(BOOL)reachabilityEstablished {
    _reachabilityEstablished = reachabilityEstablished;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKReachabilityStateWasDeterminedNotification object:self];
}

@end
