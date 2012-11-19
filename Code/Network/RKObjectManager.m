//
//  RKObjectManager.m
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

#import <objc/runtime.h>
#import "RKObjectManager.h"
#import "RKObjectParameterization.h"
#import "RKManagedObjectStore.h"
#import "RKRequestDescriptor.h"
#import "RKResponseDescriptor.h"
#import "RKDictionaryUtilities.h"
#import "RKMIMETypes.h"
#import "RKLog.h"
#import "RKMIMETypeSerialization.h"
#import "RKPathMatcher.h"
#import "RKMappingErrors.h"
#import "RKPaginator.h"

#if !__has_feature(objc_arc)
#error RestKit must be built with ARC.
// You can turn on ARC for only RestKit files by adding "-fobjc-arc" to the build phase for each of its files.
#endif

//////////////////////////////////
// Shared Instance

static RKObjectManager  *sharedManager = nil;

//////////////////////////////////
// Utility Functions

/**
 Returns the subset of the given array of `RKResponseDescriptor` objects that match the given path.
 
 @param responseDescriptors An array of `RKResponseDescriptor` objects.
 @param path The path for which to select matching response descriptors.
 @return An `NSArray` object whose elements are `RKResponseDescriptor` objects matching the given path.
 */
static NSArray *RKFilteredArrayOfResponseDescriptorsMatchingPath(NSArray *responseDescriptors, NSString *path)
{
    NSIndexSet *indexSet = [responseDescriptors indexesOfObjectsPassingTest:^BOOL(RKResponseDescriptor *responseDescriptor, NSUInteger idx, BOOL *stop) {
        return [responseDescriptor matchesPath:path];
    }];
    return [responseDescriptors objectsAtIndexes:indexSet];
}

/**
 Returns the first `RKRequestDescriptor` object from the given array that matches the given object.
 
 @param requestDescriptors An array of `RKRequestDescriptor` objects.
 @param object The object to find a matching request descriptor for.
 @return An `RKRequestDescriptor` object matching the given object, or `nil` if none could be found.
 */
static RKRequestDescriptor *RKRequestDescriptorFromArrayMatchingObject(NSArray *requestDescriptors, id object)
{
    Class searchClass = [object class];
    do {
        for (RKRequestDescriptor *requestDescriptor in requestDescriptors) {
            if ([requestDescriptor.objectClass isEqual:searchClass]) return requestDescriptor;
        }
        searchClass = [searchClass superclass];
    } while (searchClass);
    
    return nil;
}

/**
 Returns `YES` if the given array of `RKResponseDescriptor` objects contains an `RKEntityMapping`.
 
 @param responseDescriptor An array of `RKResponseDescriptor` objects.
 @return `YES` if the `mapping` property of any of the response descriptor objects in the given array is an instance of `RKEntityMapping`, else `NO`.
 */
static BOOL RKDoesArrayOfResponseDescriptorsContainEntityMapping(NSArray *responseDescriptors)
{
    for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
        if ([responseDescriptor.mapping isKindOfClass:[RKEntityMapping class]]) {
            return YES;
        }
    }
    
    return NO;
}

static NSString *RKMIMETypeFromAFHTTPClientParameterEncoding(AFHTTPClientParameterEncoding encoding)
{
    switch (encoding) {
        case AFFormURLParameterEncoding:
            return RKMIMETypeFormURLEncoded;
            break;
            
        case AFJSONParameterEncoding:
            return RKMIMETypeJSON;
            break;
            
        case AFPropertyListParameterEncoding:
            break;
            
        default:
            RKLogWarning(@"RestKit is unable to infer the appropriate request serialization MIME Type from an `AFHTTPClientParameterEncoding` value of %d: defaulting to `RKMIMETypeFormURLEncoded`", encoding);
            break;
    }
    
    return RKMIMETypeFormURLEncoded;
}

///////////////////////////////////

@interface RKObjectManager ()
@property (nonatomic, strong, readwrite) AFHTTPClient *HTTPClient;
@property (nonatomic, strong) NSMutableArray *mutableRequestDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableResponseDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableFetchRequestBlocks;
@property (nonatomic, strong) NSString *acceptHeaderValue;
@property (nonatomic) Class HTTPOperationClass;
@end

@implementation RKObjectManager

- (id)initWithHTTPClient:(AFHTTPClient *)client
{
    self = [super init];
    if (self) {
        self.HTTPClient = client;
        self.router = [[RKRouter alloc] initWithBaseURL:client.baseURL];        
        self.operationQueue = [NSOperationQueue new];
        self.mutableRequestDescriptors = [NSMutableArray new];
        self.mutableResponseDescriptors = [NSMutableArray new];
        self.mutableFetchRequestBlocks = [NSMutableArray new];
        self.requestSerializationMIMEType = RKMIMETypeFromAFHTTPClientParameterEncoding(client.parameterEncoding);        

        // Set shared manager if nil
        if (nil == sharedManager) {
            [RKObjectManager setSharedManager:self];
        }
    }

    return self;
}

+ (RKObjectManager *)sharedManager
{
    return sharedManager;
}

+ (void)setSharedManager:(RKObjectManager *)manager
{
    sharedManager = manager;
}

+ (RKObjectManager *)managerWithBaseURL:(NSURL *)baseURL
{
    RKObjectManager *manager = [[self alloc] initWithHTTPClient:[AFHTTPClient clientWithBaseURL:baseURL]];
    manager.acceptHeaderValue = RKMIMETypeJSON;
    manager.requestSerializationMIMEType = RKMIMETypeFormURLEncoded;
    return manager;
}

// NOTE: This implementation could just use the default headers on AFHTTPClient, but this
// feels less intrusive.
- (void)setAcceptHeaderWithMIMEType:(NSString *)MIMEType;
{
    self.acceptHeaderValue = MIMEType;
}

- (NSURL *)baseURL
{
    return self.HTTPClient.baseURL;
}

- (NSDictionary *)defaultHeaders
{
    NSMutableDictionary *defaultHeaders = [self.HTTPClient.defaultHeaders mutableCopy];
    if (self.acceptHeaderValue) [defaultHeaders setValue:self.acceptHeaderValue forKey:@"Accept"];
    return defaultHeaders;
}

#pragma mark - Building Requests

/**
 This method is the `RKObjectManager` analog for the method of the same name on `AFHTTPClient`.
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest* request;
    if (parameters && !([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"])) {
        request = [self.HTTPClient requestWithMethod:method path:path parameters:nil];
		
        NSError *error = nil;
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.HTTPClient.stringEncoding));
        [request setValue:[NSString stringWithFormat:@"%@; charset=%@", self.requestSerializationMIMEType, charset] forHTTPHeaderField:@"Content-Type"];
        NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:self.requestSerializationMIMEType error:&error];
        [request setHTTPBody:requestBody];
	} else {
        request = [self.HTTPClient requestWithMethod:method path:path parameters:parameters];
    }
    if (self.acceptHeaderValue) [request setValue:self.acceptHeaderValue forHTTPHeaderField:@"Accept"];

	return request;
}

- (NSMutableURLRequest *)requestWithPathForRouteNamed:(NSString *)routeName
                                               object:(id)object
                                           parameters:(NSDictionary *)parameters
{
    RKRequestMethod method;
    NSURL *URL = [self.router URLForRouteNamed:routeName method:&method object:object];
    NSAssert(URL, @"No route found named '%@'", routeName);
    return [self requestWithMethod:RKStringFromRequestMethod(method) path:[URL relativeString] parameters:parameters];
}

- (NSMutableURLRequest *)requestWithPathForRelationship:(NSString *)relationship
                                               ofObject:(id)object
                                                 method:(RKRequestMethod)method
                                             parameters:(NSDictionary *)parameters
{
    NSURL *URL = [self.router URLForRelationship:relationship ofObject:object method:method];
    NSAssert(URL, @"No relationship route found for the '%@' class with the name '%@'", NSStringFromClass([object class]), relationship);
    return [self requestWithMethod:RKStringFromRequestMethod(method) path:[URL relativeString] parameters:parameters];
}

- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKRequestMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;
{
    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
    NSString *stringMethod = RKStringFromRequestMethod(method);
    NSDictionary *requestParameters = nil;
    RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObject(self.requestDescriptors, object);
    if ((method != RKRequestMethodGET && method != RKRequestMethodDELETE) && requestDescriptor) {
        NSError *error = nil;
        requestParameters = [[RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error] mutableCopy];
        if (error) {
            RKLogError(@"Object parameterization failed while building %@ request to '%@': %@", stringMethod, requestPath, error);
            return nil;
        }
        if (parameters) {
            requestParameters = RKDictionaryByMergingDictionaryWithDictionary(requestParameters, parameters);
        }
    } else {
        requestParameters = parameters;
    }

    return [self requestWithMethod:stringMethod path:requestPath parameters:requestParameters];
}

- (NSMutableURLRequest *)multipartFormRequestWithObject:(id)object
                                                 method:(RKRequestMethod)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
{
    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
    NSString *stringMethod = RKStringFromRequestMethod(method);
    NSDictionary *requestParameters = nil;
    RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObject(self.requestDescriptors, object);
    if (requestDescriptor) {
        NSError *error = nil;
        requestParameters = [[RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error] mutableCopy];
        if (parameters) {
            requestParameters = RKDictionaryByMergingDictionaryWithDictionary(requestParameters, parameters);
        }
    } else {
        requestParameters = parameters;
    }
    NSMutableURLRequest *multipartRequest = [self.HTTPClient multipartFormRequestWithMethod:stringMethod path:requestPath parameters:requestParameters constructingBodyWithBlock:block];
    if (self.acceptHeaderValue) [multipartRequest setValue:self.acceptHeaderValue forHTTPHeaderField:@"Accept"];

    return multipartRequest;
}

- (void)setHTTPOperationClass:(Class)operationClass
{
    NSAssert(operationClass == nil || [operationClass isSubclassOfClass:[RKHTTPRequestOperation class]], @"The HTTP operation class must be a subclass of `RKHTTPRequestOperation`");
    _HTTPOperationClass = operationClass;
}

- (RKHTTPRequestOperation *)HTTPOperationWithRequest:(NSURLRequest *)request
{
    Class operationClass = self.HTTPOperationClass ?: [RKHTTPRequestOperation class];
    return [[operationClass alloc] initWithRequest:request];
}

#pragma mark - Object Request Operations

- (RKObjectRequestOperation *)objectRequestOperationWithRequest:(NSURLRequest *)request
                                                        success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                        failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithHTTPRequestOperation:[self HTTPOperationWithRequest:request] responseDescriptors:self.responseDescriptors];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    return operation;
}

- (RKManagedObjectRequestOperation *)managedObjectRequestOperationWithRequest:(NSURLRequest *)request
                                                         managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                      success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                                      failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:[self HTTPOperationWithRequest:request] responseDescriptors:self.responseDescriptors];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.managedObjectContext = managedObjectContext;
    operation.managedObjectCache = self.managedObjectStore.managedObjectCache;
    operation.fetchRequestBlocks = self.fetchRequestBlocks;
    return operation;
}

- (id)appropriateObjectRequestOperationWithObject:(id)object
                                           method:(RKRequestMethod)method
                                             path:(NSString *)path
                                       parameters:(NSDictionary *)parameters
{
    RKObjectRequestOperation *operation = nil;
    NSURLRequest *request = [self requestWithObject:object method:method path:path parameters:parameters];
    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
    NSArray *matchingDescriptors = RKFilteredArrayOfResponseDescriptorsMatchingPath(self.responseDescriptors, requestPath);
    BOOL containsEntityMapping = RKDoesArrayOfResponseDescriptorsContainEntityMapping(matchingDescriptors);
    BOOL isManagedObjectRequestOperation = (containsEntityMapping || [object isKindOfClass:[NSManagedObject class]]);
    
    if (isManagedObjectRequestOperation && !self.managedObjectStore) RKLogWarning(@"Asked to create an `RKManagedObjectRequestOperation` object, but managedObjectStore is nil.");
    if ((containsEntityMapping) && self.managedObjectStore) {
        // Construct a Core Data operation
        NSManagedObjectContext *managedObjectContext = [object respondsToSelector:@selector(managedObjectContext)] ? [object managedObjectContext] : self.managedObjectStore.mainQueueManagedObjectContext;
        operation = [self managedObjectRequestOperationWithRequest:request managedObjectContext:managedObjectContext success:nil failure:nil];
        if ([object isKindOfClass:[NSManagedObject class]] && [[object objectID] isTemporaryID]) {
            RKLogInfo(@"Asked to perform object request with NSManagedObject with temporary object ID: Obtaining permanent ID before proceeding.");
            __block BOOL _blockSuccess;
            __block NSError *_blockError;
            
            [[object managedObjectContext] performBlockAndWait:^{
                _blockSuccess = [[object managedObjectContext] obtainPermanentIDsForObjects:@[object] error:&_blockError];
            }];
            if (! _blockSuccess) RKLogWarning(@"Failed to obtain permanent ID for object %@: %@", object, _blockError);
        }                
    } else {
        // Non-Core Data operation
        operation = [self objectRequestOperationWithRequest:request success:nil failure:nil];
    }
    
    operation.targetObject = object;
    return operation;
}

- (void)getObjectsAtPathForRelationship:(NSString *)relationshipName
                               ofObject:(id)object
                             parameters:(NSDictionary *)parameters
                                success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSURL *URL = [self.router URLForRelationship:relationshipName ofObject:object method:RKRequestMethodGET];
    NSAssert(URL, @"Failed to generate URL for relationship named '%@' for object: %@", relationshipName, object);
    return [self getObjectsAtPath:[URL relativeString] parameters:parameters success:success failure:failure];
}

- (void)getObjectsAtPathForRouteNamed:(NSString *)routeName
                               object:(id)object
                           parameters:(NSDictionary *)parameters
                              success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                              failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKRequestMethod method;
    NSURL *URL = [self.router URLForRouteNamed:routeName method:&method object:object];
    NSAssert(URL, @"No route found named '%@'", routeName);
    NSString *path = [URL relativeString];
    NSAssert(method == RKRequestMethodGET, @"Expected route named '%@' to specify a GET, but it does not", routeName);
    return [self getObjectsAtPath:path parameters:parameters success:success failure:failure];
}

- (void)getObjectsAtPath:(NSString *)path
              parameters:(NSDictionary *)parameters
                 success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                 failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)getObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSParameterAssert(object);
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:object method:RKRequestMethodGET path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)postObject:(id)object
              path:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
           failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSParameterAssert(object);
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:object method:RKRequestMethodPOST path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)putObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSParameterAssert(object);
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:object method:RKRequestMethodPUT path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)patchObject:(id)object
               path:(NSString *)path
         parameters:(NSDictionary *)parameters
            success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
            failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSParameterAssert(object);
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:object method:RKRequestMethodPATCH path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)deleteObject:(id)object
                path:(NSString *)path
          parameters:(NSDictionary *)parameters
             success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
             failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSParameterAssert(object);
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:object method:RKRequestMethodDELETE path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (RKPaginator *)paginatorWithPathPattern:(NSString *)pathPattern
{
    NSAssert(self.paginationMapping, @"Cannot instantiate a paginator when `paginationMapping` is nil.");
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:pathPattern parameters:nil];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:self.responseDescriptors];
    paginator.managedObjectContext = self.managedObjectStore.mainQueueManagedObjectContext;
    paginator.managedObjectCache = self.managedObjectStore.managedObjectCache;
    paginator.fetchRequestBlocks = self.fetchRequestBlocks;
    return paginator;
}

#pragma mark - Request & Response Descriptors

- (NSArray *)requestDescriptors
{
    return [NSArray arrayWithArray:self.mutableRequestDescriptors];
}

- (void)addRequestDescriptor:(RKRequestDescriptor *)requestDescriptor
{
    NSParameterAssert(requestDescriptor);
    if ([self.requestDescriptors containsObject:requestDescriptor]) return;
    NSAssert([requestDescriptor isKindOfClass:[RKRequestDescriptor class]], @"Expected an object of type RKRequestDescriptor, got '%@'", [requestDescriptor class]);
    [self.requestDescriptors enumerateObjectsUsingBlock:^(RKRequestDescriptor *registeredDescriptor, NSUInteger idx, BOOL *stop) {
        NSAssert(![registeredDescriptor.objectClass isEqual:requestDescriptor.objectClass], @"Cannot add a request descriptor for the same object class as an existing request descriptor.");
    }];
    [self.mutableRequestDescriptors addObject:requestDescriptor];
}

- (void)addRequestDescriptorsFromArray:(NSArray *)requestDescriptors
{
    for (RKRequestDescriptor *requestDescriptor in requestDescriptors) {
        [self addRequestDescriptor:requestDescriptor];
    }
}

- (void)removeRequestDescriptor:(RKRequestDescriptor *)requestDescriptor
{
    NSParameterAssert(requestDescriptor);
    NSAssert([requestDescriptor isKindOfClass:[RKRequestDescriptor class]], @"Expected an object of type RKRequestDescriptor, got '%@'", [requestDescriptor class]);
    [self.mutableRequestDescriptors removeObject:requestDescriptor];
}

- (NSArray *)responseDescriptors
{
    return [NSArray arrayWithArray:self.mutableResponseDescriptors];
}

- (void)addResponseDescriptor:(RKResponseDescriptor *)responseDescriptor
{
    NSParameterAssert(responseDescriptor);
    NSAssert([responseDescriptor isKindOfClass:[RKResponseDescriptor class]], @"Expected an object of type RKResponseDescriptor, got '%@'", [responseDescriptor class]);
    responseDescriptor.baseURL = self.baseURL;
    [self.mutableResponseDescriptors addObject:responseDescriptor];
}

- (void)addResponseDescriptorsFromArray:(NSArray *)responseDescriptors
{
    for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
        [self addResponseDescriptor:responseDescriptor];
    }
}

- (void)removeResponseDescriptor:(RKResponseDescriptor *)responseDescriptor
{
    NSParameterAssert(responseDescriptor);
    NSAssert([responseDescriptor isKindOfClass:[RKResponseDescriptor class]], @"Expected an object of type RKResponseDescriptor, got '%@'", [responseDescriptor class]);
    [self.mutableResponseDescriptors removeObject:responseDescriptor];
}

#pragma mark - Fetch Request Blocks

- (NSArray *)fetchRequestBlocks
{
    return [NSArray arrayWithArray:self.mutableFetchRequestBlocks];
}

- (void)addFetchRequestBlock:(RKFetchRequestBlock)block
{
    NSParameterAssert(block);
    [self.mutableFetchRequestBlocks addObject:block];
}

#pragma mark - Queue Management

- (void)enqueueObjectRequestOperation:(RKObjectRequestOperation *)objectRequestOperation
{
    [self.operationQueue addOperation:objectRequestOperation];
}

- (void)cancelAllObjectRequestOperationsWithMethod:(RKRequestMethod)method matchingPathPattern:(NSString *)pathPattern
{
    NSString *methodName = RKStringFromRequestMethod(method);
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:pathPattern];
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[RKObjectRequestOperation class]]) {
            continue;
        }
        
        NSURLRequest *request = [(RKObjectRequestOperation *)operation HTTPRequestOperation].request;
        NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL([request URL], self.baseURL);
        if ((!methodName || [methodName isEqualToString:[request HTTPMethod]]) && [pathMatcher matchesPath:pathAndQueryString tokenizeQueryStrings:NO parsedArguments:nil]) {
            [operation cancel];
        }
    }
}

- (void)enqueueBatchOfObjectRequestOperationsWithRoute:(RKRoute *)route
                                               objects:(NSArray *)objects
                                              progress:(void (^)(NSUInteger numberOfFinishedOperations,
                                                                 NSUInteger totalNumberOfOperations))progress
                                            completion:(void (^)(NSArray *operations))completion {
    NSMutableArray *operations = [[NSMutableArray alloc] initWithCapacity:objects.count];
    for (id object in objects) {
        RKObjectRequestOperation *operation = nil;
        NSURL *URL = [self.router URLWithRoute:route object:object];
        NSAssert(URL, @"Failed to generate URL for route %@ with object %@", route, object);
        if ([route isClassRoute]) {
            operation = [self appropriateObjectRequestOperationWithObject:object method:route.method path:[URL relativeString] parameters:nil];
        } else {
            operation = [self appropriateObjectRequestOperationWithObject:nil method:route.method path:[URL relativeString] parameters:nil];
        }
        [operations addObject:operation];
    }
    return [self enqueueBatchOfObjectRequestOperations:operations progress:progress completion:completion];
}

- (void)enqueueBatchOfObjectRequestOperations:(NSArray *)operations
                                     progress:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progress
                                   completion:(void (^)(NSArray *operations))completion {

    __block dispatch_group_t dispatchGroup = dispatch_group_create();
    NSBlockOperation *batchedOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if (completion) {
                completion(operations);
            }
        });
    }];

    for (RKObjectRequestOperation *operation in operations) {
        void (^originalCompletionBlock)(void) = [operation.completionBlock copy];
        __weak RKObjectRequestOperation *weakOperation = operation;
        [operation setCompletionBlock:^{
            dispatch_queue_t queue = weakOperation.successCallbackQueue ?: dispatch_get_main_queue();
            dispatch_group_async(dispatchGroup, queue, ^{
                if (originalCompletionBlock) {
                    originalCompletionBlock();
                }

                __block NSUInteger numberOfFinishedOperations = 0;
                [operations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([(NSOperation *)obj isFinished]) {
                        numberOfFinishedOperations++;
                    }
                }];

                if (progress) {
                    progress(numberOfFinishedOperations, [operations count]);
                }

                dispatch_group_leave(dispatchGroup);
            });
        }];

        dispatch_group_enter(dispatchGroup);
        [batchedOperation addDependency:operation];

        [self enqueueObjectRequestOperation:operation];
    }
    [self.operationQueue addOperation:batchedOperation];
}

@end

#ifdef _SYSTEMCONFIGURATION_H
NSString *RKStringFromNetworkReachabilityStatus(AFNetworkReachabilityStatus networkReachabilityStatus)
{
    switch (networkReachabilityStatus) {
        case AFNetworkReachabilityStatusNotReachable:     return @"Not Reachable";
        case AFNetworkReachabilityStatusReachableViaWiFi: return @"Reachable via WiFi";
        case AFNetworkReachabilityStatusReachableViaWWAN: return @"Reachable via WWAN";
        case AFNetworkReachabilityStatusUnknown:          return @"Reachability Unknown";
        default:                                          break;
    }
    return nil;
}
#endif
