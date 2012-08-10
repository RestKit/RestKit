//
//  RKReachabilityObserver.h
//  RestKit
//
//  Created by Blake Watters on 9/14/10.
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

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

///-----------------------------------------------------------------------------
/// @name Constants
///-----------------------------------------------------------------------------

/**
 Posted when the network state has changed
 */
extern NSString * const RKReachabilityDidChangeNotification;

/**
 User Info key for accessing the SCNetworkReachabilityFlags from a
 RKReachabilityDidChangeNotification
 */
extern NSString * const RKReachabilityFlagsUserInfoKey;

/**
 Posted when network state has been initially determined
 */
extern NSString * const RKReachabilityWasDeterminedNotification;

typedef enum {
    /**
     Network reachability not yet known
     */
    RKReachabilityIndeterminate,
    /**
     Network is not reachable
     */
    RKReachabilityNotReachable,
    /**
     Network is reachable via a WiFi connection
     */
    RKReachabilityReachableViaWiFi,
    /**
     Network is reachable via a "wireless wide area network" (WWAN). i.e. GPRS,
     Edge, 3G, etc.
     */
    RKReachabilityReachableViaWWAN
} RKReachabilityNetworkStatus;

/**
 Provides a notification based interface for monitoring changes
 to network status.

 When initialized, creates an SCReachabilityReg and schedules it for callback
 notifications on the main dispatch queue. As notifications are intercepted from
 SystemConfiguration, the observer will update its state and emit
 `[RKReachabilityDidChangeNotifications](RKReachabilityDidChangeNotification)`
 to inform listeners about state changes.

 Portions of this software are derived from the Apple Reachability
 code sample: http://developer.apple.com/library/ios/#samplecode/Reachability/Listings/Classes_Reachability_m.html
 */
@interface RKReachabilityObserver : NSObject {
    SCNetworkReachabilityRef _reachabilityRef;
}

///-----------------------------------------------------------------------------
/// @name Creating a Reachability Observer
///-----------------------------------------------------------------------------

/**
 Creates and returns a RKReachabilityObserver instance observing reachability
 changes to the hostname or IP address referenced in a given string. The
 observer will monitor the ability to reach the specified remote host and emit
 notifications when its reachability status changes.

 The hostNameOrIPAddress will be introspected to determine if it contains an IP
 address encoded into a string or a DNS name. The observer will be configured
 appropriately based on the contents of the string.

 @bug Note that iOS 5 has known issues with hostname based reachability
 @param hostNameOrIPAddress An NSString containing a hostname or IP address to
 be observed.
 @return A reachability observer targeting the given hostname/IP address or nil
 if it could not be observed.
 */
+ (RKReachabilityObserver *)reachabilityObserverForHost:(NSString *)hostNameOrIPAddress;

/**
 Creates and returns a reachabilityObserverForInternet instance observing the
 reachability to the Internet in general.

 @return A reachability observer targeting INADDR_ANY or nil if it could not be
 observed.
 */
+ (RKReachabilityObserver *)reachabilityObserverForInternet;

/**
 Creates and returns a reachabilityObserverForInternet instance observing the
 reachability to the Internet via the local WiFi interface. Internet access
 available via the WWAN (3G, Edge, etc) will not be considered reachable.

 @return A reachability observer targeting IN_LINKLOCALNETNUM or nil if it could
 not be observed.
 */
+ (RKReachabilityObserver *)reachabilityObserverForLocalWifi;

/**
 Creates and returns a RKReachabilityObserver instance observing reachability
 changes to the sockaddr address provided.

 @param address A socket address to determine reachability for.
 @return A reachability observer targeting the given socket address or nil if it
 could not be observed.
 */
+ (RKReachabilityObserver *)reachabilityObserverForAddress:(const struct sockaddr *)address;

/**
 Creates and returns a RKReachabilityObserver instance observing reachability
 changes to the IP address provided.

 @param internetAddress A 32-bit integer representation of an IP address
 @return A reachability observer targeting the given IP address or nil if it
 could not be observed.
 */
+ (RKReachabilityObserver *)reachabilityObserverForInternetAddress:(in_addr_t)internetAddress;

/**
 Returns a RKReachabilityObserver instance observing reachability changes to the
 hostname or IP address referenced in a given string. The observer will monitor
 the ability to reach the specified remote host and emit notifications when its
 reachability status changes.

 The hostNameOrIPAddress will be introspected to determine if it contains an IP
 address encoded into a string or a DNS name. The observer will be configured
 appropriately based on the contents of the string.

 @bug Note that iOS 5 has known issues with hostname based reachability
 @param hostNameOrIPAddress An NSString containing a hostname or IP address to
 be observed.
 @return A reachability observer targeting the given hostname/IP address or nil
 if it could not be observed.
 */
- (id)initWithHost:(NSString *)hostNameOrIPAddress;

/**
 Returns a RKReachabilityObserver instance observing reachability changes to the
 sockaddr address provided.

 @param address A socket address to determine reachability for.
 @return A reachability observer targeting the given socket address or nil if it
 could not be observed.
 */
- (id)initWithAddress:(const struct sockaddr *)address;


///-----------------------------------------------------------------------------
/// @name Determining the Host
///-----------------------------------------------------------------------------

/**
 The remote hostname or IP address being observed for reachability.
 */
@property (nonatomic, readonly) NSString *host;


///-----------------------------------------------------------------------------
/// @name Managing Reachability States
///-----------------------------------------------------------------------------

/**
 Current state of determining reachability

 When initialized, RKReachabilityObserver instances are in an indeterminate
 state to indicate that reachability status has not been yet established. After
 the first callback is processed by the observer, the observer will answer YES
 for reachabilityDetermined and networkStatus will return a determinate
 response.

 @return YES if reachability has been determined
 */
@property (nonatomic, readonly, getter=isReachabilityDetermined) BOOL reachabilityDetermined;

/**
 Current network status as determined by examining the state of the currently
 cached reachabilityFlags

 @return Status of the network as RKReachabilityNetworkStatus
 */
@property (nonatomic, readonly) RKReachabilityNetworkStatus networkStatus;

/**
 Current state of the local WiFi interface's reachability

 When the local WiFi interface is being monitored, only three reachability
 states are possible:

 - RKReachabilityIndeterminate
 - RKReachabilityNotReachable
 - RKReachabilityReachableViaWiFi

 If the device has connectivity through a WWAN connection only it will consider
 the network not reachable.

 @see reachabilityObserverForLocalWifi

 @return YES if the reachability observer is monitoring the local WiFi interface
 */
@property (nonatomic, readonly, getter=isMonitoringLocalWiFi) BOOL monitoringLocalWiFi;


/**
 The reachability flags as of the last invocation of the reachability callback

 Each time the reachability callback is invoked with an asynchronous update of
 reachability status the flags are cached and made accessible via the
 reachabilityFlags method.

 Flags can also be directly obtained via [RKReachabilityObserver getFlags]

 @see getFlags
 @return The most recently cached reachability flags reflecting current network
 status.
 */
@property (nonatomic, readonly) SCNetworkReachabilityFlags reachabilityFlags;

/**
 Acquires the current network reachability flags, answering YES if
 successfully acquired; answering NO otherwise.

 Beware! The System Configuration framework operates synchronously by
 default. See Technical Q&A QA1693, Synchronous Networking On The Main
 Thread. Asking for flags blocks the current thread and potentially kills your
 iOS application if the reachability enquiry does not respond before the
 watchdog times out.
 */
- (BOOL)getFlags;


///-----------------------------------------------------------------------------
/// @name Reachability Introspection
///-----------------------------------------------------------------------------

/**
 Returns YES when the Internet is reachable (via WiFi or WWAN)

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if called before reachability is determined
 */
- (BOOL)isNetworkReachable;

/**
 Returns YES when we the network is reachable via WWAN

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if called before reachability is determined
 */
- (BOOL)isReachableViaWWAN;

/**
 Returns YES when we the network is reachable via WiFi

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if called before reachability is determined
 */
- (BOOL)isReachableViaWiFi;

/**
 Returns YES when WWAN may be available, but not active until a connection has been established.

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if called before reachability is determined
 */
- (BOOL)isConnectionRequired;

/**
 Returns YES if a dynamic, on-demand connection is available

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if called before reachability is determined
 */
- (BOOL)isConnectionOnDemand;

/**
 Returns YES if user intervention is required to initiate a connection

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if called before reachability is determined
 */
- (BOOL)isInterventionRequired;

/**
 Returns a string representation of the currently cached reachabilityFlags for inspection

 @return A string containing single character representations of the bits in an
 SCNetworkReachabilityFlags
 */
- (NSString *)reachabilityFlagsDescription;

@end
