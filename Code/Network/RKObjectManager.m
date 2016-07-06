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
#import "AFRKNetworking.h"

#import "RKObjectManager.h"
#import "RKObjectParameterization.h"
#import "RKRequestDescriptor.h"
#import "RKResponseDescriptor.h"
#import "RKDictionaryUtilities.h"
#import "RKMIMETypes.h"
#import "RKLog.h"
#import "RKMIMETypeSerialization.h"
#import "RKPathMatcher.h"
#import "RKMappingErrors.h"
#import "RKPaginator.h"
#import "RKDynamicMapping.h"
#import "RKRelationshipMapping.h"
#import "RKObjectRequestOperation.h"
#import "RKRouter.h"
#import "RKRoute.h"
#import "RKRouteSet.h"

#if __has_include("CoreData.h")
#   define RKCoreDataIncluded
#   import "RKManagedObjectStore.h"
#   import "RKManagedObjectRequestOperation.h"
#endif

#if !__has_feature(objc_arc)
#error RestKit must be built with ARC. \
You can turn on ARC for only RestKit files by adding "-fobjc-arc" to the build phase for each of its files.
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
 @param method The method for which to select matching response descriptors.
 @return An `NSArray` object whose elements are `RKResponseDescriptor` objects matching the given path and method.
 */
#ifdef RKCoreDataIncluded
static NSArray *RKFilteredArrayOfResponseDescriptorsMatchingPathAndMethod(NSArray *responseDescriptors, NSString *path, RKRequestMethod method)
{
    NSIndexSet *indexSet = [responseDescriptors indexesOfObjectsPassingTest:^BOOL(RKResponseDescriptor *responseDescriptor, NSUInteger idx, BOOL *stop) {
        return [responseDescriptor matchesPath:path] && (method & responseDescriptor.method);
    }];
    return [responseDescriptors objectsAtIndexes:indexSet];
}
#endif

/**
 Returns the first `RKRequestDescriptor` object from the given array that matches the given object.
 
 @param requestDescriptors An array of `RKRequestDescriptor` objects.
 @param object The object to find a matching request descriptor for.
 @return An `RKRequestDescriptor` object matching the given object, or `nil` if none could be found.
 */
RKRequestDescriptor *RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(NSArray *requestDescriptors, id object, RKRequestMethod requestMethod);
RKRequestDescriptor *RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(NSArray *requestDescriptors, id object, RKRequestMethod requestMethod)
{
    Class searchClass = [object class];
    do {
        for (RKRequestDescriptor *requestDescriptor in requestDescriptors) {
            if ([requestDescriptor.objectClass isEqual:searchClass] && (requestMethod == requestDescriptor.method)) return requestDescriptor;
        }
        
        for (RKRequestDescriptor *requestDescriptor in requestDescriptors) {
            if ([requestDescriptor.objectClass isEqual:searchClass] && (requestMethod & requestDescriptor.method)) return requestDescriptor;
        }
        searchClass = [searchClass superclass];
    } while (searchClass);
    
    return nil;
}

extern NSString *RKStringDescribingRequestMethod(RKRequestMethod method);

@interface RKObjectParameters : NSObject

@property (nonatomic, strong) NSMutableDictionary *parameters;
- (void)addParameters:(NSDictionary *)serialization atRootKeyPath:(NSString *)rootKeyPath inArray:(BOOL)inArray;

@end

@implementation RKObjectParameters

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.parameters = [NSMutableDictionary new];
    }
    return self;
}

- (void)addParameters:(NSDictionary *)parameters atRootKeyPath:(NSString *)rootKeyPath inArray:(BOOL)inArray
{
    id rootKey = rootKeyPath ?: [NSNull null];
    id nonNestedParameters = rootKeyPath ? parameters[rootKeyPath] : parameters;
    id value = (self.parameters)[rootKey];
    if (value) {
        if ([value isKindOfClass:[NSMutableArray class]]) {
            [value addObject:nonNestedParameters];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *mutableArray = [NSMutableArray arrayWithObjects:value, nonNestedParameters, nil];
            (self.parameters)[rootKey] = mutableArray;
        } else {
            [NSException raise:NSInvalidArgumentException format:@"Unexpected argument of type '%@': expected an NSDictionary or NSArray.", [value class]];
        }
    } else {
        (self.parameters)[rootKey] = (inArray ? @[ nonNestedParameters ] : nonNestedParameters);
    }
}

- (id)requestParameters
{
    if ([self.parameters count] == 0) return nil;
    id valueAtNullKey = (self.parameters)[[NSNull null]];
    if (valueAtNullKey) {
        if ([self.parameters count] == 1) return valueAtNullKey;

        // If we have values at `[NSNull null]` and other key paths, we have an invalid configuration
        [NSException raise:NSInvalidArgumentException format:@"Invalid request descriptor configuration: The request descriptors specify that multiple objects be serialized at incompatible key paths. Cannot serialize objects at the `nil` root key path in the same request as objects with a non-nil root key path. Please check your request descriptors and try again."];
    }
    return self.parameters;
}

@end

/**
 Visits all mappings accessible via relationships or dynamic mapping in an object graph starting from a given mapping.
 */
@interface RKMappingGraphVisitor : NSObject

@property (nonatomic, readonly) NSSet *mappings;

- (instancetype)initWithMapping:(RKMapping *)mapping NS_DESIGNATED_INITIALIZER;

@end

@interface RKMappingGraphVisitor ()
@property (nonatomic, readwrite) NSMutableSet *mutableMappings;
@end

@implementation RKMappingGraphVisitor

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@, use designated initilizer -initWithMapping:", NSStringFromClass([self class])]
                                 userInfo:nil];
    return [self init];
}

- (instancetype)initWithMapping:(RKMapping *)mapping
{
    self = [super init];
    if (self) {
        self.mutableMappings = [NSMutableSet set];
        [self visitMapping:mapping];
    }
    return self;
}

- (NSSet *)mappings
{
    return self.mutableMappings;
}

- (void)visitMapping:(RKMapping *)mapping
{
    if ([self.mappings containsObject:mapping]) return;
    [self.mutableMappings addObject:mapping];
    
    if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        RKDynamicMapping *dynamicMapping = (RKDynamicMapping *)mapping;
        for (RKMapping *nestedMapping in dynamicMapping.objectMappings) {
            [self visitMapping:nestedMapping];
        }
    } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        RKObjectMapping *objectMapping = (RKObjectMapping *)mapping;
        for (RKRelationshipMapping *relationshipMapping in objectMapping.relationshipMappings) {
            [self visitMapping:relationshipMapping.mapping];
        }
    }
}

@end

/**
 Returns `YES` if the given array of `RKResponseDescriptor` objects contains an `RKEntityMapping` anywhere in its object graph.
 
 @param responseDescriptors An array of `RKResponseDescriptor` objects.
 @return `YES` if the `mapping` property of any of the response descriptor objects in the given array is an instance of `RKEntityMapping`, else `NO`.
 */
#ifdef RKCoreDataIncluded
static BOOL RKDoesArrayOfResponseDescriptorsContainEntityMapping(NSArray *responseDescriptors)
{
    // Visit all mappings accessible from the object graphs of all response descriptors
    NSMutableSet *accessibleMappings = [NSMutableSet set];
    for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
        if (! [accessibleMappings containsObject:responseDescriptor.mapping]) {
            RKMappingGraphVisitor *graphVisitor = [[RKMappingGraphVisitor alloc] initWithMapping:responseDescriptor.mapping];
            [accessibleMappings unionSet:graphVisitor.mappings];
        }
    }
    
    // Enumerate all mappings and search for an `RKEntityMapping`
    for (RKMapping *mapping in accessibleMappings) {
        if ([mapping isKindOfClass:[RKEntityMapping class]]) {
            return YES;
        }
        
        if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
            RKDynamicMapping *dynamicMapping = (RKDynamicMapping *)mapping;
            if ([dynamicMapping.objectMappings count] == 0) {
                // Likely means that there is a representation block, assume `YES`
                return YES;
            }
        }
    }
    
    return NO;
}
#endif

BOOL RKDoesArrayOfResponseDescriptorsContainOnlyEntityMappings(NSArray *responseDescriptors);
BOOL RKDoesArrayOfResponseDescriptorsContainOnlyEntityMappings(NSArray *responseDescriptors)
{
#ifdef RKCoreDataIncluded
    // Visit all mappings accessible from the object graphs of all response descriptors
    NSMutableSet *accessibleMappings = [NSMutableSet set];
    for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
        if (! [accessibleMappings containsObject:responseDescriptor.mapping]) {
            RKMappingGraphVisitor *graphVisitor = [[RKMappingGraphVisitor alloc] initWithMapping:responseDescriptor.mapping];
            [accessibleMappings unionSet:graphVisitor.mappings];
        }
    }

    NSMutableSet *mappingClasses = [NSMutableSet set];
    // Enumerate all mappings and search for an `RKEntityMapping`
    for (RKMapping *mapping in accessibleMappings) {
        if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
            [mappingClasses addObjectsFromArray:[[(RKDynamicMapping *)mapping objectMappings] valueForKey:@"class"]];
        } else {
            [mappingClasses addObject:mapping.class];
        }
    }

    if ([mappingClasses count]) {
        for (Class mappingClass in mappingClasses) {
            if (! [mappingClass isSubclassOfClass:[RKEntityMapping class]]) {
                return NO;
            }
        }
        return YES;
    }
#endif
    
    return NO;
}

static BOOL RKDoesArrayOfResponseDescriptorsContainMappingForClass(NSArray *responseDescriptors, Class classToBeMapped)
{
    // Visit all mappings accessible from the object graphs of all response descriptors
    NSMutableSet *accessibleMappings = [NSMutableSet set];
    for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
        if (! [accessibleMappings containsObject:responseDescriptor.mapping]) {
            RKMappingGraphVisitor *graphVisitor = [[RKMappingGraphVisitor alloc] initWithMapping:responseDescriptor.mapping];
            [accessibleMappings unionSet:graphVisitor.mappings];
        }
    }
    
    // Enumerate all mappings and search for a mapping matching the class
    for (RKMapping *mapping in accessibleMappings) {
        if ([mapping isKindOfClass:[RKObjectMapping class]]) {
            if ([[(RKObjectMapping *)mapping objectClass] isSubclassOfClass:classToBeMapped]) return YES;
        }
        
        if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
            RKDynamicMapping *dynamicMapping = (RKDynamicMapping *)mapping;
            for (RKObjectMapping *mapping in dynamicMapping.objectMappings) {
                if ([[(RKObjectMapping *)mapping objectClass] isSubclassOfClass:classToBeMapped]) return YES;
            }
        }
    }
    
    return NO;
}

static NSString *RKMIMETypeFromAFHTTPClientParameterEncoding(AFRKHTTPClientParameterEncoding encoding)
{
    switch (encoding) {
        case AFRKFormURLParameterEncoding:
            return RKMIMETypeFormURLEncoded;
            break;
            
        case AFRKJSONParameterEncoding:
            return RKMIMETypeJSON;
            break;
            
        case AFRKPropertyListParameterEncoding:
            break;
            
        default:
            RKLogWarning(@"RestKit is unable to infer the appropriate request serialization MIME Type from an `AFHTTPClientParameterEncoding` value of %d: defaulting to `RKMIMETypeFormURLEncoded`", encoding);
            break;
    }
    
    return RKMIMETypeFormURLEncoded;
}

@interface AFRKHTTPClient ()
@property (readonly, nonatomic, strong) NSURLCredential *defaultCredential;
@end

///////////////////////////////////

@interface RKObjectManager ()
@property (nonatomic, strong) NSMutableArray *mutableRequestDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableResponseDescriptors;
@property (nonatomic, strong) NSMutableArray *mutableFetchRequestBlocks;
@property (nonatomic, strong) NSMutableArray *registeredHTTPRequestOperationClasses;
@property (nonatomic, strong) NSMutableArray *registeredObjectRequestOperationClasses;
@property (nonatomic, strong) NSMutableArray *registeredManagedObjectRequestOperationClasses;

@end

@implementation RKObjectManager

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@, use designated initilizer -initWithHTTPClient:", NSStringFromClass([self class])]
                                 userInfo:nil];
    return [self init];
}

- (instancetype)initWithHTTPClient:(AFRKHTTPClient *)client
{
    self = [super init];
    if (self) {
        self.HTTPClient = client;
        self.router = [[RKRouter alloc] initWithBaseURL:client.baseURL];        
        self.operationQueue = [NSOperationQueue new];
        self.mutableRequestDescriptors = [NSMutableArray new];
        self.mutableResponseDescriptors = [NSMutableArray new];
        self.mutableFetchRequestBlocks = [NSMutableArray new];
        self.registeredHTTPRequestOperationClasses = [NSMutableArray new];
        self.registeredManagedObjectRequestOperationClasses = [NSMutableArray new];
        self.registeredObjectRequestOperationClasses = [NSMutableArray new];
        self.requestSerializationMIMEType = RKMIMETypeFromAFHTTPClientParameterEncoding(client.parameterEncoding);        

        // Set shared manager if nil
        if (nil == sharedManager) {
            [RKObjectManager setSharedManager:self];
        }
    }

    return self;
}

+ (instancetype)sharedManager
{
    return sharedManager;
}

+ (void)setSharedManager:(RKObjectManager *)manager
{
    sharedManager = manager;
}

+ (RKObjectManager *)managerWithBaseURL:(NSURL *)baseURL
{
    RKObjectManager *manager = [[self alloc] initWithHTTPClient:[AFRKHTTPClient clientWithBaseURL:baseURL]];
    [manager.HTTPClient registerHTTPOperationClass:[AFRKJSONRequestOperation class]];
    [manager setAcceptHeaderWithMIMEType:RKMIMETypeJSON];
    manager.requestSerializationMIMEType = RKMIMETypeFormURLEncoded;
    return manager;
}

- (void)setAcceptHeaderWithMIMEType:(NSString *)MIMEType;
{
    [self.HTTPClient setDefaultHeader:@"Accept" value:MIMEType];
}

- (NSURL *)baseURL
{
    return self.HTTPClient.baseURL;
}

- (NSDictionary *)defaultHeaders
{
    return self.HTTPClient.defaultHeaders;
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
        // NOTE: If the HTTP client has been subclasses, then the developer may be trying to perform signing on the request
        NSDictionary *parametersForClient = [self.HTTPClient isMemberOfClass:[AFRKHTTPClient class]] ? nil : parameters;
        request = [self.HTTPClient requestWithMethod:method path:path parameters:parametersForClient];
		
        NSError *error = nil;
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.HTTPClient.stringEncoding));
        [request setValue:[NSString stringWithFormat:@"%@; charset=%@", self.requestSerializationMIMEType, charset] forHTTPHeaderField:@"Content-Type"];
        NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:self.requestSerializationMIMEType error:&error];
        [request setHTTPBody:requestBody];
	} else {
        request = [self.HTTPClient requestWithMethod:method path:path parameters:parameters];
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

- (id)mergedParametersWithObject:(id)object method:(RKRequestMethod)method parameters:(NSDictionary *)parameters
{
    NSArray *objectsToParameterize = ([object isKindOfClass:[NSArray class]] || object == nil) ? object : @[ object ];
    RKObjectParameters *objectParameters = [RKObjectParameters new];
    for (id objectToParameterize in objectsToParameterize) {
        RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(self.requestDescriptors, objectToParameterize, method);
        if ((method != RKRequestMethodGET && method != RKRequestMethodDELETE) && requestDescriptor) {
            NSError *error = nil;
            NSDictionary *parametersForObject = [RKObjectParameterization parametersWithObject:objectToParameterize requestDescriptor:requestDescriptor error:&error];
            if (error) {
                RKLogError(@"Object parameterization failed while building %@ request for object '%@': %@", RKStringFromRequestMethod(method), objectToParameterize, error);
                return nil;
            }
            // Ensure that a single object inputted as an array is emitted as an array when serialized
            BOOL inArray = ([object isKindOfClass:[NSArray class]] && [object count] == 1);
            [objectParameters addParameters:parametersForObject atRootKeyPath:requestDescriptor.rootKeyPath inArray:inArray];
        }
    }
    id requestParameters = [objectParameters requestParameters];

    // Merge the extra parameters if possible
    if ([requestParameters isKindOfClass:[NSArray class]] && parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot merge parameters with array of object representations serialized with a nil root key path."];
    } else if (requestParameters && parameters) {
        requestParameters = RKDictionaryByMergingDictionaryWithDictionary(requestParameters, parameters);
    } else if (parameters && !requestParameters) {
        requestParameters = parameters;
    }

    return requestParameters;
}

- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKRequestMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;
{
    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
    id requestParameters = [self mergedParametersWithObject:object method:method parameters:parameters];
    return [self requestWithMethod:RKStringFromRequestMethod(method) path:requestPath parameters:requestParameters];
}

- (NSMutableURLRequest *)multipartFormRequestWithObject:(id)object
                                                 method:(RKRequestMethod)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFRKMultipartFormData> formData))block
{
    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
    id requestParameters = [self mergedParametersWithObject:object method:method parameters:parameters];
    NSMutableURLRequest *multipartRequest = [self.HTTPClient multipartFormRequestWithMethod:RKStringFromRequestMethod(method)
                                                                                       path:requestPath
                                                                                 parameters:requestParameters
                                                                  constructingBodyWithBlock:block];
    return multipartRequest;
}

#pragma mark - Registering Subclasses

- (BOOL)registerRequestOperationClass:(Class)operationClass
{
    Class managedObjectRequestOperationClass = NSClassFromString(@"RKManagedObjectRequestOperation");
    if (managedObjectRequestOperationClass && [operationClass isSubclassOfClass:managedObjectRequestOperationClass]) {
        [self.registeredManagedObjectRequestOperationClasses removeObject:operationClass];
        [self.registeredManagedObjectRequestOperationClasses insertObject:operationClass atIndex:0];
        return YES;
    } else if ([operationClass isSubclassOfClass:[RKObjectRequestOperation class]]) {
        [self.registeredObjectRequestOperationClasses removeObject:operationClass];
        [self.registeredObjectRequestOperationClasses insertObject:operationClass atIndex:0];
        return YES;
    } else if ([operationClass isSubclassOfClass:[RKHTTPRequestOperation class]]) {
        [self.registeredHTTPRequestOperationClasses removeObject:operationClass];
        [self.registeredHTTPRequestOperationClasses insertObject:operationClass atIndex:0];
        return YES;
    }
    
    return NO;
}

- (void)unregisterRequestOperationClass:(Class)operationClass
{
    [self.registeredHTTPRequestOperationClasses removeObject:operationClass];
    [self.registeredObjectRequestOperationClasses removeObject:operationClass];
    [self.registeredManagedObjectRequestOperationClasses removeObject:operationClass];
}

- (Class)requestOperationClassForRequest:(NSURLRequest *)request fromRegisteredClasses:(NSArray *)registeredClasses
{
    Class requestOperationClass = nil;
    NSEnumerator *enumerator = [registeredClasses reverseObjectEnumerator];
    while (requestOperationClass = [enumerator nextObject]) {
        if ([requestOperationClass canProcessRequest:request]) break;
        requestOperationClass = nil;
    }    
    return requestOperationClass;
}

#pragma mark - Object Request Operations

- (void)copyStateFromHTTPClientToHTTPRequestOperation:(AFRKHTTPRequestOperation *)operation
{
    operation.credential = self.HTTPClient.defaultCredential;
    operation.allowsInvalidSSLCertificate = self.HTTPClient.allowsInvalidSSLCertificate;
#ifdef _AFRKNETWORKING_PIN_SSL_CERTIFICATES_
    operation.SSLPinningMode = self.HTTPClient.defaultSSLPinningMode;
#endif
}

- (RKObjectRequestOperation *)objectRequestOperationWithRequest:(NSURLRequest *)request
                                                        success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                        failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    return [self objectRequestOperationWithRequest:request responseDescriptors:self.responseDescriptors success:success failure:failure];
}

- (RKObjectRequestOperation *)objectRequestOperationWithRequest:(NSURLRequest *)request
                                            responseDescriptors:(NSArray *)responseDescriptors
                                                        success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                        failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    Class HTTPRequestOperationClass = [self requestOperationClassForRequest:request fromRegisteredClasses:self.registeredHTTPRequestOperationClasses] ?: [RKHTTPRequestOperation class];
    RKHTTPRequestOperation *HTTPRequestOperation = [[HTTPRequestOperationClass alloc] initWithRequest:request];
    [self copyStateFromHTTPClientToHTTPRequestOperation:HTTPRequestOperation];
    Class objectRequestOperationClass = [self requestOperationClassForRequest:request fromRegisteredClasses:self.registeredObjectRequestOperationClasses] ?: [RKObjectRequestOperation class];
    RKObjectRequestOperation *operation = [[objectRequestOperationClass alloc] initWithHTTPRequestOperation:HTTPRequestOperation responseDescriptors:responseDescriptors];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    return operation;
}

#ifdef RKCoreDataIncluded
- (RKManagedObjectRequestOperation *)managedObjectRequestOperationWithRequest:(NSURLRequest *)request
                                                          managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                      success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                                      failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    return [self managedObjectRequestOperationWithRequest:request responseDescriptors:self.responseDescriptors managedObjectContext:managedObjectContext success:success failure:failure];
}

- (RKManagedObjectRequestOperation *)managedObjectRequestOperationWithRequest:(NSURLRequest *)request
                                                          responseDescriptors:(NSArray *)responseDescriptors
                                                         managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                      success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                                      failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    Class HTTPRequestOperationClass = [self requestOperationClassForRequest:request fromRegisteredClasses:self.registeredHTTPRequestOperationClasses] ?: [RKHTTPRequestOperation class];
    RKHTTPRequestOperation *HTTPRequestOperation = [[HTTPRequestOperationClass alloc] initWithRequest:request];
    [self copyStateFromHTTPClientToHTTPRequestOperation:HTTPRequestOperation];
    Class objectRequestOperationClass = [self requestOperationClassForRequest:request fromRegisteredClasses:self.registeredManagedObjectRequestOperationClasses] ?: [RKManagedObjectRequestOperation class];
    RKManagedObjectRequestOperation *operation = (RKManagedObjectRequestOperation *)[[objectRequestOperationClass alloc] initWithHTTPRequestOperation:HTTPRequestOperation responseDescriptors:responseDescriptors];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.managedObjectContext = managedObjectContext ?: self.managedObjectStore.mainQueueManagedObjectContext;
    operation.managedObjectCache = self.managedObjectStore.managedObjectCache;
    operation.fetchRequestBlocks = self.fetchRequestBlocks;
    return operation;
}
#endif

- (id)appropriateObjectRequestOperationWithObject:(id)object
                                           method:(RKRequestMethod)method
                                             path:(NSString *)path
                                       parameters:(NSDictionary *)parameters
{
    RKObjectRequestOperation *operation = nil;
    NSURLRequest *request = [self requestWithObject:object method:method path:path parameters:parameters];
    NSDictionary *routingMetadata = nil;
    if (! path) {
        RKRoute *route = [self.router.routeSet routeForObject:object method:method];
        NSDictionary *interpolatedParameters = nil;
        NSURL *URL = [self URLWithRoute:route object:object interpolatedParameters:&interpolatedParameters];
        if (! URL) {
            RKLogError(@"Failed to construct a URL from the provided object. Returning nil.");
            return operation;
        }
        path = [URL relativeString];
        
        routingMetadata = @{ @"routing": @{ @"parameters": interpolatedParameters, @"route": route },
                             @"query": @{ @"parameters": parameters ?: @{} } };
    } else if (parameters) {
        routingMetadata = @{ @"query": @{ @"parameters": parameters } };
    }
    
#ifdef RKCoreDataIncluded
    NSArray *matchingDescriptors = RKFilteredArrayOfResponseDescriptorsMatchingPathAndMethod(self.responseDescriptors, path, method);
    BOOL containsEntityMapping = RKDoesArrayOfResponseDescriptorsContainEntityMapping(matchingDescriptors);
    BOOL isManagedObjectRequestOperation = (containsEntityMapping || [object isKindOfClass:[NSManagedObject class]]);
    
    if (isManagedObjectRequestOperation && !self.managedObjectStore) RKLogWarning(@"Asked to create an `RKManagedObjectRequestOperation` object, but managedObjectStore is nil.");
    if (isManagedObjectRequestOperation && self.managedObjectStore) {
        // Construct a Core Data operation
        NSManagedObjectContext *managedObjectContext = [object respondsToSelector:@selector(managedObjectContext)] ? [object managedObjectContext] : self.managedObjectStore.mainQueueManagedObjectContext;
        operation = [self managedObjectRequestOperationWithRequest:request responseDescriptors:matchingDescriptors managedObjectContext:managedObjectContext success:nil failure:nil];

        if ([object isKindOfClass:[NSManagedObject class]]) {
            static NSPredicate *temporaryObjectsPredicate = nil;
            if (! temporaryObjectsPredicate) temporaryObjectsPredicate = [NSPredicate predicateWithFormat:@"objectID.isTemporaryID == YES"];
            NSSet *temporaryObjects = [[managedObjectContext insertedObjects] filteredSetUsingPredicate:temporaryObjectsPredicate];
            if ([temporaryObjects count]) {
                RKLogInfo(@"Asked to perform object request for NSManagedObject with temporary object IDs: Obtaining permanent ID before proceeding.");
                __block BOOL _blockSuccess;
                __block NSError *_blockError;

                [[object managedObjectContext] performBlockAndWait:^{
                    _blockSuccess = [[object managedObjectContext] obtainPermanentIDsForObjects:[temporaryObjects allObjects] error:&_blockError];
                }];
                if (! _blockSuccess) RKLogWarning(@"Failed to obtain permanent ID for object %@: %@", object, _blockError);
            }
        }
    } else {
        // Non-Core Data operation
        operation = [self objectRequestOperationWithRequest:request responseDescriptors:matchingDescriptors success:nil failure:nil];
    }
#else
    // Non-Core Data operation
    operation = [self objectRequestOperationWithRequest:request success:nil failure:nil];
#endif
    
    if (RKDoesArrayOfResponseDescriptorsContainMappingForClass(self.responseDescriptors, [object class])) operation.targetObject = object;
    operation.mappingMetadata = routingMetadata;
    return operation;
}

- (NSURL *)URLWithRoute:(RKRoute *)route object:(id)object interpolatedParameters:(NSDictionary **)interpolatedParameters
{
    NSString *path = nil;
    if (object) {
        RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:route.pathPattern];
        path = [pathMatcher pathFromObject:object addingEscapes:route.shouldEscapePath interpolatedParameters:interpolatedParameters];
    } else {
        // When there is no object, the path pattern is our complete path
        path = route.pathPattern;
        if (interpolatedParameters) *interpolatedParameters = @{};
    }
    return [NSURL URLWithString:path relativeToURL:self.baseURL];
}

- (void)getObjectsAtPathForRelationship:(NSString *)relationshipName
                               ofObject:(id)object
                             parameters:(NSDictionary *)parameters
                                success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    RKRoute *route = [self.router.routeSet routeForRelationship:relationshipName ofClass:[object class] method:RKRequestMethodGET];
    NSDictionary *interpolatedParameters = nil;
    NSURL *URL = [self URLWithRoute:route object:object interpolatedParameters:&interpolatedParameters];
    NSAssert(URL, @"Failed to generate URL for relationship named '%@' for object: %@", relationshipName, object);
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:[URL relativeString] parameters:parameters];
    
    operation.mappingMetadata = @{ @"routing": @{ @"parameters": interpolatedParameters, @"route": route },
                                   @"query": @{ @"parameters": parameters ?: @{} } };
    
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)getObjectsAtPathForRouteNamed:(NSString *)routeName
                               object:(id)object
                           parameters:(NSDictionary *)parameters
                              success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                              failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSParameterAssert(routeName);    
    RKRoute *route = [self.router.routeSet routeForName:routeName];
    NSDictionary *interpolatedParameters = nil;
    NSURL *URL = [self URLWithRoute:route object:object interpolatedParameters:&interpolatedParameters];
    NSAssert(URL, @"No route found named '%@'", routeName);
    NSAssert(route.method & RKRequestMethodGET, @"Expected route named '%@' to specify a GET, but it does not", routeName);
    
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:[URL relativeString] parameters:parameters];
    
    operation.mappingMetadata = @{ @"routing": @{ @"parameters": interpolatedParameters, @"route": route },
                                   @"query": @{ @"parameters": parameters ?: @{} } };
    
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (void)getObjectsAtPath:(NSString *)path
              parameters:(NSDictionary *)parameters
                 success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                 failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure
{
    NSParameterAssert(path);
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
    NSAssert(object || path, @"Cannot make a request without an object or a path.");
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
    NSAssert(object || path, @"Cannot make a request without an object or a path.");
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
    NSAssert(object || path, @"Cannot make a request without an object or a path.");
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
    NSAssert(object || path, @"Cannot make a request without an object or a path.");
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
    NSAssert(object || path, @"Cannot make a request without an object or a path.");
    RKObjectRequestOperation *operation = [self appropriateObjectRequestOperationWithObject:object method:RKRequestMethodDELETE path:path parameters:parameters];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [self enqueueObjectRequestOperation:operation];
}

- (RKPaginator *)paginatorWithPathPattern:(NSString *)pathPattern
{
    return [self paginatorWithPathPattern:pathPattern parameters:nil];
}

- (RKPaginator *)paginatorWithPathPattern:(NSString *)pathPattern parameters:(NSDictionary *)parameters
{
    NSAssert(self.paginationMapping, @"Cannot instantiate a paginator when `paginationMapping` is nil.");
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:pathPattern parameters:parameters];
    RKPaginator *paginator = [[self.paginationMapping.objectClass alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:self.responseDescriptors];
#ifdef RKCoreDataIncluded
    paginator.managedObjectContext = self.managedObjectStore.mainQueueManagedObjectContext;
    paginator.managedObjectCache = self.managedObjectStore.managedObjectCache;
    paginator.fetchRequestBlocks = self.fetchRequestBlocks;
#endif
    paginator.operationQueue = self.operationQueue;
    Class HTTPOperationClass = [self requestOperationClassForRequest:request fromRegisteredClasses:self.registeredHTTPRequestOperationClasses];
    if (HTTPOperationClass) [paginator setHTTPOperationClass:HTTPOperationClass];
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
        NSAssert(!([registeredDescriptor.objectClass isEqual:requestDescriptor.objectClass] && (requestDescriptor.method == registeredDescriptor.method)), @"Cannot add request descriptor: An existing descriptor is already registered for the class '%@' and HTTP method'%@'.", requestDescriptor.objectClass, RKStringDescribingRequestMethod(requestDescriptor.method));
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

#ifdef RKCoreDataIncluded

- (NSArray *)fetchRequestBlocks
{
    return [NSArray arrayWithArray:self.mutableFetchRequestBlocks];
}

- (void)addFetchRequestBlock:(NSFetchRequest *(^)(NSURL *URL))block
{
    NSParameterAssert(block);
    [self.mutableFetchRequestBlocks addObject:block];
}

#endif

#pragma mark - Queue Management

- (void)enqueueObjectRequestOperation:(RKObjectRequestOperation *)objectRequestOperation
{
    [self.operationQueue addOperation:objectRequestOperation];
}

- (NSArray *)enqueuedObjectRequestOperationsWithMethod:(RKRequestMethod)method matchingPathPattern:(NSString *)pathPattern
{
    NSMutableArray *matches = [NSMutableArray array];
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:pathPattern];
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[RKObjectRequestOperation class]]) {
            continue;
        }
        NSURLRequest *request = [(RKObjectRequestOperation *)operation HTTPRequestOperation].request;
        NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL([request URL], self.baseURL);
        
        RKRequestMethod operationMethod = RKRequestMethodFromString([request HTTPMethod]);
        if ((method & operationMethod) && [pathMatcher matchesPath:pathAndQueryString tokenizeQueryStrings:NO parsedArguments:nil]) {
            [matches addObject:operation];
        }
    }
    return [matches copy];
}

- (void)cancelAllObjectRequestOperationsWithMethod:(RKRequestMethod)method matchingPathPattern:(NSString *)pathPattern
{
    for (RKObjectRequestOperation *operation in [self enqueuedObjectRequestOperationsWithMethod:method matchingPathPattern:pathPattern]) {
        [operation cancel];
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
        NSDictionary *interpolatedParameters = nil;
        NSURL *URL = [self URLWithRoute:route object:object interpolatedParameters:&interpolatedParameters];
        NSAssert(URL, @"Failed to generate URL for route %@ with object %@", route, object);
        if ([route isClassRoute]) {
            operation = [self appropriateObjectRequestOperationWithObject:object method:route.method path:[URL relativeString] parameters:nil];
        } else {
            operation = [self appropriateObjectRequestOperationWithObject:nil method:route.method path:[URL relativeString] parameters:nil];
        }
        operation.mappingMetadata = @{ @"routing": interpolatedParameters, @"route": route };
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
#if !OS_OBJECT_USE_OBJC
        dispatch_release(dispatchGroup);
#endif
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
NSString *RKStringFromNetworkReachabilityStatus(AFRKNetworkReachabilityStatus networkReachabilityStatus)
{
    switch (networkReachabilityStatus) {
        case AFRKNetworkReachabilityStatusNotReachable:     return @"Not Reachable";
        case AFRKNetworkReachabilityStatusReachableViaWiFi: return @"Reachable via WiFi";
        case AFRKNetworkReachabilityStatusReachableViaWWAN: return @"Reachable via WWAN";
        case AFRKNetworkReachabilityStatusUnknown:          return @"Reachability Unknown";
        default:                                          break;
    }
    return nil;
}
#endif
