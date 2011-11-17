//
//  RKError.h
//  RestKit
//
//  Created by Blake Watters on 3/25/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

/** @name Error Domain & Codes */

// The error domain for RestKit generated errors
extern NSString* const RKErrorDomain;

typedef enum {
	RKObjectLoaderRemoteSystemError             =   1,
	RKRequestBaseURLOfflineError                =   2,
    RKRequestUnexpectedResponseError            =   3,
    RKObjectLoaderUnexpectedResponseError       =   4
} RKErrorCode;

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
