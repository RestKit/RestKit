//
//  RKObjectManager.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import <RestKit/Network.h>
#import "RKRouter.h"
#import "RKObjectPaginator.h"
#import "RKMacros.h"
#import "AFNetworking.h"
#import "RKManagedObjectRequestOperation.h"

@protocol RKSerialization;
@class RKManagedObjectStore, RKObjectRequestOperation, RKManagedObjectRequestOperation,
RKMappingResult, RKRequestDescriptor, RKResponseDescriptor;

/**
 The `RKObjectManager` class provides a centralized interface for performing object mapping based HTTP request and response operations. It encapsulates common configuration such as request/response descriptors and routing, provides for the creation of NSURLRequest and RKObjectRequestOperation objects, and one-line methods to enqueue object request operations for the basic HTTP request methods (GET, POST, PUT, DELETE, etc).
 
 ## Path Patterns
 
 Key Concepts??
 Routing
 Request Descriptor
 Object Request Operation
 Request and Response MIME Types???
 Parameterization
 
 ## Request and Response Descriptors
 
 RestKit centralizes configuration for object mapping configurations into the object manager through `RKRequestDescriptor` and `RKResponseDescriptor` objects. A collection of each of these object types are maintained by the manager and used to initialize all `RKObjectRequestOperation` objects created by the manager.
 
 Request descriptors describe how `NSURLRequest` objects constructed by the manager will be built by specifying how the attributes and relationships for a given class will be object mapped to construct request parameters and what, if any, root key path the parameters will be nested under. Request descriptor objects can also be used with the `RKObjectParameterization` class to map an object into an `NSDictionary` representation that is suitable for use as the parameters of a request.
 
 Response descriptors describe how `NSHTTPURLResponse` objects loaded by object request operations sent by the manager are to be object mapped into local domain objects. Response descriptors are matched against a given response via URL path matching, parsed content key path matching, or both. The `RKMapping` object associated from a matched `RKResponseDescriptor` is given to an instance of `RKObjectMapper` with the parsed response body to perform object mapping on the response.
 
 To better illustrate these concepts, consider the following example for an imaginary Wiki client application:
 
    @interface RKWikiPage : NSObject
    @property (nonatomic, copy) NSString *title;
    @property (nonatomic, copy) NSString *body;
    @end     
 
    // Construct a request mapping for our class
    RKObjectMapping *requestMapping = [RKObjectMapping requestMapping];
    [requestMapping addAttributeMappingsFromDictionary:@{ @"title": @"title", @"body": @"body" }];
    
    // We wish to generate parameters of the format: 
    // @{ @"page": @{ @"title": @"An Example Page", @"body": @"Some example content" } }
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping
                                                                                   objectClass:[RKWikiPage class]
                                                                                   rootKeyPath:@"page"];
 
    // Construct an object mapping for the response
    // We are expecting JSON in the format:
    // {"page": {"title": "<title value>", "body": "<body value>"}
    RKObjectMapping *responseMapping = [RKObjectMapping mappingForClass:[RKWikiPage class]];
    [responseMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
 
    // Construct a response descriptor that matches any URL (the pathPattern is nil), when the response payload
    // contains content nested under the `@"page"` key path, if the response status code is 200 (OK)
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:responseMapping
                                                                                       pathPattern:nil
                                                                                           keyPath:@"page"
                                                                                       statusCodes:[NSIndexSet indexSetWithIndex:200]];
 
    // Register our descriptors with a manager
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org/"]];
    [manager addRequestDescriptor:requestDescriptor];
    [manager addResponseDescriptor:responseDescriptor];
 
    // Work with the object
    RKWikiPage *page = [RKWikiPage new];
    page.title = @"An Example Page";
    page.body  = @"Some example content";
 
    // POST the parameterized representation of the `page` object to `/posts` and map the response
    [manager postObject:page path:@"/pages" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        NSLog(@"We object mapped the response with the following result: %@", result);
    } failure:nil];
 
 In the above example, request and response mapping configurations were described for a simple data model and then used to perform a basic POST operation and map the results. An arbitrary number of request and response descriptors may be added to the manager to accommodate your application's needs.
 
 ## Routing
 
 Routing is the process of generating an `NSURL` appropriate for a particular HTTP server request interaction. Using routing instead of hard-coding paths enables centralization of configuration and allows the developer to focus on what they want done rather than the details of how to do it. Changes to the URL structure in the application can be made in one place. Routes can also be useful in testing, as they permit for the changing of paths at run-time.
 
 Routing interfaces are provided by the `RKRouter` class. Each object manager is in initialized with an `RKRouter` object with a baseURL equal to the baseURL of the underlying `AFHTTPClient` object. Each `RKRouter` instance maintains an `RKRouteSet` object that manages a collection of `RKRoute` objects. Routes are defined in terms of a path pattern.
 
 There are three types of routes currently supported:
 
 1. Class Routes. Class routes are configured to target a given object class and HTTP request method. For example, we mightone might route the HTTP `GET` for a `User` class to the path pattern `@"/users/:userID"`.
 1. Relationship Routes. Relationship routes identify the path appropriate for performing a request for an object that is related to another object. For example, each `User` may have many friends. This might be routed as a relationship route for the `User` class with the name `@"friends"` to the path pattern `@"/users/:userID/friends"`.
 1. Named Routes. Names routes bind an arbitrary name to a path. For example, there might be an action to follow another user that could be added as a named route with the name `@"follow_user"` that generates a `POST` to the path pattern `@"/users/:userID/follow"`.
 
 To better understand these concepts, please consider the following example code for configuring the above routing examples:
 
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
 
    // Class Route
    [manager.router.routeSet addRoute:[RKRoute routeWithClass:[User class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
 
    // Relationship Route
    [manager.router.routeSet addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[User class] pathPattern:@"/users/:userID/friends" method:RKRequestMethodGET]];
 
    // Named Route
    [manager.router.routeSet addRoute:[RKRoute routeWithName:@"follow_user" pathPattern:@"/users/:userID/follow" method:RKRequestMethodPOST]];
 
 Once configured, routes will be consulted by the object manager whenever the path parameter provided to a method is given as nil. For example, invoking the following code would result in a `GET` to the path `@"/users/1234"`:
 
    User *user = [User new];
    user.userID = 1234;
    [manager getObject:user path:nil parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        // Request 
    } failure:nil];
 
 Routes can also be explicitly used to construct `NSMutableURLRequest` objects and are referenced explicitly in a few object request operation methods:
 
 1. `requestWithObject:method:path:parameters:` - Consults routing when path is nil.
 1. `multipartFormRequestWithObject:method:path:parameters:constructingBodyWithBlock:` - Consults routing when path is nil.
 1. `requestWithPathForRouteNamed:object:parameters:` - Explicitly retrieves the route with the given name.
 1. `getObjectsAtPathForRelationship:ofObject:parameters:success:failure:` - Explicitly retrieves the route for the given
    name and object class.
 1. `getObjectsAtPathForRouteNamed:object:parameters:success:failure:` - Explicitly retrieves the route for the given
    name.
 
 Please see the documentation for `RKRouter`, `RKRouteSet`, and `RKRoute` for more details about the routing classes.
 
 ## Core Data
 
 RestKit features deep integration with Apple's Core Data persistence framework. The object manager provides access to this integration by creating `RKManagedObjectRequestOperation` objects when an attempt is made to interact with a resource that has been mapped using an `RKEntityMapping`. To utilize the Core Data integration, the object manager must be provided with a fully configured `RKManagedObjectStore` object. The `RKManagedObjectStore` provides access to the `NSManagedObjectModel` and `NSManagedObjectContext` objects required to peform object mapping that targets a Core Data entity.
 
 Fetch Request Blocks ->> TODO
 Need to cover DELETE impacts...
 
 Please see the documentation for `RKManagedObjectStore` and `RKEntityMapping` for in depth information about Core Data in RestKit.
 */
@interface RKObjectManager : NSObject

///----------------------------------------------
/// @name Configuring the Shared Manager Instance
///----------------------------------------------

/**
 Return the shared instance of the object manager
 
 @return The shared manager instance.
 */
+ (RKObjectManager *)sharedManager;

/**
 Set the shared instance of the object manager
 
 @param manager The new shared manager instance.
 */
+ (void)setSharedManager:(RKObjectManager *)manager;

///-------------------------------------
/// @name Initializing an Object Manager
///-------------------------------------

/**
 Creates and returns a new `RKObjectManager` object initialized with a new `AFHTTPClient` object that was in turn initialized with the given base URL.
 
 This is a convenience interface for initializing an `RKObjectManager` and its underlying `AFHTTPClient` object with a single message. It is functionally equivalent to the following example code:
 
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:baseURL];
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
 
 @param baseURL The base URL with which to initialize the `AFHTTPClient` object
 @return A new `RKObjectManager` initialized with an `AFHTTPClient` that was initialized with the given baseURL.
 */
+ (id)managerWithBaseURL:(NSURL *)baseURL;

/**
 Initializes the receiver with the given AFNetworking HTTP client object.
 
 This is the designated initializer. If the sharedManager instance is nil, the receiver will be set as the sharedManager.

 @param client The AFNetworking HTTP client with which to initialize the receiver.
 @return The receiver, initialized with the given client.
 */
- (id)initWithHTTPClient:(AFHTTPClient *)client;

///------------------------------------------
/// @name Accessing Object Manager Properties
///------------------------------------------

/**
 The AFNetworking HTTP client with which the receiver makes requests.
 */
@property (nonatomic, strong, readonly) AFHTTPClient *HTTPClient;

/**
 The operation queue which manages operations enqueued by the object manager.
 */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/**
 The router used to generate URL objects for routable requests created by the manager.
 
 @see RKRouter
 @see RKRoute
 */
@property (nonatomic, strong) RKRouter *router;

/**
 The Default MIME Type to be used in object serialization.
 */
@property (nonatomic, strong) NSString *serializationMIMEType;
// parameterSerializationMIMEType;
// requestParameterMIMEType;
// responseAcceptMIMEType;

/**
 The value for the HTTP Accept header to specify the preferred format for retrieved data
 */
// TODO: Should we just remove this??
//- (void)setAcceptHeaderWithMIMEType:(NSString *)MIMEType;
@property (nonatomic, weak) NSString *acceptMIMEType;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates and returns an `NSMutableURLRequest` object with a given object, method, path, and parameters.
 
 The manager is searched for an `RKRequestDescriptor` object with an objectClass that matches the class of the given object. If found, the matching request descriptor and object are used to build a parameterization of the object's attributes using the `RKObjectParameterization` class if the request method is a `POST`, `PUT`, or `PATCH`. The parameterized representation of the object is reverse merged with the given parameters dictionary, if any, and then serialized and set as the request body. If the HTTP method is `GET`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL.
 
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
                                    method:(RKRequestMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;

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
                                                method:(RKRequestMethod)method
                                                  path:(NSString *)path
                                            parameters:(NSDictionary *)parameters
                             constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

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
                                           parameters:(NSDictionary *)parameters;
/**
 Creates an `NSMutableURLRequest` object with the `NSURL` returned by the router for the relationship of the given object and the given parameters.
 
 The implementation invokes `requestWithObject:method:path:parameters:` after constructing the path with the given route.
 
 Creates an `RKObjectRequestOperation` with a `GET` request for the relationship with the given name of the given object, and enqueues it to the manager's operation queue.
 
 @param relationshipName The name of the relationship being loaded. Used to retrieve the `RKRoute` object from the router for the given object's class and the relationship name. Cannot be nil.
 @param object The object for which related objects are being loaded. Evaluated against the `RKRoute` for the relationship for the object's class with the given name to compute the path. Cannot be nil.
 @param method The HTTP method for the request.
 @param parameters The parameters to be encoded and appended as the query string for the request URL, or parameterized and set as the request body. May be nil.
 @return An `NSMutableURLRequest` object for the specified relationship.
 
 @raises NSInvalidArgumentException Raised if no route is configured for a relationship of the given object's class with the given name.
 @see `requestWithObject:method:path:parameters`
 */
- (NSMutableURLRequest *)requestWithPathForRelationship:(NSString *)relationship
                                               ofObject:(id)object
                                                 method:(RKRequestMethod)method
                                             parameters:(NSDictionary *)parameters;

///-----------------------------------------
/// @name Creating Object Request Operations
///-----------------------------------------

/**
 Creates an `RKObjectRequestOperation` operation with the given request and sets the completion block with the given success and failure blocks.
 
 @param request The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 @return An `RKObjectRequestOperation` object that is ready to be sent.
 
 @warning Instances of `RKObjectRequestOperation` are not capable of mapping the loaded `NSHTTPURLResponse` into a Core Data entity. Use an instance of `RKManagedObjectRequestOperation` if the response is to be mapped using an `RKEntityMapping`.
 */
- (RKObjectRequestOperation *)objectRequestOperationWithRequest:(NSURLRequest *)request
                                                        success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                        failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKManagedObjectRequestOperation` operation with the given request and managed object context, and sets the completion block with the given success and failure blocks.
 
 The given managed object context given will be used as the parent context of the private managed context in which the response is mapped and will be used to fetch the results upon invocation of the success completion block.
 
 @param request The request object to be loaded asynchronously during execution of the operation.
 @param managedObjectContext The managed object context with which to associate the operation. This context will be used as the parent context of a new operation local `NSManagedObjectContext` with the `NSPrivateQueueConcurrencyType` concurrency type. Upon success, the private context will be saved and changes resulting from the object mapping will be 'pushed' to the given context.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 @return An `RKObjectRequestOperation` object that is ready to be sent.
 
 @see `RKManagedObjectRequestOperation`
 */
- (RKManagedObjectRequestOperation *)managedObjectRequestOperationWithRequest:(NSURLRequest *)request
                                                         managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                      success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                                      failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;


/**
 Creates and returns an object request operation of the appropriate type for the given object, request method, path, and parameters.
 
 The type of object request operation created is determined by evaluating the type of the object given and examining the list of `RKResponseDescriptor` objects added to the manager. 
 
 If the given object is non-nil and inherits from `NSManagedObject`, then an instance of `RKManagedObjectRequestOperation` is returned.
 
 If the given object is nil, then the `RKResponseDescriptor` objects added to the manager are evaluated to determine the type of operation created. In this case, the path of the operation is used to filter the set of `RKResponseDescriptor` objects to those that may be used to map the response. If the path is nil, the router is consulted to determine an appropriate path with which to perform the matching. If the filtered array of matching response descriptors defines a mapping configuration with an `RKEntityMapping` object, then an `RKManagedObjectRequestOperation` is returned; otherwise an `RKObjectRequestOperation` is returned.
 
 If an `RKManagedObjectRequestOperation` operation is created, the managed object context used will be the `mainQueueManagedObjectContext` of the manager's `managedObjectStore`.
 
 @param object The object with which to construct the object request operation. May be nil.
 @param method The request method for the request.
 @param path The path to be appended to the HTTP client's baseURL and set as the URL of the request. If nil, the router is consulted.
 @param parameters The parameters to be either set as a query string for `GET` requests, or reverse merged with the parameterization of the object and set as the request HTTP body.
 
 @return A newly created `RKObjectRequestOperation` or `RKManagedObjectRequest` operation as deemed appropriate by the manager for the given parameters.
 @warning The given object must be a single object instance. Collections are not yet supported.
 
 @see `requestWithObject:method:path:parameters`
 */
- (id)appropriateObjectRequestOperationWithObject:(id)object
                                           method:(RKRequestMethod)method
                                             path:(NSString *)path
                                       parameters:(NSDictionary *)parameters;

///--------------------------------------------------
/// @name Managing Enqueued Object Request Operations
///--------------------------------------------------

/**
 Enqueues an `RKObjectRequestOperation` to the object manager's operation queue.
 
 @param objectRequestOperation The object request operation to be enqueued.
 */
- (void)enqueueObjectRequestOperation:(RKObjectRequestOperation *)objectRequestOperation;
// TODO: Need a cancel...

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
- (void)getObjectsAtPath:(NSString *)path
              parameters:(NSDictionary *)parameters
                 success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                 failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

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
- (void)getObjectsAtPathForRelationship:(NSString *)relationshipName
                               ofObject:(id)object
                             parameters:(NSDictionary *)parameters
                                success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

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
- (void)getObjectsAtPathForRouteNamed:(NSString *)routeName
                               object:(id)object
                           parameters:(NSDictionary *)parameters
                              success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                              failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

///-------------------------------------------
/// @name Making Object Requests for an Object
///-------------------------------------------

/**
 Creates an `RKObjectRequestOperation` with a `GET` request for the given object, and enqueues it to the manager's operation queue.
 
 The type of object request operation created is determined by invoking `appropriateObjectRequestOperationWithObject:method:path:parameters:`.
 
 @param object The object with which to construct the object request operation. Cannot be nil.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKRequestMethodGET` request method.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (void)getObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `POST` request for the given object, and enqueues it to the manager's operation queue.
 
 @param object The object with which to construct the object request operation. Cannot be nil.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKRequestMethodPOST` method.
 @param parameters The parameters to be reverse merged with the parameterization of the given object and set as the request body.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (void)postObject:(id)object
              path:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
           failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `PUT` request for the given object, and enqueues it to the manager's operation queue.
 
 @param object The object with which to construct the object request operation. Cannot be nil.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKRequestMethodPUT` method.
 @param parameters The parameters to be reverse merged with the parameterization of the given object and set as the request body.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (void)putObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `PATCH` request for the given object, and enqueues it to the manager's operation queue.
 
 @param object The object with which to construct the object request operation. Cannot be nil.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKRequestMethodPATCH` method.
 @param parameters The parameters to be reverse merged with the parameterization of the given object and set as the request body.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (void)patchObject:(id)object
               path:(NSString *)path
         parameters:(NSDictionary *)parameters
            success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
            failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `DELETE` request for the given object, and enqueues it to the manager's operation queue.
 
 The type of object request operation created is determined by invoking `appropriateObjectRequestOperationWithObject:method:path:parameters:`.
 
 @param object The object with which to construct the object request operation. Cannot be nil.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If nil, the request URL will be obtained by consulting the router for a route registered for the given object's class and the `RKRequestMethodDELETE` request method.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the object request operation finishes successfully. This block has no return value and takes two arguments: the created object request operation and the `RKMappingResult` object created by object mapping the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see [RKRouter URLForObject:method:]
 @see [RKObjectManager appropriateObjectRequestOperationWithObject:method:path:parameters:]
 */
- (void)deleteObject:(id)object
                path:(NSString *)path
          parameters:(NSDictionary *)parameters
             success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
             failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

///------------------------------------------------
/// @name Managing Request and Response Descriptors
///------------------------------------------------

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
- (void)addRequestDescriptorsFromArray:(NSArray *)requestDescriptors;

/**
 Removes a given request descriptor from the manager.
 
 @param requestDescriptor An `RKRequestDescriptor` object to be removed from the manager.
 */
- (void)removeRequestDescriptor:(RKRequestDescriptor *)requestDescriptor;

/**
 Returns an array containing the `RKResponseDescriptor` objects added to the manager.
 
 @return An array containing the request descriptors of the receiver. The elements of the array are instances of `RKRequestDescriptor`.
 
 @see RKResponseDescriptor
 */
@property (nonatomic, readonly) NSArray *responseDescriptors;

/**
 Adds a response descriptor to the manager.
 
 @param responseDescriptor The response descriptor object to the be added to the manager.
 */
- (void)addResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

/**
 Adds the `RKResponseDescriptor` objects contained in a given array to the manager.
 
 @param responseDescriptors An array of `RKResponseDescriptor` objects to be added to the manager.
 @exception NSInvalidArgumentException Raised if any element of the given array is not an `RKResponseDescriptor` object.
 */
- (void)addResponseDescriptorsFromArray:(NSArray *)responseDescriptors;

/**
 Removes a given response descriptor from the manager.
 
 @param responseDescriptor An `RKResponseDescriptor` object to be removed from the manager.
 */
- (void)removeResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

///----------------------------------------
/// @name Configuring Core Data Integration
///----------------------------------------

// Moves to RKObjectManager+CoreData

/**
 A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;

/**
 An array of `RKFetchRequestBlock` blocks used to map `NSURL` objects into corresponding `NSFetchRequest` objects.
 
 When searched, the blocks are iterated in the reverse-order of their registration and the first block with a non-nil return value halts the search.
 */
@property (nonatomic, readonly) NSArray *fetchRequestBlocks;

/**
 Adds the given `RKFetchRequestBlock` block to the manager.
 
 @param A block object to be executed when constructing an `NSFetchRequest` object from a given `NSURL`. The block has a return type of `NSFetchRequest` and accepts a single `NSURL` argument.
 */
- (void)addFetchRequestBlock:(RKFetchRequestBlock)block;

///---------------------------------
/// @name Creating Paginator Objects
///---------------------------------

/**
 Creates and returns an RKObjectPaginator instance targeting the specified path pattern.
 
 The paginator instantiated will be initialized with a URL built by appending the pathPattern to the baseURL of the client.
 
 @return The newly created paginator instance.
 @see RKObjectPaginator
 */
//- (RKObjectPaginator *)paginatorWithPathPattern:(NSString *)pathPattern;

@end

/**
 Returns a string description of the given network status.

 @param networkReachabilityStatus The network reachability status.
 @return A string describing the reachability status.
 */
NSString *RKStringFromNetworkReachabilityStatus(AFNetworkReachabilityStatus networkReachabilityStatus);
