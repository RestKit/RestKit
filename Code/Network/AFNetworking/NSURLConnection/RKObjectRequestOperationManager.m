//
//  RKObjectRequestOperationManager.m
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
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
