//
//  RKObjectRequestOperationManager.m
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

#import "RKObjectRequestOperationManager.h"

@interface RKObjectRequestOperationManager ()

@end

@implementation RKObjectRequestOperationManager

+ (instancetype)managerWithBaseURL:(NSURL *)baseURL
{
    AFHTTPRequestOperationManager *HTTPRequestOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    return [[self alloc] initWithHTTPRequestOperationManager:HTTPRequestOperationManager];
}

- (id)initWithHTTPRequestOperationManager:(AFHTTPRequestOperationManager *)manager
{
    self = [self init];
    if (self) {
        self.HTTPRequestOperationManager = manager;
        self.requestSerializer = [RKRequestSerializer requestSerializerWithBaseURL:manager.baseURL transportSerializer:manager.requestSerializer];
        self.responseSerializationManager = [RKResponseSerializationManager managerWithTransportSerializer:manager.responseSerializer];
        self.operationQueue = manager.operationQueue;
    }
    return self;
}

- (NSURL *)baseURL
{
    return self.HTTPRequestOperationManager.baseURL;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                     object:(id)object
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPResponseSerializer *responseSerializer = [self.responseSerializationManager serializerWithRequest:request object:object];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = responseSerializer;
    operation.shouldUseCredentialStorage = self.HTTPRequestOperationManager.shouldUseCredentialStorage;
    operation.credential = self.HTTPRequestOperationManager.credential;
    operation.securityPolicy = self.HTTPRequestOperationManager.securityPolicy;
    
    [operation setCompletionBlockWithSuccess:success failure:failure];
    
    return operation;
}

- (AFHTTPRequestOperation *)GETObjectsAtURLForString:(NSString *)URLString
                            parameters:(NSDictionary *)parameters
                               success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:nil method:RKHTTPMethodGET URLString:URLString parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:nil success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)GETObjectsAtURLForRelationship:(NSString *)relationshipName
                                                  ofObject:(id)object
                                                parameters:(NSDictionary *)parameters
                                                   success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithURLForRelationship:relationshipName ofObject:object method:RKHTTPMethodGET parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:object success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)GETObjectsAtURLForRouteNamed:(NSString *)routeName
                                                  object:(id)object
                                              parameters:(NSDictionary *)parameters
                                                 success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithURLForRouteNamed:routeName object:object parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:object success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)GET:(id)object
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object method:RKHTTPMethodGET URLString:URLString parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:object success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)POST:(id)object
                       URLString:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object method:RKHTTPMethodPOST URLString:URLString parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:object success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)PUT:(id)object
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object method:RKHTTPMethodPUT URLString:URLString parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:object success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)PATCH:(id)object
                        URLString:(NSString *)URLString
                       parameters:(NSDictionary *)parameters
                          success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object method:RKHTTPMethodPATCH URLString:URLString parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:object success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)DELETE:(id)object
                         URLString:(NSString *)URLString
                        parameters:(NSDictionary *)parameters
                           success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object method:RKHTTPMethodDELETE URLString:URLString parameters:parameters error:&error];
    if (! request) {
        if (failure) failure(nil, error);
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request object:object success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

@end
