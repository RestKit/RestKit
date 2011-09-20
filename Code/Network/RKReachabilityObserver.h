//
//  RKReachabilityObserver.h
//  RestKit
//
//  Created by Blake Watters on 9/14/10.
//  Copyright 2010 RestKit
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

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

/**
 * Posted when the network state has changed
 */
extern NSString* const RKReachabilityStateChangedNotification;
extern NSString* const RKReachabilityStateWasDeterminedNotification;

typedef enum {
	RKReachabilityIndeterminate,
	RKReachabilityNotReachable,
	RKReachabilityReachableViaWiFi,
	RKReachabilityReachableViaWWAN
} RKReachabilityNetworkStatus;

/**
 * Provides a notification based interface for monitoring changes
 * to network status8
 *
 * Portions of this software are derived from the Apple Reachability
 * code sample: http://developer.apple.com/library/ios/#samplecode/Reachability/Listings/Classes_Reachability_m.html
 */
@interface RKReachabilityObserver : NSObject {
    NSString* _hostName;
	SCNetworkReachabilityRef _reachabilityRef;
	BOOL _reachabilityEstablished;
}

/**
 The hostname we are observing reachability to
 */
@property (nonatomic, readonly) NSString* hostName;

/**
 Returns YES if reachability has been determined
 */
@property (nonatomic, readonly) BOOL reachabilityEstablished;

/**
 * Create a new reachability observer against a given hostname. The observer
 * will monitor the ability to reach the specified hostname and emit notifications
 * when its reachability status changes. 
 *
 * Note that the observer will be scheduled in the current run loop.
 */
- (id)initWithHostname:(NSString*)hostName;

/**
 * Returns the current network status
 */
- (RKReachabilityNetworkStatus)networkStatus;

/**
 * Returns YES when the Internet is reachable (via WiFi or WWAN)
 */
- (BOOL)isNetworkReachable;

/**
 * Returns YES when WWAN may be available, but not active until a connection has been established.
 */
- (BOOL)isConnectionRequired;

@end
