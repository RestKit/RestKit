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

/**
 A serial dispatch queue used for all deserialization of response bodies
 */
static dispatch_queue_t RKResponseMapperSerializationQueue() {
    static dispatch_queue_t serializationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serializationQueue = dispatch_queue_create("org.restkit.response-mapper.serialization", DISPATCH_QUEUE_SERIAL);
    });
    
    return serializationQueue;
}

@interface RKResponseMapperOperation ()
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;
@property (nonatomic, strong, readwrite) NSData *data;
@property (nonatomic, strong, readwrite) NSArray *responseDescriptors;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSDictionary *responseMappingsDictionary;
@property (nonatomic, strong) RKMapperOperation *mapperOperation;
@property (nonatomic, copy) id (^willMapDeserializedResponseBlock)(id deserializedResponseBody);
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
    __block NSError *underlyingError = nil;
    __block id object;
    dispatch_sync(RKResponseMapperSerializationQueue(), ^{
        object = [RKMIMETypeSerialization objectFromData:self.data MIMEType:MIMEType error:&underlyingError];
    });    
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

- (void)cancel
{
    [super cancel];
    [self.mapperOperation cancel];
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
            // NOTE: For alignment with the behavior of loading an empty array or empty dictionary, if there is a nil targetObject we return a nil mappingResult.
            // This informs the caller that operation succeeded, but performed no mapping.
            self.mappingResult = nil;
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
    
    // Invoke the will map deserialized response block
    if (self.willMapDeserializedResponseBlock) {
        parsedBody = self.willMapDeserializedResponseBlock(parsedBody);
        if (! parsedBody) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Mapping was declined due to a `willMapDeserializedResponseBlock` returning nil." };
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorFromMappingResult userInfo:userInfo];
            RKLogError(@"Failed to parse response data: %@", [error localizedDescription]);
            return;
        }
    }

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
    self.mapperOperation = [[RKMapperOperation alloc] initWithObject:sourceObject mappingsDictionary:self.responseMappingsDictionary];
    self.mapperOperation.mappingOperationDataSource = dataSource;
    self.mapperOperation.targetObject = self.targetObject;
    [self.mapperOperation start];
    if (error) *error = self.mapperOperation.error;
    return self.mapperOperation.mappingResult;
}

@end

static inline NSManagedObjectID *RKObjectIDFromObjectIfManaged(id object)
{
    return [object isKindOfClass:[NSManagedObject class]] ? [object objectID] : nil;
}

@interface RKManagedObjectResponseMapperOperation ()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation RKManagedObjectResponseMapperOperation

- (void)cancel
{
    [super cancel];
    [self.operationQueue cancelAllOperations];
}

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    NSParameterAssert(self.managedObjectContext);

    __block NSError *blockError = nil;
    __block RKMappingResult *mappingResult = nil;
    self.operationQueue = [NSOperationQueue new];
    [self.managedObjectContext performBlockAndWait:^{
        // Configure the mapper
        self.mapperOperation = [[RKMapperOperation alloc] initWithObject:sourceObject mappingsDictionary:self.responseMappingsDictionary];
        self.mapperOperation.delegate = self.mapperDelegate;
        
        // Configure a data source to defer execution of connection operations until mapping is complete
        RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                                                                          cache:self.managedObjectCache];
        [self.operationQueue setMaxConcurrentOperationCount:1];
        [self.operationQueue setName:[NSString stringWithFormat:@"Relationship Connection Queue for '%@'", self.mapperOperation]];
        dataSource.operationQueue = self.operationQueue;
        dataSource.parentOperation = self.mapperOperation;
        self.mapperOperation.mappingOperationDataSource = dataSource;
        
        if (NSLocationInRange(self.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))) {
            self.mapperOperation.targetObject = self.targetObject;

            if (self.targetObjectID || self.targetObject) {
                NSManagedObjectID *objectID = self.targetObjectID ?: RKObjectIDFromObjectIfManaged(self.targetObject);
                if (objectID) {
                    if ([objectID isTemporaryID]) RKLogWarning(@"Performing object mapping to temporary target objectID. Results may not be accessible without obtaining a permanent object ID.");
                    NSManagedObject *localObject = [self.managedObjectContext existingObjectWithID:objectID error:&blockError];
                    NSAssert([localObject.managedObjectContext isEqual:self.managedObjectContext], @"Serious Core Data error: requested existing object with ID %@ in context %@, instead got an object reference in context %@. This may indicate that the objectID for your target managed object was obtained using `obtainPermanentIDsForObjects:error:` in the wrong context.", objectID, self.managedObjectContext, [localObject managedObjectContext]);
                    if (! localObject) {
                        RKLogWarning(@"Failed to retrieve existing object with ID: %@", objectID);
                        RKLogCoreDataError(blockError);
                    }
                    self.mapperOperation.targetObject = localObject;
                } else {
                    if (self.mapperOperation.targetObject) RKLogDebug(@"Mapping HTTP response to unmanaged target object with `RKManagedObjectResponseMapperOperation`: %@", self.mapperOperation.targetObject);
                }
            } else {
                RKLogTrace(@"Mapping HTTP response to nil target object...");
            }
        } else {
            RKLogInfo(@"Non-successful state code encountered: performing mapping with nil target object.");
        }

        [self.mapperOperation start];
        blockError = self.mapperOperation.error;
        mappingResult = self.mapperOperation.mappingResult;
    }];
    
    if (self.isCancelled) return nil;

    if (! mappingResult) {
        if (error) *error = blockError;
        return nil;
    }
    
    // Mapping completed without error, allow the connection operations to execute
    if ([self.operationQueue operationCount]) {
        RKLogTrace(@"Awaiting execution of %ld enqueued connection operations: %@", (long) [self.operationQueue operationCount], [self.operationQueue operations]);
        [self.operationQueue waitUntilAllOperationsAreFinished];
    }

    return mappingResult;
}

@end
