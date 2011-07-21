//
//  Errors.h
//  RestKit
//
//  Created by Blake Watters on 3/25/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

// The error domain for RestKit generated errors
extern NSString* const RKRestKitErrorDomain;

extern NSString* const RKObjectMapperErrorObjectsKey;

typedef enum {
	RKObjectLoaderRemoteSystemError             =   1,
	RKRequestBaseURLOfflineError                =   2,
    RKRequestUnexpectedResponseError            =   3,
    RKObjectLoaderUnexpectedResponseError       =   4
} RKRestKitError;
