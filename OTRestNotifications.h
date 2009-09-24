//
//  OTRestNotifications.h
//  OTRestFramework
//
//  Created by Blake Watters on 9/24/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>

/******************
 * Request Auditing
 *
 * OTRestClient exposes a set of NSNotifications that can be
 * used to audit the request/response cycle of your application.
 * This is useful for doing things like generating automatic logging
 * for all your requests or sending the response times 
 */
extern NSString* const kOTRestRequestSentNotification;
extern NSString* const kOTRestResponseReceivedNotification;
