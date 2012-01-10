//
//  RKSpecResponseLoader.h
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters
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
#import "RKObjectLoader.h"

@interface RKSpecResponseLoader : NSObject <RKObjectLoaderDelegate, RKOAuthClientDelegate> {
	BOOL _awaitingResponse;
	BOOL _success;
    BOOL _wasCancelled;
    BOOL _unknownResponse;
	RKResponse* _response;
    NSArray* _objects;
	NSError* _failureError;
	NSTimeInterval _timeout;
}

// The response that was loaded from the web request
@property (nonatomic, retain, readonly) RKResponse* response;

// The objects that were loaded (if any)
@property (nonatomic, retain, readonly) NSArray* objects;

// True when the response is success
@property (nonatomic, readonly) BOOL success;

// YES when the request was cancelled
@property (nonatomic, readonly) BOOL wasCancelled;

@property (nonatomic, readonly) BOOL unknownResponse;

// The error that was returned from a failure to connect
@property (nonatomic, copy, readonly) NSError* failureError;

// The error message returned by the server
@property (nonatomic, readonly) NSString* errorMessage;

@property (nonatomic, assign)	NSTimeInterval timeout;

// Return a new auto-released loader
+ (RKSpecResponseLoader*)responseLoader;

// Wait for a response to load
- (void)waitForResponse;

@end
