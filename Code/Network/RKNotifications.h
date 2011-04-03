//
//  RKNotifications.h
//  RestKit
//
//  Created by Blake Watters on 9/24/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

/******************
 * Request Auditing
 *
 * RKClient exposes a set of NSNotifications that can be
 * used to audit the request/response cycle of your application.
 * This is useful for doing things like generating automatic logging
 * for all your requests or sending the response times 
 */
extern NSString* const RKRequestSentNotification;
extern NSString* const RKRequestDidLoadResponseNotification;
extern NSString* const RKResponseReceivedNotification;
extern NSString* const RKRequestFailedWithErrorNotification;