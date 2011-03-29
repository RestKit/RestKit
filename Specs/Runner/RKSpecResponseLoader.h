//
//  RKSpecResponseLoader.h
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectLoader.h"

@interface RKSpecResponseLoader : NSObject <RKObjectLoaderDelegate> {
	BOOL _awaitingResponse;
	BOOL _success;
    BOOL _wasCancelled;
	RKResponse* _response;
    NSArray* _objects;
	NSError* _failureError;
	NSString* _errorMessage;
	NSTimeInterval _timeout;
}

// The response that was loaded from the web request
@property (nonatomic, readonly) RKResponse* response;

// The objects that were loaded (if any)
@property (nonatomic, readonly) NSArray* objects;

// True when the response is success
@property (nonatomic, readonly) BOOL success;

// YES when the request was cancelled
@property (nonatomic, readonly) BOOL wasCancelled;

// The error that was returned from a failure to connect
@property (nonatomic, readonly) NSError* failureError;

// The error message returned by the server
@property (nonatomic, readonly) NSString* errorMessage;

@property (nonatomic, assign)	NSTimeInterval timeout;

// Return a new auto-released loader
+ (RKSpecResponseLoader*)responseLoader;

// Wait for a response to load
- (void)waitForResponse;

@end
