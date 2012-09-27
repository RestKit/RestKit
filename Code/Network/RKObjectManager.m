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

#import "RKObjectManager.h"
#import "RKObjectParameterization.h"
#import "RKManagedObjectStore.h"
#import "RKRequestDescriptor.h"
#import "RKResponseDescriptor.h"
#import "RKDictionaryUtilities.h"
#import "RKMIMETypes.h"
#import "RKLog.h"
#import "RKMIMETypeSerialization.h"

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
static NSArray * RKFilteredArrayOfResponseDescriptorsMatchingPath(NSArray *responseDescriptors, NSString *path)
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
static RKRequestDescriptor * RKRequestDescriptorFromArrayMatchingObject(NSArray *requestDescriptors, id object)
{
    for (RKRequestDescriptor *requestDescriptor in requestDescriptors) {
        if ([requestDescriptor matchesObject:object]) return requestDescriptor;
    }
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

///////////////////////////////////

@interface RKObjectManager ()
@property (nonatomic, strong, readwrite) AFHTTPClient *HTTPClient;
@property (nonatomic, strong) NSMutableArray *mutableRequestDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableResponseDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableFetchRequestBlocks;
@property (nonatomic, strong) NSString *acceptHeaderValue;
@end

@implementation RKObjectManager

- (id)initWithHTTPClient:(AFHTTPClient *)client
{
    self = [super init];
    if (self) {
        self.HTTPClient = client;

        self.router = [[RKRouter alloc] initWithBaseURL:client.baseURL];
        self.acceptHeaderValue = RKMIMETypeJSON;
        self.operationQueue = [NSOperationQueue new];
        self.mutableRequestDescriptors = [NSMutableArray new];
        self.mutableResponseDescriptors = [NSMutableArray new];
        self.mutableFetchRequestBlocks = [NSMutableArray new];

        self.requestSerializationMIMEType = RKMIMETypeFormURLEncoded;

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
    return manager;
}

// NOTE: This implementation could just use the default headers on AFHTTPClient, but this
// feels less intrusive.
- (void)setAcceptHeaderWithMIMEType:(NSString *)MIMEType;
{
    self.acceptHeaderValue = MIMEType;
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Collection Loaders

//- (RKObjectPaginator *)paginatorWithPathPattern:(NSString *)pathPattern
//{
//    RKURL *patternURL = [[self baseURL] URLByAppendingResourcePath:resourcePathPattern];
//    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL
//                                                              mappingProvider:self.mappingProvider];
//    paginator.configurationDelegate = self;
//    return paginator;
//}

/**
 This method is the `RKObjectManager` analog for the method of the same name on `AFHTTPClient`.
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.HTTPClient.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.HTTPClient.defaultHeaders];
    if (self.acceptHeaderValue) [request setValue:self.acceptHeaderValue forHTTPHeaderField:@"Accept"];

    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AFQueryStringFromParametersWithEncoding(parameters, self.HTTPClient.stringEncoding)]];
            [request setURL:url];
        } else {
            NSError *error = nil;
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.HTTPClient.stringEncoding));
            [request setValue:[NSString stringWithFormat:@"%@; charset=%@", self.requestSerializationMIMEType, charset] forHTTPHeaderField:@"Content-Type"];
            NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:self.requestSerializationMIMEType error:&error];
            [request setHTTPBody:requestBody];
        }
    }

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
    if (requestDescriptor) {
        NSError *error = nil;
        requestParameters = [[RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error] mutableCopy];
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

    return [self.HTTPClient multipartFormRequestWithMethod:stringMethod path:requestPath parameters:requestParameters constructingBodyWithBlock:block];
}

- (RKObjectRequestOperation *)objectRequestOperationWithRequest:(NSURLRequest *)request
                                                        success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                        failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.responseDescriptors];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    return operation;
}

- (RKManagedObjectRequestOperation *)managedObjectRequestOperationWithRequest:(NSURLRequest *)request
                                                         managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                      success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                                      failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.responseDescriptors];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.managedObjectContext = managedObjectContext;
    operation.managedObjectCache = self.managedObjectStore.managedObjectCache;
    operation.fetchRequestBlocks = self.fetchRequestBlocks;
    return operation;
}

// TODO: Unit test me!
// non-managed object, nil path
// managed object, given path
// nil object, path contains response descriptor with entity mapping
// nil object, path does not 
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
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:object method:RKRequestMethodDELETE path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (NSArray *)requestDescriptors
{
    return [NSArray arrayWithArray:self.mutableRequestDescriptors];
}

- (void)addRequestDescriptor:(RKRequestDescriptor *)requestDescriptor
{
    NSParameterAssert(requestDescriptor);
    NSAssert([requestDescriptor isKindOfClass:[RKRequestDescriptor class]], @"Expected an object of type RKRequestDescriptor, got '%@'", [requestDescriptor class]);
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

- (NSArray *)fetchRequestBlocks
{
    return [NSArray arrayWithArray:self.mutableFetchRequestBlocks];
}

- (void)addFetchRequestBlock:(RKFetchRequestBlock)block
{
    NSParameterAssert(block);
    [self.mutableFetchRequestBlocks addObject:block];
}

- (void)enqueueObjectRequestOperation:(RKObjectRequestOperation *)objectRequestOperation
{
    [self.operationQueue addOperation:objectRequestOperation];
}

@end

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
