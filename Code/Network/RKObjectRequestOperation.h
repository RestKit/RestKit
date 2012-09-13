//
//  RKObjectRequestOperation.h
//  RestKit
//
//  Created by Blake Watters on 8/9/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKHTTPRequestOperation.h"
#import "RKMappingResult.h"

// Add docs about cacheing behaviors...
@interface RKObjectRequestOperation : NSOperation

- (id)initWithRequest:(NSURLRequest *)request responseDescriptors:(NSArray *)responseDescriptors;

@property (nonatomic, strong) id targetObject;

@property (nonatomic, strong, readonly) NSArray *responseDescriptors;
@property (nonatomic, strong, readonly) RKMappingResult *mappingResult;

@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, strong, readonly) NSURLRequest *request;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSData *responseData;

/**
 When `YES`, network access is avoided entirely if a valid, non-expired cache entry is available for the request being loaded. No conditional GET request is sent to the server and the cache entry is assumed to be fresh. This optimization enables the object mapping to begin immediately using the cached response data. In high latency environments, this can result in an improved user experience as the operation does not wait for a 304 (Not Modified) response to be returned before proceeding with mapping.
 
 This optimization has even greater impact when the object request operation is an instance of `RKManagedObjectRequestOperation` as object mapping can skipped entirely and the objects loaded directly from Core Data.
 
 **Default**: Dependent on the `cachePolicy` of the `NSURLRequest` used to initialize the operation. `YES` unless the request has a `cachePolicy` value equal to `NSURLRequestReloadIgnoringLocalCacheData` or `NSURLRequestReloadIgnoringLocalAndRemoteCacheData`.
 */
@property (nonatomic, assign) BOOL avoidsNetworkAccess;

/**
 */
@property (nonatomic, readonly) BOOL isResponseFromCache;

/**
 The callback dispatch queue on success. If `NULL` (default), the main queue is used.
 
 The queue is retained while this operation is living
 */
@property (nonatomic, assign) dispatch_queue_t successCallbackQueue;

/**
 The callback dispatch queue on failure. If `NULL` (default), the main queue is used.
 
 The queue is retained while this operation is living
 */
@property (nonatomic, assign) dispatch_queue_t failureCallbackQueue;

// TODO: Add a Boolean to enable the network if possible

///-----------------------------------
/// @name Setting the Completion Block
///-----------------------------------

- (void)setCompletionBlockWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                              failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

// Things to consider:
//  - (void)willMapObject:(id* inout)object | willMapResponseObject:
// mapperDelegate

// Subclass Overrides
- (RKMappingResult *)performMappingOnResponse:(NSError **)error;
- (void)willFinish;

// TODO: Need tests for: success, request failure, request timeout, parsing failure, no matching mapping descriptors, parsing an error out of the payload,
// no mappable content found, unable to parse the MIME type returned, handling a 204 response, getting back a 200 with 'blank' content (i.e. render :nothing => true)
@end
