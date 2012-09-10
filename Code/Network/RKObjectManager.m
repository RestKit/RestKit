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
#import "NSMutableDictionary+RKAdditions.h"
#import "RKMIMETypes.h"
#import "RKLog.h"

//////////////////////////////////
// Shared Instance

static RKObjectManager  *sharedManager = nil;

///////////////////////////////////

@interface RKObjectManager ()
@property (nonatomic, strong, readwrite) AFHTTPClient *HTTPClient;
@property (nonatomic, strong) NSMutableArray *mutableRequestDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableResponseDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableFetchRequestBlocks;
@end

@implementation RKObjectManager

- (id)initWithHTTPClient:(AFHTTPClient *)client
{
    self = [super init];
    if (self) {
        self.HTTPClient = client;
        [self.HTTPClient registerHTTPOperationClass:[RKHTTPRequestOperation class]];

        self.router = [[RKRouter alloc] initWithBaseURL:client.baseURL];
        self.acceptMIMEType = RKMIMETypeJSON;
        self.operationQueue = [NSOperationQueue new];
        self.mutableRequestDescriptors = [NSMutableArray new];
        self.mutableResponseDescriptors = [NSMutableArray new];
        self.mutableFetchRequestBlocks = [NSMutableArray new];

        self.serializationMIMEType = RKMIMETypeFormURLEncoded;

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
    RKObjectManager *manager = [[self alloc] initWithBaseURL:baseURL];
    return manager;
}

- (void)setAcceptMIMEType:(NSString *)MIMEType
{
//    [self.client setValue:MIMEType forHTTPHeaderField:@"Accept"];
}

- (NSString *)acceptMIMEType
{
//    return [self.client.HTTPHeaders valueForKey:@"Accept"];
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

// TODO: Private, move down...
- (RKRequestDescriptor *)requestDescriptorForObject:(id)object
{
    for (RKRequestDescriptor *requestDescriptor in self.requestDescriptors) {
        if ([object isKindOfClass:requestDescriptor.objectClass]) return requestDescriptor;
    }
    return nil;
}

- (NSMutableURLRequest *)requestWithPathForRouteNamed:(NSString *)routeName
                                               object:(id)object
                                           parameters:(NSDictionary *)parameters
{
    RKRequestMethod method;
    NSURL *URL = [self.router URLForRouteNamed:routeName method:&method object:object];
    NSAssert(URL, @"No route found named '%@'", routeName);
    return [self.HTTPClient requestWithMethod:RKStringFromRequestMethod(method) path:[URL relativeString] parameters:parameters];
}

- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKRequestMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;
{
    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
    NSString *stringMethod = RKStringFromRequestMethod(method);
    NSDictionary *requestParameters = nil;
    RKRequestDescriptor *requestDescriptor = [self requestDescriptorForObject:object];
    if (requestDescriptor) {
        NSError *error = nil;
        NSMutableDictionary *mergedParameters = [[RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error] mutableCopy];
        if (parameters) [mergedParameters reverseMergeWith:parameters];
        requestParameters = mergedParameters;
    } else {
        requestParameters = parameters;
    }

    return [self.HTTPClient requestWithMethod:stringMethod path:requestPath parameters:requestParameters];
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
    RKRequestDescriptor *requestDescriptor = [self requestDescriptorForObject:object];
    if (requestDescriptor) {
        NSError *error = nil;
        NSMutableDictionary *mergedParameters = [[RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error] mutableCopy];
        if (parameters) [mergedParameters reverseMergeWith:parameters];
        requestParameters = mergedParameters;
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

- (BOOL)responseDescriptorsContainsEntityMappings
{
    return [self.responseDescriptors indexOfObjectPassingTest:^BOOL(RKResponseDescriptor *responseDescriptor, NSUInteger idx, BOOL *stop) {
        if ([responseDescriptor.mapping isKindOfClass:[RKEntityMapping class]]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }] != NSNotFound;
}

/**
 TODO: Test cases...
 1) Managed object
 2) Non managed object, request descriptors with entity

 Does it make sense to assume the main queue MOC here?
 */
- (id)objectRequestOperationWithObject:(id)object method:(RKRequestMethod)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSParameterAssert(object);
    NSURLRequest *request = [self requestWithObject:object method:method path:path parameters:parameters];
    RKObjectRequestOperation *operation = nil;
    if ([object isKindOfClass:[NSManagedObject class]] || [self responseDescriptorsContainsEntityMappings]) {
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
    // TODO: Add support for asking the object request operation class if it can handle the response descriptors matching the URL
    // This will enable graceful selection of the appropriate managed vs. unmanaged object request operation
    NSURLRequest *request = [self.HTTPClient requestWithMethod:@"GET" path:path parameters:parameters];
    id operation = [self managedObjectRequestOperationWithRequest:request managedObjectContext:self.managedObjectStore.mainQueueManagedObjectContext success:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)getObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [self objectRequestOperationWithObject:object method:RKRequestMethodGET path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)postObject:(id)object
              path:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
           failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [self objectRequestOperationWithObject:object method:RKRequestMethodPOST path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)putObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [self objectRequestOperationWithObject:object method:RKRequestMethodPUT path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)patchObject:(id)object
               path:(NSString *)path
         parameters:(NSDictionary *)parameters
            success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
            failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [self objectRequestOperationWithObject:object method:RKRequestMethodPATCH path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)deleteObject:(id)object
                path:(NSString *)path
          parameters:(NSDictionary *)parameters
             success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
             failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKObjectRequestOperation *operation = [self objectRequestOperationWithObject:object method:RKRequestMethodDELETE path:path parameters:parameters];
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
