//
//  RKErrors.h
//  RestKit
//
//  Created by Blake Watters on 3/25/10.
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

/** @name Error Domain & Codes */

// The error domain for RestKit generated errors
extern NSString* const RKErrorDomain;

typedef enum {
    RKObjectLoaderRemoteSystemError             =   1,
    RKRequestBaseURLOfflineError                =   2,
    RKRequestUnexpectedResponseError            =   3,
    RKObjectLoaderUnexpectedResponseError       =   4,
    RKRequestConnectionTimeoutError             =   5
} RKRestKitError;

/** @name Error Constants */

/**
 The key RestKit generated errors will appear at within an NSNotification
 indicating an error
 */
extern NSString* const RKErrorNotificationErrorKey;

/**
 When RestKit constructs an NSError object from one or more RKErrorMessage
 (or other object mapped error representations), the userInfo of the NSError
 object will be populated with an array of the underlying error objects.

 These underlying errors can be accessed via RKObjectMapperErrorObjectsKey key.

 @see RKObjectMappingResult
 */
extern NSString* const RKObjectMapperErrorObjectsKey;
