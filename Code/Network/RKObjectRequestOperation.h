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

/**
 `RKObjectRequestOperation` is an `NSOperation` subclass that implements object mapping on the response body of an `NSHTTPResponse` loaded via an `RKHTTPRequestOperation`.
 
 Object request operations are initialized with a fully configured `NSURLRequest` object and an array of `RKResponseDescriptor` objects. `RKObjectRequestOperation` is internally implemented as an aggregate operation that constructs and starts an `RKHTTPRequestOperation` to perform the network access and retrieve the mappable data. If an error occurs during HTTP transport, the object request operation is failed with the transport error. Once response data is loaded for the request, the object request operation creates and starts an `RKObjectResponseMapperOperation` to perform the object mapping on the response body. If the mapping operation fails, then object request operation is failed and the `error` property is set. If mapping is successful, then the `mappingResult` property is set and the operation is finished successfully.
 
 ## Acceptable Content Types and Status Codes
 
 Instances of `RKObjectRequestOperation` determine the acceptability of status codes and content types differently than is typical for `AFNetworking` derived network opertations. The `RKHTTPRequestOperation` (which is a subclass of the AFNetworking `AFHTTPRequestOperation` class) supports the dynamic assigning of acceptable status codes and content types. This facility is utilized during the configuration of the network operation for an object request operation. The set of acceptable content types is determined by consulting the `RKMIMETypeSerialization` via an invocation of `[RKMIMETypeSerialization registeredMIMETypes]`. The `registeredMIMETypes` method returns an `NSSet` containing either `NSString` or `NSRegularExpression` objects that specify the content types for which `RKSerialization` classes have been registered to handle. The set of acceptable status codes is determined by aggregating the value of the `statusCodes` property from all registered `RKResponseDescriptor` objects.
 
 ## Error Mapping
 
 If the HTTP request returned a response in the Client Error (400-499 range) or Server Error (500-599 range) class and an appropriate `RKResponseDescriptor` is provided to perform mapping on the response, then the object mapping result is considered to contain a server returned error. In this case, an `NSError` object is created in the `RKErrorDomain` with an error code of `RKMappingErrorFromMappingResult` and the object request operation is failed. In the event that an a response is returned in an error class and no `RKResponseDescriptor` has been provided to the operation to handle it, then an `NSError` object in the `AFNetworkingErrorDomain` with an error code of `NSURLErrorBadServerResponse` will be returned by the underlying `RKHTTPRequestOperation` indicating that an unexpected status code was returned. 
 
 ## Caching
 
 Instances of `RKObjectRequestOperation` support all the HTTP caching facilities available via the `NSURLConnection` family of API's. For caching to be enabled, the remote web server that the application is communicating with must emit the appropriate `Cache-Control`, `Expires`, and/or `ETag` headers. When the response headers include the appropriate caching information, the shared `NSURLCache` instance will manage responses and transparently add conditional GET support to cachable requests. HTTP caching is a deep topic explored in depth across the web and detailed in RFC 2616: http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html

 The `RKObjectRequestOperation` class also provides support for utilizing the `NSURLCache` to satisfy requests without hitting the network. This support enables applications to display views presenting data retrieved via a cachable `GET` request without revalidating with the server and incurring any overhead. The optimization is controlled via `avoidsNetworkAccess` property. When enabled, the operation will skip the network transport portion of the object request operation and proceed directly to object mapping the cached response data. When the object request operation is an instance of `RKManagedObjectRequestOperation`, the deserialization and mapping portion of the process can be skipped entirely and the operation will fetch the appropriate object directly from Core Data, falling back to network transport once the cache entry has expired. Please refer to the documentation accompanying `RKManagedObjectRequestOperation` for more details.
 
 ## Core Data
 
 `RKObjectRequestOperation` is not able to perform object mapping that targets Core Data destination entities. Please refer to the `RKManagedObjectRequestOperation` subclass for details regarding performing a Core Data object request operation.
 
 @see `RKResponseDescriptor`
 @see `RKHTTPRequestOperation`
 @see `RKMIMETypeSerialization`
 @see `RKManagedObjectRequestOperation`
 */
@interface RKObjectRequestOperation : NSOperation

///-----------------------------------------------
/// @name Initializing an Object Request Operation
///-----------------------------------------------

/**
 Initializes an object request operation with a request object and a set of response descriptors.
 
 This is the designated initializer.
 
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
 */
@property (nonatomic, strong, readonly) NSArray *responseDescriptors;

/**
 The target object for the object mapping operation.
 
 @see `[RKObjectResponseMapperOperation targetObject]`
 */
@property (nonatomic, strong) id targetObject;

///----------------------------------
/// @name Accessing Operation Results
///----------------------------------

/**
 The mapping result returned by the underlying `RKObjectResponseMapperOperation`.
 
 This property is `nil` if the operation is failed due to a network transport error.
 */
@property (nonatomic, strong, readonly) RKMappingResult *mappingResult;

/**
 The error, if any, that occurred during execution of the operation.
 
 Errors may originate during the network transport or object mapping phases of the object request operation. A `nil` error value indicates that the operation completed successfully.
 */
@property (nonatomic, strong, readonly) NSError *error;

///-----------------------------------
/// @name Accessing Network Properties
///-----------------------------------

/**
 The request object used by the underlying `RKHTTPRequestOperation` network operation.
 */
@property (nonatomic, strong, readonly) NSURLRequest *request;

/**
 The response object loaded by the underlying `RKHTTPRequestOperation` network operation.
 */
@property (nonatomic, readonly) NSHTTPURLResponse *response;

/**
 The response data loaded by the underlying `RKHTTRequestOperation` network operation.
 
 Object mapping is performed on the deserialized `responseData`.
 */
@property (nonatomic, readonly) NSData *responseData;

/**
 When `YES`, network access is avoided entirely if a valid, non-expired cache entry is available for the request being loaded. No conditional GET request is sent to the server and the cache entry is assumed to be fresh. This optimization enables the object mapping to begin immediately using the cached response data. In high latency environments, this can result in an improved user experience as the operation does not wait for a 304 (Not Modified) response to be returned before proceeding with mapping.
 
 This optimization has even greater impact when the object request operation is an instance of `RKManagedObjectRequestOperation` as object mapping can skipped entirely and the objects loaded directly from Core Data. Please refer to the documentation accompanying `RKManagedObjectRequestOperation`.
 
 **Default**: Dependent on the `cachePolicy` of the `NSURLRequest` used to initialize the operation. `YES` unless the request has a `cachePolicy` value equal to `NSURLRequestReloadIgnoringLocalCacheData` or `NSURLRequestReloadIgnoringLocalAndRemoteCacheData`.

 @see `RKManagedObjectRequestOperation`
 */
@property (nonatomic, assign) BOOL avoidsNetworkAccess;

/**
 Returns `YES` if the value of the `response` and `responseData` was loaded from `NSURLCache`, else `NO`.
 */
@property (nonatomic, readonly) BOOL isResponseFromCache;

///-------------------------------------------------------
/// @name Setting the Completion Block and Callback Queues
///-------------------------------------------------------

/**
 Sets the `completionBlock` property with a block that executes either the specified success or failure block, depending on the state of the request on completion. If `error` returns a value, which can be caused by an unacceptable status code or content type, then `failure` is executed. Otherwise, `success` is executed.

 @param success The block to be executed on the completion of a successful operation. This block has no return value and takes two arguments: the receiver operation and the mapping result from object mapping the response data of the request.
 @param failure The block to be executed on the completion of an unsuccessful operation. This block has no return value and takes two arguments: the receiver operation and the error that occurred during the execution of the operation.

 @discussion This method should be overridden in subclasses in order to specify the response object passed into the success block.
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

// Things to consider:
//  - (void)willMapObject:(id* inout)object | willMapResponseObject:
// mapperDelegate
// TODO: Add a Boolean to enable the network if possible
// TODO: Need tests for: success, request failure, request timeout, parsing failure, no matching mapping descriptors, parsing an error out of the payload,
// no mappable content found, unable to parse the MIME type returned, handling a 204 response, getting back a 200 with 'blank' content (i.e. render :nothing => true)
@end
