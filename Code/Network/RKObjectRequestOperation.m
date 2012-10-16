//
//  RKObjectRequestOperation.m
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

#import "RKObjectRequestOperation.h"
#import "RKResponseMapperOperation.h"
#import "RKMIMETypeSerialization.h"
#import "RKHTTPUtilities.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

static inline NSString *RKDescriptionForRequest(NSURLRequest *request)
{
    return [NSString stringWithFormat:@"%@ '%@'", request.HTTPMethod, [request.URL absoluteString]];
}

static NSIndexSet *RKObjectRequestOperationAcceptableMIMETypes()
{
    static NSMutableIndexSet *statusCodes = nil;
    if (! statusCodes) {
        statusCodes = [NSMutableIndexSet indexSet];
        [statusCodes addIndexesInRange:RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful)];
        [statusCodes addIndexesInRange:RKStatusCodeRangeForClass(RKStatusCodeClassClientError)];
    }
    return statusCodes;
}

@interface RKObjectRequestOperation ()
@property (nonatomic, strong, readwrite) RKHTTPRequestOperation *HTTPRequestOperation;
@property (nonatomic, strong, readwrite) NSArray *responseDescriptors;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong, readwrite) NSError *error;
@end

@implementation RKObjectRequestOperation

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    if(_failureCallbackQueue) dispatch_release(_failureCallbackQueue);
    if(_successCallbackQueue) dispatch_release(_successCallbackQueue);
#endif
}

// Designated initializer
- (id)initWithHTTPRequestOperation:(RKHTTPRequestOperation *)requestOperation responseDescriptors:(NSArray *)responseDescriptors
{
    NSParameterAssert(requestOperation);
    NSParameterAssert(responseDescriptors);
    
    self = [self init];
    if (self) {
        self.responseDescriptors = responseDescriptors;
        self.HTTPRequestOperation = requestOperation;
        self.HTTPRequestOperation.acceptableContentTypes = [RKMIMETypeSerialization registeredMIMETypes];
        self.HTTPRequestOperation.acceptableStatusCodes = RKObjectRequestOperationAcceptableMIMETypes();
    }
    
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request responseDescriptors:(NSArray *)responseDescriptors
{
    NSParameterAssert(request);
    NSParameterAssert(responseDescriptors);    
    return [self initWithHTTPRequestOperation:[[RKHTTPRequestOperation alloc] initWithRequest:request] responseDescriptors:responseDescriptors];
}

- (void)setSuccessCallbackQueue:(dispatch_queue_t)successCallbackQueue
{
   if (successCallbackQueue != _successCallbackQueue) {
       if (_successCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
           dispatch_release(_successCallbackQueue);
#endif
           _successCallbackQueue = NULL;
       }

       if (successCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
           dispatch_retain(successCallbackQueue);
#endif
           _successCallbackQueue = successCallbackQueue;
       }
   }
}

- (void)setFailureCallbackQueue:(dispatch_queue_t)failureCallbackQueue
{
   if (failureCallbackQueue != _failureCallbackQueue) {
       if (_failureCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
           dispatch_release(_failureCallbackQueue);
#endif
           _failureCallbackQueue = NULL;
       }

       if (failureCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
           dispatch_retain(failureCallbackQueue);
#endif
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
    RKObjectResponseMapperOperation *mapperOperation = [[RKObjectResponseMapperOperation alloc] initWithResponse:self.HTTPRequestOperation.response
                                                                                                            data:self.HTTPRequestOperation.responseData
                                                                                              responseDescriptors:self.responseDescriptors];
    mapperOperation.targetObject = self.targetObject;
    [mapperOperation start];
    [mapperOperation waitUntilFinished];
    if (mapperOperation.error) {
        if (error) *error = mapperOperation.error;
        return nil;
    }
    return mapperOperation.mappingResult;
}

- (void)willFinish
{
    // Default implementation does nothing
}

- (void)cancel
{
    [super cancel];
    [self.HTTPRequestOperation cancel];
}

- (void)main
{
    if (self.isCancelled) return;
    
    // Send the request
    [self.HTTPRequestOperation start];
    [self.HTTPRequestOperation waitUntilFinished];

    if (self.HTTPRequestOperation.error) {
        RKLogError(@"Object request failed: Underlying HTTP request operation failed with error: %@", self.HTTPRequestOperation.error);
        self.error = self.HTTPRequestOperation.error;
        return;
    }
    
    if (self.isCancelled) return;

    // Map the response
    NSError *error;
    RKMappingResult *mappingResult = [self performMappingOnResponse:&error];
    if (self.isCancelled) return;

    // If there is no mapping result but no error, there was no mapping to be performed,
    // which we do not treat as an error condition
    if (! mappingResult && error) {
        self.error = error;
        return;
    }
    self.mappingResult = mappingResult;
    [self willFinish];
}

@end
