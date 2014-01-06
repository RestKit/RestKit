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

@interface RKRequestSerializer ()
@property (nonatomic, strong) NSMutableArray *mutableRequestDescriptors;
@end

@implementation RKRequestSerializer

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

#pragma mark - Building Requests

- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKHTTPMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                                     error:(NSError * __autoreleasing *)error
{
    NSMutableURLRequest* request;
//    if (parameters && !([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"])) {
//        // NOTE: If the HTTP client has been subclasses, then the developer may be trying to perform signing on the request
//        NSDictionary *parametersForClient = [self.HTTPClient isMemberOfClass:[AFHTTPClient class]] ? nil : parameters;
//        request = [self.HTTPClient requestWithMethod:method path:path parameters:parametersForClient];
//
//        NSError *error = nil;
//        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.HTTPClient.stringEncoding));
//        [request setValue:[NSString stringWithFormat:@"%@; charset=%@", self.requestSerializationMIMEType, charset] forHTTPHeaderField:@"Content-Type"];
//        NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:self.requestSerializationMIMEType error:&error];
//        [request setHTTPBody:requestBody];
//	} else {
//        request = [self.HTTPClient requestWithMethod:method path:path parameters:parameters];
//    }

	return request;
}

- (NSMutableURLRequest *)requestWithPathForRouteNamed:(NSString *)routeName
                                               object:(id)object
                                           parameters:(NSDictionary *)parameters
                                                error:(NSError *__autoreleasing *)error
{
    RKHTTPMethodOptions method;
    NSURL *URL = [self.router URLForRouteNamed:routeName method:&method object:object];
    NSAssert(URL, @"No route found named '%@'", routeName);
    return [self requestWithMethod:RKStringFromHTTPMethod(method) URLString:[URL absoluteString] parameters:parameters error:error];
}

- (NSMutableURLRequest *)requestWithPathForRelationship:(NSString *)relationship
                                               ofObject:(id)object
                                                 method:(RKHTTPMethodOptions)method
                                             parameters:(NSDictionary *)parameters
                                                  error:(NSError *__autoreleasing *)error
{
    NSURL *URL = [self.router URLForRelationship:relationship ofObject:object method:method];
    NSAssert(URL, @"No relationship route found for the '%@' class with the name '%@'", NSStringFromClass([object class]), relationship);
    return [self requestWithMethod:RKStringFromHTTPMethod(method) URLString:[URL relativeString] parameters:parameters error:error];
}

//- (id)mergedParametersWithObject:(id)object method:(RKHTTPMethodOptions)method parameters:(NSDictionary *)parameters
//{
//    NSArray *objectsToParameterize = ([object isKindOfClass:[NSArray class]] || object == nil) ? object : @[ object ];
//    RKObjectParameters *objectParameters = [RKObjectParameters new];
//    for (id objectToParameterize in objectsToParameterize) {
//        RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(self.requestDescriptors, objectToParameterize, method);
//        if ((method != RKHTTPMethodGET && method != RKHTTPMethodDELETE) && requestDescriptor) {
//            NSError *error = nil;
//            NSDictionary *parametersForObject = [RKObjectParameterization parametersWithObject:objectToParameterize requestDescriptor:requestDescriptor error:&error];
//            if (error) {
//                RKLogError(@"Object parameterization failed while building %@ request for object '%@': %@", RKStringFromRequestMethod(method), objectToParameterize, error);
//                return nil;
//            }
//            // Ensure that a single object inputted as an array is emitted as an array when serialized
//            BOOL inArray = ([object isKindOfClass:[NSArray class]] && [object count] == 1);
//            [objectParameters addParameters:parametersForObject atRootKeyPath:requestDescriptor.rootKeyPath inArray:inArray];
//        }
//    }
//    id requestParameters = [objectParameters requestParameters];
//
//    // Merge the extra parameters if possible
//    if ([requestParameters isKindOfClass:[NSArray class]] && parameters) {
//        [NSException raise:NSInvalidArgumentException format:@"Cannot merge parameters with array of object representations serialized with a nil root key path."];
//    } else if (requestParameters && parameters) {
//        requestParameters = RKDictionaryByMergingDictionaryWithDictionary(requestParameters, parameters);
//    } else if (parameters && !requestParameters) {
//        requestParameters = parameters;
//    }
//
//    return requestParameters;
//}
//
//- (NSMutableURLRequest *)requestWithObject:(id)object
//                                    method:(RKHTTPMethodOptions)method
//                                      path:(NSString *)path
//                                parameters:(NSDictionary *)parameters
//                                     error:(NSError *__autoreleasing *)error
//{
////    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
////    id requestParameters = [self mergedParametersWithObject:object method:method parameters:parameters];
////    return [self requestWithMethod:RKStringFromRequestMethod(method) path:requestPath parameters:requestParameters];
//}

- (NSMutableURLRequest *)multipartFormRequestWithObject:(id)object
                                                 method:(RKHTTPMethodOptions)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError *__autoreleasing *)error
{
//    NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
//    id requestParameters = [self mergedParametersWithObject:object method:method parameters:parameters];
//    NSMutableURLRequest *multipartRequest = [self.HTTPClient multipartFormRequestWithMethod:RKStringFromRequestMethod(method)
//                                                                                       path:requestPath
//                                                                                 parameters:requestParameters
//                                                                  constructingBodyWithBlock:block];
//    return multipartRequest;
    return nil;
}

@end
