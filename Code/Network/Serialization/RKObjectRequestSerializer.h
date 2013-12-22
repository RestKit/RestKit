//
//  RKObjectRequestSerializer.h
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFURLRequestSerialization.h"
#import "RKHTTPUtilities.h"
#import "RKRequestDescriptor.h"

@interface RKObjectRequestSerializer : AFHTTPRequestSerializer

///-----------------------------------
/// @name Managing Request Descriptors
///-----------------------------------

/**
Returns an array containing the `RKRequestDescriptor` objects added to the manager.

@return An array containing the request descriptors of the receiver. The elements of the array are instances of `RKRequestDescriptor`.

@see RKRequestDescriptor
*/
@property (nonatomic, readonly) NSArray *requestDescriptors;

/**
 Adds a request descriptor to the manager.

 @param requestDescriptor The request descriptor object to the be added to the manager.
 */
- (void)addRequestDescriptor:(RKRequestDescriptor *)requestDescriptor;

/**
 Adds the `RKRequestDescriptor` objects contained in a given array to the manager.

 @param requestDescriptors An array of `RKRequestDescriptor` objects to be added to the manager.
 @exception NSInvalidArgumentException Raised if any element of the given array is not an `RKRequestDescriptor` object.
 */
- (void)addRequestDescriptors:(NSArray *)requestDescriptors;

/**
 Removes a given request descriptor from the manager.

 @param requestDescriptor An `RKRequestDescriptor` object to be removed from the manager.
 */
- (void)removeRequestDescriptor:(RKRequestDescriptor *)requestDescriptor;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates and returns an `NSMutableURLRequest` object with a given object, method, path, and parameters.

 The manager is searched for an `RKRequestDescriptor` object with an objectClass that matches the class of the given object. If found, the matching request descriptor and object are used to build a parameterization of the object's attributes using the `RKObjectParameterization` class if the request method is a `POST`, `PUT`, or `PATCH`. The parameterized representation of the object is reverse merged with the given parameters dictionary, if any, and then serialized and set as the request body. If the HTTP method is `GET` or `DELETE`, the object will not be parameterized and the given parameters, if any, will be used to construct a url-encoded query string that is appended to the request's URL.

 If the given path is nil, the router is searched for a class route with the class of the object andthe method. The path pattern of the retrieved route is interpolated with the object and the resulting path is appended to the HTTP client's base URL and used as the request URL.

 @param object The object with which to construct the request. For the `POST`, `PUT`, and `PATCH` request methods, the object will parameterized using the `RKRequestDescriptor` for the object.
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the router is consulted.
 @param parameters The parameters to be either set as a query string for `GET` requests, or reverse merged with the parameterization of the object and set as the request HTTP body.

 @return An `NSMutableURLRequest` object.
 @see RKObjectParameterization
 @see RKRouter
 */
- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKHTTPMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                                     error:(NSError * __autoreleasing *)error;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2

 This method wraps the underlying `AFHTTPClient` method `multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock` and adds routing and object parameterization.

 @param object The object with which to construct the request. For the `POST`, `PUT`, and `PATCH` request methods, the object will parameterized using the `RKRequestDescriptor` for the object.
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the router is consulted.
 @param parameters The parameters to be either set as a query string for `GET` requests, or reverse merged with the parameterization of the object and set as the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol. This can be used to upload files, encode HTTP body as JSON or XML, or specify multiple values for the same parameter, as one might for array values.
 @return An `NSMutableURLRequest` object.
 @warning An exception will be raised if the specified method is not `POST`, `PUT` or `DELETE`.
 @see [AFHTTPClient multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock]
 */
- (NSMutableURLRequest *)multipartFormRequestWithObject:(id)object
                                                 method:(RKHTTPMethod)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError * __autoreleasing *)error;

/**
 Creates an `NSMutableURLRequest` object with the `NSURL` returned by the router for the given route name and object and the given parameters.

 The implementation invokes `requestWithObject:method:path:parameters:` after constructing the path with the given route.

 @param routeName The name of the route object containing the path pattern which is to be interpolated against the given object, appended to the HTTP client's base URL and used as the request URL.
 @param object The object with which to interpolate the path pattern of the named route. Can be nil.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 @return An `NSMutableRequest` object.

 @see `requestWithObject:method:path:parameters`
 */
- (NSMutableURLRequest *)requestWithPathForRouteNamed:(NSString *)routeName
                                               object:(id)object
                                           parameters:(NSDictionary *)parameters
                                                error:(NSError * __autoreleasing *)error;
/**
 Creates an `NSMutableURLRequest` object with the `NSURL` returned by the router for the relationship of the given object and the given parameters.

 The implementation invokes `requestWithObject:method:path:parameters:` after constructing the path with the given route.

 Creates an `RKObjectRequestOperation` with a `GET` request for the relationship with the given name of the given object, and enqueues it to the manager's operation queue.

 @param relationship The name of the relationship being loaded. Used to retrieve the `RKRoute` object from the router for the given object's class and the relationship name. Cannot be nil.
 @param object The object for which related objects are being loaded. Evaluated against the `RKRoute` for the relationship for the object's class with the given name to compute the path. Cannot be nil.
 @param method The HTTP method for the request.
 @param parameters The parameters to be encoded and appended as the query string for the request URL, or parameterized and set as the request body. May be nil.
 @return An `NSMutableURLRequest` object for the specified relationship.

 @raises NSInvalidArgumentException Raised if no route is configured for a relationship of the given object's class with the given name.
 @see `requestWithObject:method:path:parameters`
 */
- (NSMutableURLRequest *)requestWithPathForRelationship:(NSString *)relationship
                                               ofObject:(id)object
                                                 method:(RKHTTPMethodOptions)method
                                             parameters:(NSDictionary *)parameters
                                                  error:(NSError * __autoreleasing *)error;

@end
