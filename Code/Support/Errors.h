//
//  Errors.h
//  RestKit
//
//  Created by Blake Watters on 3/25/10.
//
//

// The error domain for RestKit generated errors
extern NSString* const RKRestKitErrorDomain;

typedef enum {
	RKObjectLoaderRemoteSystemError = 1,
	RKRequestBaseURLOfflineError
} RKRestKitError;
