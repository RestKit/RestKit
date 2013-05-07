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
#import "RKMapperOperation.h"

/**
 The key for a Boolean NSNumber value that indicates if a `NSCachedURLResponse` stored in the `NSURLCache` has been object mapped to completion. This key is stored on the `userInfo` of the cached response, if any, just before an `RKObjectRequestOperation` transitions to the finished state.
 */
extern NSString * const RKResponseHasBeenMappedCacheUserInfoKey;

/**
 `RKObjectRequestOperation` is an `NSOperation` subclass that implements object mapping on the response body of an `NSHTTPResponse` loaded via an `RKHTTPRequestOperation`.
 
 Object request operations are initialized with a fully configured `NSURLRequest` object and an array of `RKResponseDescriptor` objects. `RKObjectRequestOperation` is internally implemented as an aggregate operation that constructs and starts an `RKHTTPRequestOperation` to perform the network access and retrieve the mappable data. If an error occurs during HTTP transport, the object request operation is failed with the transport error. Once response data is loaded for the request, the object request operation creates and starts an `RKObjectResponseMapperOperation` to perform the object mapping on the response body. If the mapping operation fails, then object request operation is failed and the `error` property is set. If mapping is successful, then the `mappingResult` property is set and the operation is finished successfully.
 
 ## Acceptable Content Types and Status Codes
 
 Instances of `RKObjectRequestOperation` determine the acceptability of status codes and content types differently than is typical for `AFNetworking` derived network opertations. The `RKHTTPRequestOperation` (which is a subclass of the AFNetworking `AFHTTPRequestOperation` class) supports the dynamic assignment of acceptable status codes and content types. This facility is utilized during the configuration of the network operation for an object request operation. The set of acceptable content types is determined by consulting the `RKMIMETypeSerialization` via an invocation of `[RKMIMETypeSerialization registeredMIMETypes]`. The `registeredMIMETypes` method returns an `NSSet` containing either `NSString` or `NSRegularExpression` objects that specify the content types for which `RKSerialization` classes have been registered to handle. The set of acceptable status codes is determined by aggregating the value of the `statusCodes` property from all registered `RKResponseDescriptor` objects.
 
 ## Error Mapping
 
 If the HTTP request returned a response in the Client Error (400-499 range) or Server Error (500-599 range) class and an appropriate `RKResponseDescriptor` is provided to perform mapping on the response, then the object mapping result is considered to contain a server returned error. In this case, an `NSError` object is created in the `RKErrorDomain` with an error code of `RKMappingErrorFromMappingResult` and the object request operation is failed. In the event that an a response is returned in an error class and no `RKResponseDescriptor` has been provided to the operation to handle it, then an `NSError` object in the `AFNetworkingErrorDomain` with an error code of `NSURLErrorBadServerResponse` will be returned by the underlying `RKHTTPRequestOperation` indicating that an unexpected status code was returned. 
 
 ## Metadata Mapping

 The `RKObjectRequestOperation` class provides support for metadata mapping via the `mappingMetadata` property. This optional dictionary of user supplied information is made available to the mapping operations executed when processing the HTTP response loaded by an object request operation. More details about the metadata mapping architecture is available on the `RKMappingOperation` documentation.

 ## Prioritization and Cancellation
 
 Object request operations support prioritization and cancellation of the underlying `RKHTTPRequestOperation` and `RKResponseMapperOperation` operations that perform the network transport and object mapping duties on their behalf. The queue priority of the object request operation, as set via the `[NSOperation setQueuePriority:]` method, is applied to the underlying response mapping operation when it is enqueued onto the `responseMappingQueue`. If the object request operation is cancelled, then the underlying HTTP request operation and response mapping operation are also cancelled.
 
 ## Caching
 
 Instances of `RKObjectRequestOperation` support all the HTTP caching facilities available via the `NSURLConnection` family of API's. For caching to be enabled, the remote web server that the application is communicating with must emit the appropriate `Cache-Control`, `Expires`, and/or `ETag` headers. When the response headers include the appropriate caching information, the shared `NSURLCache` instance will manage responses and transparently add conditional GET support to cachable requests. HTTP caching is a deep topic explored in depth across the web and detailed in RFC 2616: http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html

 The `RKObjectRequestOperation` class also provides support for utilizing the `NSURLCache` to satisfy requests without hitting the network. This support enables applications to display views presenting data retrieved via a cachable `GET` request without revalidating with the server and incurring any overhead. The optimization is controlled via `avoidsNetworkAccess` property. When enabled, the operation will skip the network transport portion of the object request operation and proceed directly to object mapping the cached response data. When the object request operation is an instance of `RKManagedObjectRequestOperation`, the deserialization and mapping portion of the process can be skipped entirely and the operation will fetch the appropriate object directly from Core Data, falling back to network transport once the cache entry has expired. Please refer to the documentation accompanying `RKManagedObjectRequestOperation` for more details.
 
 ## Core Data
 
 `RKObjectRequestOperation` is not able to perform object mapping that targets Core Data destination entities. Please refer to the `RKManagedObjectRequestOperation` subclass for details regarding performing a Core Data object request operation.
 
 ## Subclassing Notes
 
 The `RKObjectRequestOperation` is a non-current `NSOperation` subclass and can be extended by subclassing and providing an implementation of the `main` method. It conforms to the `RKMapperOperationDelegate` protocol, providing access to the lifecycle of the mapping process to subclasses.
 
 @see `RKResponseDescriptor`
 @see `RKHTTPRequestOperation`
 @see `RKMIMETypeSerialization`
 @see `RKManagedObjectRequestOperation`
 */
@interface RKObjectRequestOperation : NSOperation <NSCopying, RKMapperOperationDelegate> {
  @protected
    RKMappingResult *_mappingResult;
}

///-----------------------------------------------
/// @name Initializing an Object Request Operation
///-----------------------------------------------

/**
 Initializes an object request operation with an HTTP request operation and a set of response descriptors.
 
 This is the designated initializer.
 
 @param request The request object to be used with the underlying network operation.
 @param responseDescriptors An array of `RKResponseDescriptor` objects specifying how object mapping is to be performed on the response loaded by the network operation.
 @return The receiver, initialized with the given request and response descriptors.
 */
- (id)initWithHTTPRequestOperation:(RKHTTPRequestOperation *)requestOperation responseDescriptors:(NSArray *)responseDescriptors;

/**
 Initializes an object request operation with a request object and a set of response descriptors.
 
 This method is a convenience initializer for initializing an object request operation from a URL request with the default HTTP operation class `RKHTTPRequestOperation`. This method is functionally equivalent to the following example code:
 
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithHTTPRequestOperation:requestOperation responseDescriptors:responseDescriptors];
 
 @param request The request object to be used with the underlying network operation.
 @param responseDescriptors An array of `RKResponseDescriptor` objects specifying how object mapping is to be performed on the response loaded by the network operation.
 @return The receiver, initialized with the given request and response descriptors.
 */
- (id)initWithRequest:(NSURLRequest *)request responseDescriptors:(NSArray *)responseDescriptors;

///---------------------------------
/// @name Configuring Object Mapping
///---------------------------------

/**
 The array of `RKResponseDescriptor` objects that specify how the deserialized `responseData` is to be object mapped.
 
 The response descriptors define the acceptable HTTP Status Codes of the receiver.
 */
@property (nonatomic, strong, readonly) NSArray *responseDescriptors;

/**
 The target object for the object mapping operation.
 
 @see `[RKObjectResponseMapperOperation targetObject]`
 */
@property (nonatomic, strong) id targetObject;

/**
 An optional dictionary of metadata to make available to mapping operations executed while processing the HTTP response loaded by the receiver.
 */
@property (nonatomic, copy) NSDictionary *mappingMetadata;

///----------------------------------
/// @name Accessing Operation Results
///----------------------------------

/**
 The mapping result returned by the underlying `RKObjectResponseMapperOperation`.
 
 This property is `nil` if the operation is failed due to a network transport error or no mapping was peformed on the response.
 */
@property (nonatomic, strong, readonly) RKMappingResult *mappingResult;

/**
 The error, if any, that occurred during execution of the operation.
 
 Errors may originate during the network transport or object mapping phases of the object request operation. A `nil` error value indicates that the operation completed successfully.
 */
@property (nonatomic, strong, readonly) NSError *error;

///-------------------------------------------
/// @name Accessing the HTTP Request Operation
///-------------------------------------------

/**
 The underlying `RKHTTPRequestOperation` object used to manage the HTTP request/response lifecycle of the object request operation.
 */
@property (nonatomic, strong, readonly) RKHTTPRequestOperation *HTTPRequestOperation;

///-------------------------------------------------------
/// @name Setting the Completion Block and Callback Queues
///-------------------------------------------------------

/**
 Sets the `completionBlock` property with a block that executes either the specified success or failure block, depending on the state of the object request on completion. If `error` returns a value, which can be set during HTTP transport by the underlying `HTTPRequestOperation` or during object mapping by the `RKResponseMapperOperation` object, then `failure` is executed. If the object request operation is cancelled, then neither success nor failure will be executed. Otherwise, `success` is executed.

 @param success The block to be executed on the completion of a successful operation. This block has no return value and takes two arguments: the receiver operation and the mapping result from object mapping the response data of the request.
 @param failure The block to be executed on the completion of an unsuccessful operation. This block has no return value and takes two arguments: the receiver operation and the error that occurred during the execution of the operation.
 */
- (void)setCompletionBlockWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                              failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

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

/**
 Sets a block to be executed before the object request operation begins mapping the deserialized response body, providing an opportunity to manipulate the mappable representation input that will be passed to the response mapper.
 
 @param block A block object to be executed before the deserialized response is passed to the response mapper. The block has an `id` return type and must return a dictionary or array of dictionaries corresponding to the object representations that are to be mapped. The block accepts a single argument: the deserialized response data that was loaded via HTTP. If you do not wish to make any chances to the response body before mapping begins, the block should return the value passed in the `deserializedResponseBody` block argument. Returning `nil` will decline the mapping from proceeding and fail the operation with an error with the `RKMappingErrorMappingDeclined` code.
 @see [RKResponseMapperOperation setWillMapDeserializedResponseBlock:]
 @warning The deserialized response body may or may not be immutable depending on the implementation details of the `RKSerialization` class that deserialized the response. If you wish to make changes to the mappable object representations, you must obtain a mutable copy of the response body input.
 */
- (void)setWillMapDeserializedResponseBlock:(id (^)(id deserializedResponseBody))block;

///-----------------------------------------------------
/// @name Determining Whether a Request Can Be Processed
///-----------------------------------------------------

/**
 Returns a Boolean value determining whether or not the class can process the specified request.
 
 @param request The request that is determined to be supported or not supported for this class.
 */
+ (BOOL)canProcessRequest:(NSURLRequest *)request;

///-------------------------------------------
/// @name Accessing the Response Mapping Queue
///-------------------------------------------

/**
 Returns the operation queue used by all object request operations when object mapping the body of a response loaded via HTTP.
 
 By default, the response mapping queue is configured with a maximum concurrent operation count of 1, ensuring that only one HTTP response is mapped at a time.
 
 @return The response mapping queue.
 */
+ (NSOperationQueue *)responseMappingQueue;

@end

///--------------------
/// @name Notifications
///--------------------

/**
 Posted when an object request operation begin executing.
 */
extern NSString *const RKObjectRequestOperationDidStartNotification;

/**
 Posted when an object request operation finishes.
 */
extern NSString *const RKObjectRequestOperationDidFinishNotification;

/**
 The key for an `NSDate` object specifying the time at which object mapping started for object request operation. Available in the user info dictionary of an `RKObjectRequestOperationDidFinishNotification`
 */
extern NSString *const RKObjectRequestOperationMappingDidStartUserInfoKey;

/**
 The key for an `NSDate` object specifying the time at which object mapping finished for object request operation. Available in the user info dictionary of an `RKObjectRequestOperationDidFinishNotification`
 */
extern NSString *const RKObjectRequestOperationMappingDidFinishUserInfoKey;
