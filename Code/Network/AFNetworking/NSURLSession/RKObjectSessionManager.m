//
//  RKObjectSessionManager.m
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKObjectSessionManager.h"

@class AFURLSessionManagerTaskDelegate;

@interface AFHTTPSessionManager ()

- (AFURLSessionManagerTaskDelegate *)delegateForTask:(NSURLSessionTask *)task;

@end

@interface AFURLSessionManagerTaskDelegate : NSObject

@property (nonatomic, strong) id <AFURLResponseSerialization> responseSerializer;

@end

@interface RKObjectSessionManager ()

@end

@implementation RKObjectSessionManager

+ (instancetype)managerWithBaseURL:(NSURL *)baseURL
{
    AFHTTPSessionManager *HTTPSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    return [[self alloc] initWithHTTPSessionManager:HTTPSessionManager];
}

- (id)initWithHTTPSessionManager:(AFHTTPSessionManager *)manager
{
    self = [self init];
    if (self) {
        self.HTTPSessionManager = manager;
        self.requestSerializer = [RKRequestSerializer requestSerializerWithBaseURL:manager.baseURL
                                                               transportSerializer:manager.requestSerializer];
        self.responseSerializationManager = [RKResponseSerializationManager managerWithTransportSerializer:manager.responseSerializer];
    }

    return self;
}

- (NSURL *)baseURL
{
    return self.HTTPSessionManager.baseURL;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                      success:(void (^)(NSURLSessionDataTask *, id))success
                                      failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    AFHTTPResponseSerializer *responseSerializer = [self.responseSerializationManager serializerWithRequest:request object:nil];
    
    __block NSURLSessionDataTask *task =  [self.HTTPSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error)
    {
        if (error) {
            failure(task, error);
        } else {
            success(task, responseObject);
        }
        task = nil;
    }];
    
    [self.HTTPSessionManager delegateForTask:task].responseSerializer = responseSerializer;
    
    
    return task;
}

- (NSURLSessionDataTask *)GETObjectsAtURLForString:(NSString *)URLString
                                        parameters:(NSDictionary *)parameters
                                           success:(void (^)(NSURLSessionDataTask *task, RKMappingResult *mappingResult))success
                                           failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:nil
                                                                      method:RKHTTPMethodGET
                                                                   URLString:URLString
                                                                  parameters:parameters
                                                                       error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)GETObjectsAtURLForRelationship:(NSString *)relationshipName
                                                ofObject:(id)object
                                              parameters:(NSDictionary *)parameters
                                                 success:(void (^)(NSURLSessionDataTask *task, RKMappingResult *mappingResult))success
                                                 failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithURLForRelationship:relationshipName
                                                                                ofObject:object
                                                                                  method:RKHTTPMethodGET
                                                                              parameters:parameters
                                                                                   error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)GETObjectsAtURLForRouteNamed:(NSString *)routeName
                                                object:(id)object
                                            parameters:(NSDictionary *)parameters
                                               success:(void (^)(NSURLSessionDataTask *task, RKMappingResult *mappingResult))success
                                               failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithURLForRouteNamed:routeName
                                                                                object:object
                                                                            parameters:parameters
                                                                                 error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)GET:(id)object URLString:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *, RKMappingResult *))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object
                                                                      method:RKHTTPMethodGET
                                                                   URLString:URLString
                                                                  parameters:parameters
                                                                       error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)POST:(id)object URLString:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *, RKMappingResult *))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object
                                                                      method:RKHTTPMethodPOST
                                                                   URLString:URLString
                                                                  parameters:parameters
                                                                       error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)PUT:(id)object URLString:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *, RKMappingResult *))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object
                                                                      method:RKHTTPMethodPUT
                                                                   URLString:URLString
                                                                  parameters:parameters
                                                                       error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)PATCH:(id)object URLString:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *, RKMappingResult *))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object
                                                                      method:RKHTTPMethodPATCH
                                                                   URLString:URLString
                                                                  parameters:parameters
                                                                       error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)DELETE:(id)object URLString:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *, RKMappingResult *))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithObject:object
                                                                      method:RKHTTPMethodDELETE
                                                                   URLString:URLString
                                                                  parameters:parameters
                                                                       error:&error];
    if (!request) {
        if (failure)
            failure(nil, error);
        return nil;
    }

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                                   success:success
                                                   failure:failure];
    [task resume];
    return task;
}

@end
