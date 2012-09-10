//
//  RKObjectRequestOperation.h
//  GateGuru
//
//  Created by Blake Watters on 8/9/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
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
 
 **Default**: `YES`
 */
@property (nonatomic, assign) BOOL avoidsNetworkAccess;

/**
 */
@property (nonatomic, readonly) BOOL isResponseFromCache;

/**
 The callback dispatch queue on success. If `NULL` (default), the main queue is used.
 
 The queue is retained while this operation is living
 */
@property (nonatomic) dispatch_queue_t successCallbackQueue;

/**
 The callback dispatch queue on failure. If `NULL` (default), the main queue is used.
 
 The queue is retained while this operation is living
 */
@property (nonatomic) dispatch_queue_t failureCallbackQueue;

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
