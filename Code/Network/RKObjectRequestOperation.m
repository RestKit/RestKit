//
//  RKObjectRequestOperation.m
//  GateGuru
//
//  Created by Blake Watters on 8/9/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import "RKObjectRequestOperation.h"
#import "RKResponseMapperOperation.h"

@interface RKObjectRequestOperation ()
@property (readwrite, nonatomic, strong) RKHTTPRequestOperation *requestOperation;
@property (readwrite, nonatomic, strong) NSArray *responseDescriptors;
@property (readwrite, nonatomic, strong) RKMappingResult *mappingResult;
@property (readwrite, nonatomic, strong) NSError *error;
@end

@implementation RKObjectRequestOperation
- (void)dealloc {
  if(_failureCallbackQueue) {
    dispatch_release(_failureCallbackQueue);
  }
  if(_successCallbackQueue) {
    dispatch_release(_successCallbackQueue);
  }
}

- (id)initWithHTTPRequestOperation:(RKHTTPRequestOperation *)requestOperation responseDescriptors:(NSArray *)responseDescriptors
{
    self = [super init];
    if (self) {
        self.requestOperation = requestOperation;
        self.responseDescriptors = responseDescriptors;
    }

    return self;
}

- (void)setSuccessCallbackQueue:(dispatch_queue_t)successCallbackQueue
{
   if (successCallbackQueue != _successCallbackQueue) {
       if (_successCallbackQueue) {
           dispatch_release(_successCallbackQueue);
           _successCallbackQueue = NULL;
       }

       if (successCallbackQueue) {
           dispatch_retain(successCallbackQueue);
           _successCallbackQueue = successCallbackQueue;
       }
   }
}

- (void)setFailureCallbackQueue:(dispatch_queue_t)failureCallbackQueue
{
   if (failureCallbackQueue != _failureCallbackQueue) {
       if (_failureCallbackQueue) {
           dispatch_release(_failureCallbackQueue);
           _failureCallbackQueue = NULL;
       }

       if (failureCallbackQueue) {
           dispatch_retain(failureCallbackQueue);
           _failureCallbackQueue = failureCallbackQueue;
       }
   }
}

- (void)setCompletionBlockWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                              failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    __block RKObjectRequestOperation *_blockSelf = self;
    self.completionBlock = ^ {
        if ([_blockSelf isCancelled]) {
            return;
        }

        if (_blockSelf.error) {
            if (failure) {
                dispatch_async(_blockSelf.failureCallbackQueue ? _blockSelf.failureCallbackQueue : dispatch_get_main_queue(), ^{
                    failure(_blockSelf, _blockSelf.error);
                });
            }
        } else {
            if (success) {
                dispatch_async(self.successCallbackQueue ? _blockSelf.successCallbackQueue : dispatch_get_main_queue(), ^{
                    success(_blockSelf, _blockSelf.mappingResult);
                });
            }
        }
    };
}

- (RKMappingResult *)performMappingOnResponse:(NSError **)error
{
    // Spin up an RKObjectResponseMapperOperation
    RKObjectResponseMapperOperation *mapperOperation = [[RKObjectResponseMapperOperation alloc] initWithResponse:self.requestOperation.response
                                                                                                            data:self.requestOperation.responseData
                                                                                              responseDescriptors:self.responseDescriptors];
    mapperOperation.targetObject = self.targetObject;
    [mapperOperation start];
    [mapperOperation waitUntilFinished];
    if (mapperOperation.error) *error = mapperOperation.error;
    return mapperOperation.mappingResult;
}

- (void)willFinish
{
    // Default implementation does nothing
}

- (void)main
{
    // Send the request
    [self.requestOperation start];
    [self.requestOperation waitUntilFinished];
    if (self.isCancelled) return;

    if (self.requestOperation.error) {
        RKLogError(@"Object request failed: Underlying HTTP request operation failed with error: %@", self.requestOperation.error);
        self.error = self.requestOperation.error;
        return;
    }

    // Map the response
    NSError *error;
    RKMappingResult *mappingResult = [self performMappingOnResponse:&error];
    if (self.isCancelled) return;
    if (! mappingResult) {
        self.error = error;
        return;
    }
    self.mappingResult = mappingResult;
    [self willFinish];
}

@end
