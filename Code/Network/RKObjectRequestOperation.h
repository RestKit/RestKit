//
//  RKObjectRequestOperation.h
//  GateGuru
//
//  Created by Blake Watters on 8/9/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import "AFNetworking.h"
#import "RKHTTPRequestOperation.h"
#import "RKMappingResult.h"

@interface RKObjectRequestOperation : NSOperation

- (id)initWithHTTPRequestOperation:(RKHTTPRequestOperation *)requestOperation responseDescriptors:(NSArray *)responseDescriptors;

@property (nonatomic, strong) id targetObject;
@property (readonly, nonatomic, strong) NSArray *responseDescriptors;
@property (readonly, nonatomic, strong) RKHTTPRequestOperation *requestOperation;
@property (readonly, nonatomic, strong) RKMappingResult *mappingResult;
@property (readonly, nonatomic, strong) NSError *error;

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

///-----------------------------------------------------------------------------
/// @name Setting the Completion Block
///-----------------------------------------------------------------------------

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
