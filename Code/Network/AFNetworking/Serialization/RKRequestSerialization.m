//
//  RKRequestSerializer.m
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
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

#import "RKRequestSerialization.h"
#import "RKHTTPUtilities.h"
#import "RKObjectParameterization.h"
#import "RKLog.h"
#import "RKDictionaryUtilities.h"

/**
 Returns the first `RKRequestDescriptor` object from the given array that matches the given object.
 
 @param requestDescriptors An array of `RKRequestDescriptor` objects.
 @param object The object to find a matching request descriptor for.
 @return An `RKRequestDescriptor` object matching the given object, or `nil` if none could be found.
 */
RKRequestDescriptor *RKRequestDescriptorFromArrayMatchingObjectAndMethod(NSArray *requestDescriptors, id object, RKHTTPMethod method);
RKRequestDescriptor *RKRequestDescriptorFromArrayMatchingObjectAndMethod(NSArray *requestDescriptors, id object, RKHTTPMethod method)
{
    Class searchClass = [object class];
    do {
        for (RKRequestDescriptor *requestDescriptor in requestDescriptors) {
            if ([requestDescriptor.objectClass isEqual:searchClass] && (method == requestDescriptor.methods)) return requestDescriptor;
        }
        
        for (RKRequestDescriptor *requestDescriptor in requestDescriptors) {
            if ([requestDescriptor.objectClass isEqual:searchClass] && (method & requestDescriptor.methods)) return requestDescriptor;
        }
        searchClass = [searchClass superclass];
    } while (searchClass);
    
    return nil;
}

@interface RKObjectParameters : NSObject

@property (nonatomic, strong) NSMutableDictionary *parameters;
- (void)addParameters:(NSDictionary *)serialization atRootKeyPath:(NSString *)rootKeyPath inArray:(BOOL)inArray;

@end

@implementation RKObjectParameters

- (id)init
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
    id nonNestedParameters = rootKeyPath ? [parameters objectForKey:rootKeyPath] : parameters;
    id value = [self.parameters objectForKey:rootKey];
    if (value) {
        if ([value isKindOfClass:[NSMutableArray class]]) {
            [value addObject:nonNestedParameters];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *mutableArray = [NSMutableArray arrayWithObjects:value, nonNestedParameters, nil];
            [self.parameters setObject:mutableArray forKey:rootKey];
        } else {
            [NSException raise:NSInvalidArgumentException format:@"Unexpected argument of type '%@': expected an NSDictionary or NSArray.", [value class]];
        }
    } else {
        [self.parameters setObject:(inArray ? @[ nonNestedParameters ] : nonNestedParameters) forKey:rootKey];
    }
}

- (id)requestParameters
{
    if ([self.parameters count] == 0) return nil;
    id valueAtNullKey = [self.parameters objectForKey:[NSNull null]];
    if (valueAtNullKey) {
        if ([self.parameters count] == 1) return valueAtNullKey;
        
        // If we have values at `[NSNull null]` and other key paths, we have an invalid configuration
        [NSException raise:NSInvalidArgumentException format:@"Invalid request descriptor configuration: The request descriptors specify that multiple objects be serialized at incompatible key paths. Cannot serialize objects at the `nil` root key path in the same request as objects with a non-nil root key path. Please check your request descriptors and try again."];
    }
    return self.parameters;
}

@end

@interface RKRequestSerializer ()
@property (nonatomic, strong) NSMutableArray *mutableRequestDescriptors;
@property (nonatomic, strong, readwrite) RKRouter *router;
@end

@implementation RKRequestSerializer

+ (instancetype)requestSerializerWithBaseURL:(NSURL *)baseURL transportSerializer:(AFHTTPRequestSerializer *)transportSerializer
{
    RKRouter *router = [RKRouter routerWithBaseURL:baseURL];
    RKRequestSerializer *requestSerializer = [[[self class] alloc] initWithRouter:router transportSerializer:transportSerializer];
    return requestSerializer;
}

- (id)initWithRouter:(RKRouter *)router transportSerializer:(AFHTTPRequestSerializer *)transportSerializer
{
    self = [super init];
    if (self) {
        _router = router;
        _transportSerializer = transportSerializer;
        _mutableRequestDescriptors = [NSMutableArray new];
    }
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Failed to call designated initializer. Call `%@` instead.",
                                           NSStringFromSelector(@selector(requestSerializerWithBaseURL:transportSerializer:))]
                                 userInfo:nil];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self) {
        _mutableRequestDescriptors = [[coder decodeObjectForKey:NSStringFromSelector(@selector(requestDescriptors))] mutableCopy];
        _router = [coder decodeObjectForKey:NSStringFromSelector(@selector(router))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.requestDescriptors forKey:NSStringFromSelector(@selector(requestDescriptors))];
    [coder encodeObject:self.router forKey:NSStringFromSelector(@selector(router))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    RKRequestSerializer *requestSerializer = [[[self class] allocWithZone:zone] init];
    requestSerializer.router = [self.router copyWithZone:zone];
    requestSerializer.mutableRequestDescriptors = [self.mutableRequestDescriptors mutableCopyWithZone:zone];
    return requestSerializer;
}

- (NSArray *)requestDescriptors
{
    return self.mutableRequestDescriptors;
}

- (void)addRequestDescriptor:(RKRequestDescriptor *)requestDescriptor
{
    NSParameterAssert(requestDescriptor);
    if ([self.requestDescriptors containsObject:requestDescriptor]) return;
    NSAssert([requestDescriptor isKindOfClass:[RKRequestDescriptor class]], @"Expected an object of type RKRequestDescriptor, got '%@'", [requestDescriptor class]);
    [self.requestDescriptors enumerateObjectsUsingBlock:^(RKRequestDescriptor *registeredDescriptor, NSUInteger idx, BOOL *stop) {
        NSAssert(!([registeredDescriptor.objectClass isEqual:requestDescriptor.objectClass] && (requestDescriptor.methods == registeredDescriptor.methods)), @"Cannot add request descriptor: An existing descriptor is already registered for the class '%@' and HTTP method'%@'.", requestDescriptor.objectClass, RKStringDescribingHTTPMethods(requestDescriptor.methods));
    }];
    [self.mutableRequestDescriptors addObject:requestDescriptor];
}

- (void)addRequestDescriptors:(NSArray *)requestDescriptors
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

- (id)mergedParametersWithObject:(id)object method:(RKHTTPMethodOptions)method parameters:(NSDictionary *)parameters
{
    NSArray *objectsToParameterize = ([object isKindOfClass:[NSArray class]] || object == nil) ? object : @[ object ];
    RKObjectParameters *objectParameters = [RKObjectParameters new];
    for (id objectToParameterize in objectsToParameterize) {
        RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndMethod(self.requestDescriptors, objectToParameterize, method);
        if ((method != RKHTTPMethodGET && method != RKHTTPMethodDELETE) && requestDescriptor) {
            NSError *error = nil;
            NSDictionary *parametersForObject = [RKObjectParameterization parametersWithObject:objectToParameterize requestDescriptor:requestDescriptor error:&error];
            if (error) {
                RKLogError(@"Object parameterization failed while building %@ request for object '%@': %@", RKStringFromHTTPMethod(method), objectToParameterize, error);
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

#pragma mark - Building Requests

- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKHTTPMethod)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                     error:(NSError * __autoreleasing *)error
{
    NSURL *URL = (URLString) ? [NSURL URLWithString:URLString] : [self.router URLForObject:object method:method];
    NSParameterAssert(URL);
    id requestParameters = [self mergedParametersWithObject:object method:method parameters:parameters];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPMethod:RKStringFromHTTPMethod(method)];
    request = [[self.transportSerializer requestBySerializingRequest:request withParameters:requestParameters error:error] mutableCopy];

	return request;
}

- (NSMutableURLRequest *)requestWithURLForRouteNamed:(NSString *)routeName
                                              object:(id)object
                                          parameters:(NSDictionary *)parameters
                                               error:(NSError *__autoreleasing *)error
{
    RKHTTPMethodOptions method;
    NSURL *URL = [self.router URLForRouteNamed:routeName method:&method object:object];
    NSAssert(URL, @"No route found named '%@'", routeName);
    return [self requestWithObject:object method:method URLString:[URL absoluteString] parameters:parameters error:error];
}

- (NSMutableURLRequest *)requestWithURLForRelationship:(NSString *)relationship
                                              ofObject:(id)object
                                                method:(RKHTTPMethod)method
                                            parameters:(NSDictionary *)parameters
                                                 error:(NSError *__autoreleasing *)error
{
    NSURL *URL = [self.router URLForRelationship:relationship ofObject:object method:method];
    NSAssert(URL, @"No relationship route found for the '%@' class with the name '%@'", NSStringFromClass([object class]), relationship);
    return [self requestWithObject:object method:method URLString:[URL absoluteString] parameters:parameters error:error];
}

- (NSMutableURLRequest *)multipartFormRequestWithObject:(id)object
                                                 method:(RKHTTPMethodOptions)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError *__autoreleasing *)error
{
    NSURL *URL = (URLString) ? [NSURL URLWithString:URLString] : [self.router URLForObject:object method:method];
    NSParameterAssert(URL);
    id requestParameters = [self mergedParametersWithObject:object method:method parameters:parameters];
    
    return [self.transportSerializer multipartFormRequestWithMethod:RKStringFromHTTPMethod(method) URLString:[URL absoluteString] parameters:requestParameters constructingBodyWithBlock:block error:error];
}

@end
