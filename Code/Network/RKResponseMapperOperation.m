//
//  RKResponseMapperOperation.m
//  RestKit
//
//  Created by Blake Watters on 8/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKObjectMappingOperationDataSource.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKLog.h"
#import "RKResponseDescriptor.h"
#import "RKPathMatcher.h"
#import "RKHTTPUtilities.h"
#import "RKResponseMapperOperation.h"
#import "RKMappingErrors.h"
#import "RKMIMETypeSerialization.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

NSError *RKErrorFromMappingResult(RKMappingResult *mappingResult)
{
    NSArray *collection = [mappingResult array];
    NSString *description = nil;
    if ([collection count] > 0) {
        description = [[collection valueForKeyPath:@"errorMessage"] componentsJoinedByString:@", "];
    } else {
        RKLogWarning(@"Expected mapping result to contain at least one object to construct an error");
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:collection, RKObjectMapperErrorObjectsKey,
                              description, NSLocalizedDescriptionKey, nil];

    NSError *error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorFromMappingResult userInfo:userInfo];
    return error;
}

static NSError *RKUnprocessableClientErrorFromResponse(NSHTTPURLResponse *response)
{
    NSCAssert(NSLocationInRange(response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassClientError)), @"Expected response status code to be in the 400-499 range, instead got %ld", (long) response.statusCode);
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:[NSString stringWithFormat:@"Loaded an unprocessable client error response (%ld)", (long) response.statusCode] forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[response URL] forKey:NSURLErrorFailingURLErrorKey];
    
    return [[NSError alloc] initWithDomain:RKErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
}

@interface RKResponseMapperOperation ()
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;
@property (nonatomic, strong, readwrite) NSData *data;
@property (nonatomic, strong, readwrite) NSArray *responseDescriptors;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSDictionary *responseMappingsDictionary;
@end

@interface RKResponseMapperOperation (ForSubclassEyesOnly)
- (id)parseResponseData:(NSError **)error;
- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error;
- (BOOL)hasEmptyResponse;
@end

@implementation RKResponseMapperOperation

- (id)initWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data responseDescriptors:(NSArray *)responseDescriptors
{
    NSParameterAssert(response);
    NSParameterAssert(responseDescriptors);
    
    self = [super init];
    if (self) {
        self.response = response;
        self.data = data;
        self.responseDescriptors = responseDescriptors;
        self.responseMappingsDictionary = [self buildResponseMappingsDictionary];
        self.treatsEmptyResponseAsSuccess = YES;
    }

    return self;
}

- (id)parseResponseData:(NSError **)error
{
    NSString *MIMEType = [self.response MIMEType];
    NSError *underlyingError = nil;
    id object = [RKMIMETypeSerialization objectFromData:self.data MIMEType:MIMEType error:&underlyingError];
    if (! object) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:[NSString stringWithFormat:@"Loaded an unprocessable response (%ld) with content type '%@'", (long) self.response.statusCode, MIMEType]
                    forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:[self.response URL] forKey:NSURLErrorFailingURLErrorKey];
        [userInfo setValue:underlyingError forKey:NSUnderlyingErrorKey];
        NSError *HTTPError = [[NSError alloc] initWithDomain:RKErrorDomain code:NSURLErrorCannotParseResponse userInfo:userInfo];

        if (error) *error = HTTPError;

        return nil;
    }
    return object;
}

- (NSDictionary *)buildResponseMappingsDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (RKResponseDescriptor *responseDescriptor in self.responseDescriptors) {
        if ([responseDescriptor matchesResponse:self.response]) {
            id key = responseDescriptor.keyPath ? responseDescriptor.keyPath : [NSNull null];
            [dictionary setObject:responseDescriptor.mapping forKey:key];
        }
    }

    return dictionary;
}

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ is an abstract operation.",
                                           NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (BOOL)hasEmptyResponse
{
    // NOTE: Comparison to single string whitespace character to support Ruby on Rails `render :nothing => true`
    static NSData *whitespaceData = nil;
    if (! whitespaceData) whitespaceData = [[NSData alloc] initWithBytes:" " length:1];

    NSUInteger length = [self.data length];
    return (length == 0 || (length == 1 && [self.data isEqualToData:whitespaceData]));
}

- (void)main
{
    if (self.isCancelled) return;

    BOOL isClientError = NSLocationInRange(self.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassClientError));

    // If we are an error response and empty, we emit an error that the content is unmappable
    if (isClientError && [self hasEmptyResponse]) {
        self.error = RKUnprocessableClientErrorFromResponse(self.response);
        return;
    }

    // If we are successful and empty, we may optionally consider the response mappable (i.e. 204 response or 201 with no body)
    if ([self hasEmptyResponse] && self.treatsEmptyResponseAsSuccess) {
        if (self.targetObject) {
            self.mappingResult = [[RKMappingResult alloc] initWithDictionary:[NSDictionary dictionaryWithObject:self.targetObject forKey:[NSNull null]]];
        } else {
            self.mappingResult = [[RKMappingResult alloc] initWithDictionary:[NSDictionary dictionary]];
        }

        return;
    }

    // Parse the response
    NSError *error;
    id parsedBody = [self parseResponseData:&error];
    if (self.isCancelled) return;
    if (! parsedBody) {
        RKLogError(@"Failed to parse response data: %@", [error localizedDescription]);
        self.error = error;
        return;
    }
    if (self.isCancelled) return;

    // Object map the response
    self.mappingResult = [self performMappingWithObject:parsedBody error:&error];
    
    // If the response is a client error return either the mapping error or the mapped result to the caller as the error
    if (isClientError) {
        if ([self.mappingResult count] > 0) {
            error = RKErrorFromMappingResult(self.mappingResult);
        } else {
            // We encountered a client error that we could not map, throw unprocessable error
            if (! error) error = RKUnprocessableClientErrorFromResponse(self.response);
        }
        self.error = error;
        return;
    }
    
    if (! self.mappingResult) {
        self.error = error;
        return;
    }
}

@end

@implementation RKObjectResponseMapperOperation

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:sourceObject mappingsDictionary:self.responseMappingsDictionary];
    mapper.mappingOperationDataSource = dataSource;
    [mapper start];
    if (error) *error = mapper.error;
    return mapper.mappingResult;
}

@end

static inline NSManagedObjectID *RKObjectIDFromObjectIfManaged(id object)
{
    return [object isKindOfClass:[NSManagedObject class]] ? [object objectID] : nil;
}

@implementation RKManagedObjectResponseMapperOperation

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    NSParameterAssert(self.managedObjectContext);

    __block NSError *blockError = nil;
    __block RKMappingResult *mappingResult = nil;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [self.managedObjectContext performBlockAndWait:^{
        // Configure the mapper
        RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:sourceObject mappingsDictionary:self.responseMappingsDictionary];
        mapper.delegate = self.mapperDelegate;
        
        // Configure a data source to defer execution of connection operations until mapping is complete
        RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                                                                          cache:self.managedObjectCache];
        [operationQueue setMaxConcurrentOperationCount:1];
        [operationQueue setName:[NSString stringWithFormat:@"Relationship Connection Queue for '%@'", mapper]];
        dataSource.operationQueue = operationQueue;
        dataSource.parentOperation = mapper;
        mapper.mappingOperationDataSource = dataSource;
        
        if (NSLocationInRange(self.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))) {
            mapper.targetObject = self.targetObject;

            NSManagedObjectID *objectID = self.targetObjectID ?: RKObjectIDFromObjectIfManaged(self.targetObject);
            if (objectID) {
                if ([objectID isTemporaryID]) RKLogWarning(@"Performing object mapping to temporary target objectID. Results may not be accessible without obtaining a permanent object ID.");
                NSManagedObject *localObject = [self.managedObjectContext existingObjectWithID:objectID error:&blockError];
                if (! localObject) {
                    RKLogWarning(@"Failed to retrieve existing object with ID: %@", objectID);
                    RKLogCoreDataError(blockError);
                }
                mapper.targetObject = localObject;
            }
        } else {
            RKLogInfo(@"Non-successful state code encountered: performing mapping with nil target object.");
        }

        [mapper start];
        blockError = mapper.error;
        mappingResult = mapper.mappingResult;
    }];

    if (! mappingResult) {
        if (error) *error = blockError;
        return nil;
    }
    
    // Mapping completed without error, allow the connection operations to execute
    RKLogDebug(@"Awaiting execution of %ld enqueued connection operations: %@", (long) [operationQueue operationCount], [operationQueue operations]);
    [operationQueue waitUntilAllOperationsAreFinished];

    return mappingResult;
}

@end
