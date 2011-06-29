//
//  RKNotifications.m
//  RestKit
//
//  Created by Blake Watters on 9/24/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKNotifications.h"

NSString* const RKRequestSentNotification = @"RKRequestSentNotification";
NSString* const RKRequestDidFailWithErrorNotification = @"RKRequestDidFailWithErrorNotification";
NSString* const RKRequestDidFailWithErrorNotificationUserInfoErrorKey = @"error";
NSString* const RKRequestDidLoadResponseNotification = @"RKRequestDidLoadResponseNotification";
NSString* const RKRequestDidLoadResponseNotificationUserInfoResponseKey = @"response";
NSString* const RKServiceDidBecomeUnavailableNotification = @"RKServiceDidBecomeUnavailableNotification";