//
//  RKPortCheck.h
//  RestKit
//
//  Created by Blake Watters on 5/10/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The RKPortCheck class provides a simple interface for quickly testing
 the availability of a listening TCP port on a remote host by IP Address or
 Hostname.
 */
@interface RKPortCheck : NSObject

///-----------------------------------------------------------------------------
/// @name Creating a Port Check
///-----------------------------------------------------------------------------

/**
 Initializes the receiver with a given hostname or IP address as a string
 and a numeric TCP port number.

 @param hostNameOrIPAddress A string containing the hostname or IP address to check.
 @param port The TCP port on the remote host to check for a listening server on.
 @return The receiver, initialized with host and port.
 */
- (id)initWithHost:(NSString *)hostNameOrIPAddress port:(NSUInteger)port;

///-----------------------------------------------------------------------------
/// @name Accessing Host and Port
///-----------------------------------------------------------------------------

/**
 The hostname or IP address the receiver is checking.
 */
@property (nonatomic, retain, readonly) NSString *host;

/**
 The TCP port to check for a listening server on.
 */
@property (nonatomic, assign, readonly) NSUInteger port;

///-----------------------------------------------------------------------------
/// @name Running the Check
///-----------------------------------------------------------------------------

/**
 Runs the check by creating a socket and attempting to connect to the
 target host and port via TCP. The
 */
- (void)run;

///-----------------------------------------------------------------------------
/// @name Inspecting Port Accessibility
///-----------------------------------------------------------------------------

/**
 Returns a Boolean value indicating if the check has been run.

 @return YES if the check has been run, otherwise NO.
 */
- (BOOL)hasRun;

/**
 Returns a Boolean value indicating if the host and port the receiver checked
 is open and listening for incoming connections.

 @return YES if the port on the remote host is open, otherwise NO.
 */
- (BOOL)isOpen;

/**
 Returns a Boolean value indicating if the host and port the receiver checked
 is NOT open and listening for incoming connections.

 @return YES if the port on the remote host is closed, otherwise NO.
 */
- (BOOL)isClosed;

@end
