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
        self.requestSerializer = [RKRequestSerializer serializer];
        self.responseSerializationManager = [RKResponseSerializationManager managerWithDataSerializer:manager.responseSerializer];
    }
    return self;
}

- (NSURL *)baseURL
{
    return self.HTTPRequestOperationManager.baseURL;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)getObjectsAtPath:(NSString *)path
                                  parameters:(NSDictionary *)parameters
                                     success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)getObjectsAtPathForRelationship:(NSString *)relationshipName
                                                   ofObject:(id)object
                                                 parameters:(NSDictionary *)parameters
                                                    success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)getObjectsAtPathForRouteNamed:(NSString *)routeName
                                                   object:(id)object
                                               parameters:(NSDictionary *)parameters
                                                  success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                                                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)GET:(id)object
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)POST:(id)object
                       URLString:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)PUT:(id)object
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)PATCH:(id)object
                        URLString:(NSString *)URLString
                       parameters:(NSDictionary *)parameters
                          success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

- (AFHTTPRequestOperation *)DELETE:(id)object
                         URLString:(NSString *)URLString
                        parameters:(NSDictionary *)parameters
                           success:(void (^)(AFHTTPRequestOperation *operation, RKMappingResult *mappingResult))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not yet implemented." userInfo:nil];
}

@end
