//
//  RKObjectRequestOperationManager.h
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"
#import "RKResponseDescriptor.h"
#import "RKRequestDescriptor.h"
#import "RKMappingResult.h"
#import "RKObjectResponseSerializer.h"
#import "RKObjectRequestSerializer.h"

@interface RKObjectRequestOperationManager : NSObject

+ (instancetype)managerWithBaseURL:(NSURL *)baseURL;
- (id)initWithHTTPRequestOperationManager:(AFHTTPRequestOperationManager *)manager;

@property (nonatomic, strong) AFHTTPRequestOperationManager *HTTPRequestOperationManager;
@property (nonatomic, readonly) NSURL *baseURL;

@property (nonatomic, strong) RKObjectRequestSerializer *requestSerializer;
@property (nonatomic, strong) RKObjectResponseSerializer *responseSerializer;

///---------------------------------------
/// @name Managing HTTP Request Operations
///---------------------------------------

/**
 Creates an `AFHTTPRequestOperation`, and sets the response serializers to that of the HTTP client.

 @param request The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

///-------------------------------------
/// @name Making Object Requests by Path
///-------------------------------------

/**
 Creates an `RKObjectRequestOperation` with a `GET` request with a URL for the given path, and enqueues it to the manager's operation queue.

 The type of object request operation created is determined by invoking `appropriateObjectRequestOperationWithObject:method:path:parameters:`.

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)getObjectsAtPath:(NSString *)path
                                  parameters:(NSDictionary *)parameters
                                     success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `GET` request for the relationship with the given name of the given object, and enqueues it to the manager's operation queue.

 The type of object request operation created is determined by invoking `appropriateObjectRequestOperationWithObject:method:path:parameters:`.

 @param relationshipName The name of the relationship being loaded. Used to retrieve the `RKRoute` object from the router for the given object's class and the relationship name. Cannot be nil.
 @param object The object for which related objects are being loaded. Evaluated against the `RKRoute` for the relationship for the object's class with the given name to compute the path. Cannot be nil.
 @param parameters The parameters to be encoded and appended as the query string for the request URL. May be nil.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the mapped result created from object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @raises NSInvalidArgumentException Raised if no route is configured for a relationship of the given object's class with the given name.
 @see [RKRouter URLForRelationship:ofObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)getObjectsAtPathForRelationship:(NSString *)relationshipName
                                                   ofObject:(id)object
                                                 parameters:(NSDictionary *)parameters
                                                    success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `GET` request for the URL returned by the router for the given route name, and enqueues it to the manager's operation queue.

 The type of object request operation created is determined by invoking `appropriateObjectRequestOperationWithObject:method:path:parameters:`.

 @param routeName The name of the route being loaded. Used to retrieve the `RKRoute` object from the router with the given name. Cannot be nil.
 @param object The object to be interpolated against the path pattern of the `RKRoute` object retrieved with the given name. Used to compute the path to be appended to the HTTP client's base URL and used as the request URL. May be nil.
 @param parameters The parameters to be encoded and appended as the query string for the request URL. May be nil.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the mapped result created from object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @raises NSInvalidArgumentException Raised if no route is configured with the given name or the route returned specifies an HTTP method other than `GET`.
 @see [RKRouter URLForRouteNamed:method:object:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)getObjectsAtPathForRouteNamed:(NSString *)routeName
                                                   object:(id)object
                                               parameters:(NSDictionary *)parameters
                                                  success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

///------------------------------------
/// @name Making Requests for an Object
///------------------------------------

/**
 Creates an `RKObjectRequestOperation` with a `GET` request for the given object, and enqueues it to the manager's operation queue.

 The type of object request operation created is determined by invoking `appropriateObjectRequestOperationWithObject:method:path:parameters:`.

 @param object The object with which to construct the object request operation. If `nil`, then the path must be provided.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKHTTPMethodGET` request method.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)GET:(id)object
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `POST` request for the given object, and enqueues it to the manager's operation queue.

 @param object The object with which to construct the object request operation. If `nil`, then the path must be provided.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKHTTPMethodPOST` method.
 @param parameters The parameters to be reverse merged with the parameterization of the given object and set as the request body.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)POST:(id)object
                       URLString:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `PUT` request for the given object, and enqueues it to the manager's operation queue.

 @param object The object with which to construct the object request operation. If `nil`, then the path must be provided.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKHTTPMethodPUT` method.
 @param parameters The parameters to be reverse merged with the parameterization of the given object and set as the request body.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)PUT:(id)object
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `PATCH` request for the given object, and enqueues it to the manager's operation queue.

 @param object The object with which to construct the object request operation. If `nil`, then the path must be provided.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKHTTPMethodPATCH` method.
 @param parameters The parameters to be reverse merged with the parameterization of the given object and set as the request body.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)PATCH:(id)object
                        URLString:(NSString *)URLString
                       parameters:(NSDictionary *)parameters
                          success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `DELETE` request for the given object, and enqueues it to the manager's operation queue.

 The type of object request operation created is determined by invoking `appropriateObjectRequestOperationWithObject:method:path:parameters:`.

 @param object The object with which to construct the object request operation. If `nil`, then the path must be provided.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKHTTPMethodDELETE` request method.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (AFHTTPRequestOperation *)DELETE:(id)object
                         URLString:(NSString *)URLString
                        parameters:(NSDictionary *)parameters
                           success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
