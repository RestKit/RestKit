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

#import <RestKit/Network/RKObjectRequestOperation.h>
#import <RestKit/Network/RKResponseDescriptor.h>
#import <RestKit/Network/RKResponseMapperOperation.h>
#import <RestKit/ObjectMapping/RKHTTPUtilities.h>
#import <RestKit/ObjectMapping/RKMappingErrors.h>
#import <RestKit/Support/RKLog.h>
#import <RestKit/Support/RKMIMETypeSerialization.h>
#import <RestKit/Support/RKOperationStateMachine.h>
#import <objc/runtime.h>

#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#endif

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

#define RKLogIsTrace() (_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))

static BOOL RKLogIsStringBlank(NSString *string)
{
    return ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0);
}

static NSString *RKLogTruncateString(NSString *string)
{
    static NSInteger maxMessageLength;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *envVars = [[NSProcessInfo processInfo] environment];
        maxMessageLength = RKLogIsStringBlank(envVars[@"RKLogMaxLength"]) ? NSIntegerMax : [envVars[@"RKLogMaxLength"] integerValue];
    });
    
    return ([string length] <= maxMessageLength)
    ? string
    : [NSString stringWithFormat:@"%@... (truncated at %ld characters)",
       [string substringToIndex:maxMessageLength],
       (long) maxMessageLength];
}

@interface NSCachedURLResponse (RKLeakFix)

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *rkData;

@end

@interface RKObjectRequestOperationLogger : NSObject

+ (RKObjectRequestOperationLogger*)sharedLogger;

@end

@implementation RKObjectRequestOperationLogger

+ (RKObjectRequestOperationLogger*)sharedLogger
{
    static RKObjectRequestOperationLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)load
{
    @autoreleasepool {
        [self sharedLogger];
    };
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectRequestOperationDidStart:)
                                                     name:RKObjectRequestOperationDidStartNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectRequestOperationDidFinish:)
                                                     name:RKObjectRequestOperationDidFinishNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(HTTPOperationDidStart:)
                                                     name:AFNetworkingOperationDidStartNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(HTTPOperationDidFinish:)
                                                     name:AFNetworkingOperationDidFinishNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

static void *RKParentObjectRequestOperation = &RKParentObjectRequestOperation;
static void *RKOperationStartDate = &RKOperationStartDate;
static void *RKOperationFinishDate = &RKOperationFinishDate;

- (void)objectRequestOperationDidStart:(NSNotification *)notification
{
    // Weakly tag the HTTP operation with its parent object request operation
    RKObjectRequestOperation *objectRequestOperation = [notification object];
    objc_setAssociatedObject(objectRequestOperation, RKOperationStartDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(objectRequestOperation.HTTPRequestOperation, RKParentObjectRequestOperation, objectRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSURLRequest *request = objectRequestOperation.HTTPRequestOperation.request;
    RKLogInfo(@"%@ '%@'", request.HTTPMethod, request.URL.absoluteString);
    RKLogDebug(@"request.headers=%@", request.allHTTPHeaderFields);
    if (request.HTTPBody && RKLogIsTrace()) {
        RKLogTrace(@"request.body=%@", RKLogTruncateString([[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]));
    }
}

- (void)HTTPOperationDidStart:(NSNotification *)notification
{
    objc_setAssociatedObject(notification.object, RKOperationStartDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)HTTPOperationDidFinish:(NSNotification *)notification
{
    objc_setAssociatedObject(notification.object, RKOperationFinishDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)objectRequestOperationDidFinish:(NSNotification *)notification
{
    RKObjectRequestOperation *objectRequestOperation = [notification object];
    if (![objectRequestOperation isKindOfClass:[RKObjectRequestOperation class]]) return;
    
    RKHTTPRequestOperation *HTTPRequestOperation = objectRequestOperation.HTTPRequestOperation;
    NSTimeInterval objectRequestExecutionDuration = [[NSDate date] timeIntervalSinceDate:objc_getAssociatedObject(objectRequestOperation, RKOperationStartDate)];
    NSTimeInterval httpRequestExecutionDuration = [objc_getAssociatedObject(HTTPRequestOperation, RKOperationFinishDate) timeIntervalSinceDate:objc_getAssociatedObject(HTTPRequestOperation, RKOperationStartDate)];
    NSDate *mappingDidStartTime = (notification.userInfo)[RKObjectRequestOperationMappingDidFinishUserInfoKey];
    NSTimeInterval mappingDuration = [mappingDidStartTime isEqual:[NSNull null]] ? 0.0 : [mappingDidStartTime timeIntervalSinceDate:(notification.userInfo)[RKObjectRequestOperationMappingDidStartUserInfoKey]];
    
    NSURLRequest *request = HTTPRequestOperation.request;
    NSHTTPURLResponse *response = HTTPRequestOperation.response;
    NSString *statusCodeString = RKStringFromStatusCode(response.statusCode);
    NSString *statusCodeDescription = statusCodeString ? [NSString stringWithFormat:@" %@ ", statusCodeString] : @" ";
    NSString *elapsedTimeString = [NSString stringWithFormat:@"[request=%.04fs mapping=%.04fs total=%.04fs]", httpRequestExecutionDuration, mappingDuration, objectRequestExecutionDuration];
    NSString *statusCodeAndElapsedTime = [NSString stringWithFormat:@"(%ld%@/ %lu objects) %@", (long)response.statusCode, statusCodeDescription, (unsigned long) [objectRequestOperation.mappingResult count], elapsedTimeString];
    if (objectRequestOperation.error) {
        if (objectRequestOperation.error.code == NSURLErrorCancelled) {
            RKLogDebug(@"%@ '%@' %@: Cancelled", request.HTTPMethod, request.URL.absoluteString, statusCodeAndElapsedTime);
        } else {
            RKLogError(@"%@ '%@' %@: %@", request.HTTPMethod, request.URL.absoluteString, statusCodeAndElapsedTime, objectRequestOperation.error);
        }
    } else {
        RKLogInfo(@"%@ '%@' %@", request.HTTPMethod, request.URL.absoluteString, statusCodeAndElapsedTime);
        RKLogDebug(@"response.headers=%@", response.allHeaderFields);
    }
    if (RKLogIsTrace()) {
        RKLogTrace(@"response.body=%@", RKLogTruncateString(HTTPRequestOperation.responseString));
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

NSString *const RKObjectRequestOperationDidStartNotification = @"RKObjectRequestOperationDidStartNotification";
NSString *const RKObjectRequestOperationDidFinishNotification = @"RKObjectRequestOperationDidFinishNotification";
NSString *const RKResponseHasBeenMappedCacheUserInfoKey = @"RKResponseHasBeenMapped";
NSString *const RKObjectRequestOperationMappingDidStartUserInfoKey = @"mappingStartedAt";
NSString *const RKObjectRequestOperationMappingDidFinishUserInfoKey = @"mappingFinishedAt";

static void RKIncrementNetworkActivityIndicator()
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    #endif
}

static void RKDecrementNetworkAcitivityIndicator()
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    #endif
}

static NSIndexSet *RKAcceptableStatusCodesFromResponseDescriptors(NSArray *responseDescriptors)
{
    // If there are no response descriptors or any descriptor matches any status code (expressed by `statusCodes` == `nil`) then we want to accept anything
    if ([responseDescriptors count] == 0 || [[responseDescriptors valueForKey:@"statusCodes"] containsObject:[NSNull null]]) return nil;
    
    NSMutableIndexSet *acceptableStatusCodes = [NSMutableIndexSet indexSet];
    [responseDescriptors enumerateObjectsUsingBlock:^(RKResponseDescriptor *responseDescriptor, NSUInteger idx, BOOL *stop) {
        [acceptableStatusCodes addIndexes:responseDescriptor.statusCodes];
    }];
    return acceptableStatusCodes;
}

static NSString *RKStringForStateOfObjectRequestOperation(RKObjectRequestOperation *operation)
{
    if ([operation isExecuting]) {
        return @"Executing";
    } else if ([operation isFinished]) {
        if (operation.error) {
            return @"Failed";
        } else {
            return @"Successful";
        }
    } else {
        return @"Ready";
    }
}

static NSString *RKStringDescribingURLResponseWithData(NSURLResponse *response, NSData *data)
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        return [NSString stringWithFormat:@"<%@: %p statusCode=%ld MIMEType=%@ length=%ld>", [response class], response, (long) [HTTPResponse statusCode], [HTTPResponse MIMEType], (long) [data length]];
    } else {
        return [response description];
    }
}

@interface RKObjectRequestOperation ()
@property (nonatomic, strong) RKOperationStateMachine *stateMachine;
@property (nonatomic, strong, readwrite) RKHTTPRequestOperation *HTTPRequestOperation;
@property (nonatomic, strong, readwrite) NSArray *responseDescriptors;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong) RKObjectResponseMapperOperation *responseMapperOperation;
@property (nonatomic, copy) id (^willMapDeserializedResponseBlock)(id deserializedResponseBody);
@property (nonatomic, strong) NSDate *mappingDidStartDate;
@property (nonatomic, strong) NSDate *mappingDidFinishDate;
@property (nonatomic, copy) void (^successBlock)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult);
@property (nonatomic, copy) void (^failureBlock)(RKObjectRequestOperation *operation, NSError *error);
@end

@implementation RKObjectRequestOperation

+ (NSOperationQueue *)responseMappingQueue
{
    static NSOperationQueue *responseMappingQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        responseMappingQueue = [NSOperationQueue new];
        [responseMappingQueue setName:@"RKObjectRequestOperation Response Mapping Queue" ];
        [responseMappingQueue setMaxConcurrentOperationCount:1];
    });
    
    return responseMappingQueue;
}

+ (dispatch_queue_t)dispatchQueue
{
    static dispatch_queue_t dispatchQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatchQueue = dispatch_queue_create("org.restkit.network.object-request-operation-queue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return dispatchQueue;
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request
{
    return YES;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    if (_failureCallbackQueue) dispatch_release(_failureCallbackQueue);
    if (_successCallbackQueue) dispatch_release(_successCallbackQueue);
#endif
    _failureCallbackQueue = NULL;
    _successCallbackQueue = NULL;
}

// Designated initializer
- (instancetype)initWithHTTPRequestOperation:(RKHTTPRequestOperation *)requestOperation responseDescriptors:(NSArray *)responseDescriptors
{
    NSParameterAssert(requestOperation);
    NSParameterAssert(responseDescriptors);
    
    self = [self init];
    if (self) {
        self.responseDescriptors = responseDescriptors;
        self.HTTPRequestOperation = requestOperation;
        self.HTTPRequestOperation.acceptableContentTypes = [RKMIMETypeSerialization registeredMIMETypes];
        self.HTTPRequestOperation.acceptableStatusCodes = RKAcceptableStatusCodesFromResponseDescriptors(responseDescriptors);
        self.HTTPRequestOperation.successCallbackQueue = [[self class] dispatchQueue];
        self.HTTPRequestOperation.failureCallbackQueue = [[self class] dispatchQueue];
        
        __weak __typeof(self)weakSelf = self;
        self.stateMachine = [[RKOperationStateMachine alloc] initWithOperation:self dispatchQueue:[[self class] dispatchQueue]];
        [self.stateMachine setExecutionBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectRequestOperationDidStartNotification object:weakSelf];
            RKIncrementNetworkActivityIndicator();
            if (weakSelf.isCancelled) {
                [weakSelf.stateMachine finish];
            } else {
                [weakSelf execute];
            }
        }];
        [self.stateMachine setFinalizationBlock:^{
            [weakSelf willFinish];
            RKDecrementNetworkAcitivityIndicator();
            [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectRequestOperationDidFinishNotification object:weakSelf userInfo:@{ RKObjectRequestOperationMappingDidStartUserInfoKey: weakSelf.mappingDidStartDate ?: [NSNull null], RKObjectRequestOperationMappingDidFinishUserInfoKey: weakSelf.mappingDidFinishDate ?: [NSNull null] }];
        }];
        [self.stateMachine setCancellationBlock:^{
            [weakSelf.HTTPRequestOperation cancel];
            [weakSelf.responseMapperOperation cancel];
        }];
    }
    
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request responseDescriptors:(NSArray *)responseDescriptors
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

// Adopted fix for "The Deallocation Problem" from AFN
- (void)setCompletionBlock:(void (^)(void))block
{
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __unsafe_unretained id weakSelf = self;
        [super setCompletionBlock:^ {
            block();
            [weakSelf setCompletionBlock:nil];
        }];
    }
}

- (void)setWillMapDeserializedResponseBlock:(id (^)(id))block
{
    if (!block) {
        _willMapDeserializedResponseBlock = nil;
    } else {
        __unsafe_unretained id weakSelf = self;
        _willMapDeserializedResponseBlock = ^id (id deserializedResponse) {
            id result = block(deserializedResponse);
            [weakSelf setWillMapDeserializedResponseBlock:nil];
            return result;
        };
    }
}

- (void)setCompletionBlockWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                              failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
// See above setCompletionBlock:
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

    //Keep blocks for copyWithZone
    self.successBlock = success;
    self.failureBlock = failure;

    self.completionBlock = ^ {
        if ([self isCancelled] && !self.error) {
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKOperationCancelledError userInfo:nil];
        }

        if (self.error) {
            if (failure) {
                dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        } else {
            if (success) {
                dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                    success(self, self.mappingResult);
                });
            }
        }
    };
#pragma clang diagnostic pop
}

- (void)performMappingOnResponseWithCompletionBlock:(void(^)(RKMappingResult *mappingResult, NSError *error))completionBlock
{
    self.responseMapperOperation = [[RKObjectResponseMapperOperation alloc] initWithRequest:self.HTTPRequestOperation.request
                                                                                   response:self.HTTPRequestOperation.response
                                                                                       data:self.HTTPRequestOperation.responseData
                                                                        responseDescriptors:self.responseDescriptors];
    self.responseMapperOperation.targetObject = self.targetObject;
    self.responseMapperOperation.mappingMetadata = self.mappingMetadata;
    self.responseMapperOperation.mapperDelegate = self;
    [self.responseMapperOperation setQueuePriority:[self queuePriority]];
    [self.responseMapperOperation setWillMapDeserializedResponseBlock:self.willMapDeserializedResponseBlock];
    [self.responseMapperOperation setDidFinishMappingBlock:^(RKMappingResult *mappingResult, NSError *error) {
        completionBlock(mappingResult, error);
    }];
    [[RKObjectRequestOperation responseMappingQueue] addOperation:self.responseMapperOperation];
}

- (void)execute
{
    __weak __typeof(self)weakSelf = self;    
    
    [self.HTTPRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (weakSelf.isCancelled) {
            [weakSelf.stateMachine finish];
            return;
        }
        
        weakSelf.mappingDidStartDate = [NSDate date];
        [weakSelf performMappingOnResponseWithCompletionBlock:^(RKMappingResult *mappingResult, NSError *error) {
            if (weakSelf.isCancelled) {
                [weakSelf.stateMachine finish];
                return;
            }                                    
            
            // If there is no mapping result but no error, there was no mapping to be performed,
            // which we do not treat as an error condition
            if (error && !([weakSelf.HTTPRequestOperation.request.HTTPMethod isEqualToString:@"DELETE"] && error.code == RKMappingErrorNotFound)) {
                weakSelf.error = error;
                [weakSelf.stateMachine finish];
                return;
            }
            weakSelf.mappingResult = mappingResult;
            
            if (weakSelf.error) {
                weakSelf.mappingResult = nil;
            } else {
                NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:weakSelf.HTTPRequestOperation.request];
                if (cachedResponse) {
                    // We're all done mapping this request. Now we set a flag on the cache entry's userInfo dictionary to indicate that the request
                    // corresponding to the cache entry completed successfully, and we can reliably skip mapping if a subsequent request results
                    // in the use of this cachedResponse.
                    NSMutableDictionary *userInfo = cachedResponse.userInfo ? [cachedResponse.userInfo mutableCopy] : [NSMutableDictionary dictionary];
                    userInfo[RKResponseHasBeenMappedCacheUserInfoKey] = @YES;
                    NSCachedURLResponse *newCachedResponse = [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.rkData userInfo:userInfo storagePolicy:cachedResponse.storagePolicy];
                    [[NSURLCache sharedURLCache] storeCachedResponse:newCachedResponse forRequest:weakSelf.HTTPRequestOperation.request];
                }
            }
            
            weakSelf.mappingDidFinishDate = [NSDate date];
            [weakSelf.stateMachine finish];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        RKLogError(@"Object request failed: Underlying HTTP request operation failed with error: %@", weakSelf.HTTPRequestOperation.error);
        weakSelf.error = weakSelf.HTTPRequestOperation.error;
        [weakSelf.stateMachine finish];
    }];
    
    // Send the request
    [self.HTTPRequestOperation start];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, state: %@, isCancelled=%@, request: %@, response: %@>",
            NSStringFromClass([self class]), self, RKStringForStateOfObjectRequestOperation(self), [self isCancelled] ? @"YES" : @"NO",
            self.HTTPRequestOperation.request, RKStringDescribingURLResponseWithData(self.HTTPRequestOperation.response, self.HTTPRequestOperation.responseData)];
}

- (void)willFinish
{
    // Default implementation does nothing
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    RKObjectRequestOperation *operation = [(RKObjectRequestOperation *)[[self class] allocWithZone:zone] initWithHTTPRequestOperation:[self.HTTPRequestOperation copyWithZone:zone] responseDescriptors:self.responseDescriptors];
    operation.targetObject = self.targetObject;
    operation.mappingMetadata = self.mappingMetadata;
    operation.successCallbackQueue = self.successCallbackQueue;
    operation.failureCallbackQueue = self.failureCallbackQueue;
    operation.willMapDeserializedResponseBlock = self.willMapDeserializedResponseBlock;
    [operation setCompletionBlockWithSuccess:self.successBlock failure:self.failureBlock];

    return operation;
}

#pragma mark - NSOperation

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isReady
{
    return [self.stateMachine isReady] && [super isReady];
}

- (BOOL)isExecuting
{
    return [self.stateMachine isExecuting];
}

- (BOOL)isFinished
{
    return [self.stateMachine isFinished];
}

- (void)start
{
    [self.stateMachine start];
}

- (void)cancel
{
    [super cancel];
    [self.stateMachine cancel];
}

@end

#pragma mark - Fix for leak in iOS 5/6 "- [NSCachedURLResponse data]" message

@implementation NSCachedURLResponse (RKLeakFix)

- (NSData *)rkData
{
    @synchronized(self) {
        NSData *result;
        CFIndex count;
        
        @autoreleasepool {
            result = [self data];
            count = CFGetRetainCount((__bridge CFTypeRef)result);
        }
        
        if (CFGetRetainCount((__bridge CFTypeRef)result) == count) {
#ifndef __clang_analyzer__
            CFRelease((__bridge CFTypeRef)result); // Leak detected, manually release
#endif
        }
        
        return result;
    }
}

@end
