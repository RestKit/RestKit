//
//  RKNotifications.h
//  RestKit
//
//  Created by Blake Watters on 9/24/09.
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

/**
 Request Auditing

 RKClient exposes a set of NSNotifications that can be used to audit the
 request/response cycle of your application. This is useful for doing things
 like generating automatic logging for all your requests or sending the response
 times.
 */
extern NSString * const RKRequestSentNotification;
extern NSString * const RKRequestDidLoadResponseNotification;
extern NSString * const RKRequestDidLoadResponseNotificationUserInfoResponseKey;
extern NSString * const RKRequestDidFailWithErrorNotification;
extern NSString * const RKRequestDidFailWithErrorNotificationUserInfoErrorKey;
extern NSString * const RKRequestDidFinishLoadingNotification;
extern NSString * const RKServiceDidBecomeUnavailableNotification;
