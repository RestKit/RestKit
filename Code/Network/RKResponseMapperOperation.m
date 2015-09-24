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

#import <RestKit/Network/RKPathMatcher.h>
#import <RestKit/Network/RKResponseDescriptor.h>
#import <RestKit/Network/RKResponseMapperOperation.h>
#import <RestKit/ObjectMapping/RKHTTPUtilities.h>
#import <RestKit/ObjectMapping/RKMappingErrors.h>
#import <RestKit/ObjectMapping/RKObjectMappingOperationDataSource.h>
#import <RestKit/Support/RKDictionaryUtilities.h>
#import <RestKit/Support/RKLog.h>
#import <RestKit/Support/RKMIMETypeSerialization.h>

#ifdef _COREDATADEFINES_H
#if __has_include("RKCoreData.h")
#define RKCoreDataIncluded
#import <RestKit/CoreData/RKManagedObjectMappingOperationDataSource.h>
#endif
#endif

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

NSError *RKErrorFromMappingResult(RKMappingResult *mappingResult)
{
    NSArray *collection = [mappingResult array];
    NSString *description = nil;
    if ([collection count] > 0) {
        description = [[collection valueForKeyPath:@"description"] componentsJoinedByString:@", "];
    } else {
        description = @"Expected mapping result to contain at least one object to construct an error";
        RKLogWarning(@"%@", description);
    }
    NSDictionary *userInfo = @{RKObjectMapperErrorObjectsKey: collection,
                              NSLocalizedDescriptionKey: description};

    NSError *error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorFromMappingResult userInfo:userInfo];
    return error;
}

static NSIndexSet *RKErrorStatusCodes()
{
    static NSIndexSet *errorStatusCodes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        errorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 200)];
    });
    
    return errorStatusCodes;
}

static NSError *RKUnprocessableErrorFromResponse(NSHTTPURLResponse *response)
{
    NSCAssert([RKErrorStatusCodes() containsIndex:response.statusCode], @"Expected response status code to be in the 400-599 range, instead got %ld", (long) response.statusCode);
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:[NSString stringWithFormat:@"Loaded an unprocessable error response (%ld)", (long) response.statusCode] forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[response URL] forKey:NSURLErrorFailingURLErrorKey];
    
    return [[NSError alloc] initWithDomain:RKErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
}

NSString *RKStringFromIndexSet(NSIndexSet *indexSet); // Defined in RKResponseDescriptor.m
static NSString *RKMatchFailureDescriptionForResponseDescriptorWithResponse(RKResponseDescriptor *responseDescriptor, NSHTTPURLResponse *response)
{
    if (responseDescriptor.statusCodes && ![responseDescriptor.statusCodes containsIndex:response.statusCode]) {
        return [NSString stringWithFormat:@"response status code %ld is not within the range %@", (long) response.statusCode, RKStringFromIndexSet(responseDescriptor.statusCodes)];
    }
    
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(response.URL, responseDescriptor.baseURL);
    if (responseDescriptor.baseURL && !RKURLIsRelativeToURL(response.URL, responseDescriptor.baseURL)) {
        // Not relative to the baseURL
        return [NSString stringWithFormat:@"response URL '%@' is not relative to the baseURL '%@'.", response.URL, responseDescriptor.baseURL];
    }
    
    // Must be a path pattern mismatch
    return [NSString stringWithFormat:@"response path '%@' did not match the path pattern '%@'.", pathAndQueryString, responseDescriptor.pathPattern];
}

static NSString *RKFailureReasonErrorStringForResponseDescriptorsMismatchWithResponse(NSArray *responseDescriptors, NSHTTPURLResponse *response)
{
    NSMutableString *failureReason = [NSMutableString string];
    [failureReason appendFormat:@"A %ld response was loaded from the URL '%@', which failed to match all (%ld) response descriptors:",
     (long) response.statusCode, response.URL, (long) [responseDescriptors count]];
    
    for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
        [failureReason appendFormat:@"\n  <RKResponseDescriptor: %p baseURL=%@ pathPattern=%@ statusCodes=%@> failed to match: %@",
         responseDescriptor, responseDescriptor.baseURL, responseDescriptor.pathPattern,
         responseDescriptor.statusCodes ? RKStringFromIndexSet(responseDescriptor.statusCodes) : responseDescriptor.statusCodes,
         RKMatchFailureDescriptionForResponseDescriptorWithResponse(responseDescriptor, response)];
    }
    
    return failureReason;
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
@property (nonatomic, strong, readwrite) NSURLRequest *request;
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;
@property (nonatomic, strong, readwrite) NSData *data;
@property (nonatomic, strong, readwrite) NSArray *responseDescriptors;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSArray *matchingResponseDescriptors;
@property (nonatomic, strong, readwrite) NSDictionary *responseMappingsDictionary;
@property (nonatomic, strong, readwrite) NSDictionary *responseMappingArgumentsDictionary;
@property (nonatomic, strong) RKMapperOperation *mapperOperation;
@property (nonatomic, copy) id (^willMapDeserializedResponseBlock)(id);
@property (nonatomic, copy) void(^didFinishMappingBlock)(RKMappingResult *, NSError *);
@end

@interface RKResponseMapperOperation (ForSubclassEyesOnly)
- (id)parseResponseData:(NSError **)error;
- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasEmptyResponse;
@end

@implementation RKResponseMapperOperation

#pragma mark Data Source Registration

static NSMutableDictionary *RKRegisteredResponseMapperOperationDataSourceClasses = nil;

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RKRegisteredResponseMapperOperationDataSourceClasses = [NSMutableDictionary new];
    });
}

+ (void)registerMappingOperationDataSourceClass:(Class<RKMappingOperationDataSource>)dataSourceClass
{
    if (dataSourceClass && ![(Class)dataSourceClass conformsToProtocol:@protocol(RKMappingOperationDataSource)]) {
        [NSException raise:NSInvalidArgumentException format:@"Registered data source class '%@' does not conform to the `RKMappingOperationDataSource` protocol.", NSStringFromClass(dataSourceClass)];
    }
    
    if (dataSourceClass) {
        RKRegisteredResponseMapperOperationDataSourceClasses[(id<NSCopying>)self] = dataSourceClass;
    } else {
        [RKRegisteredResponseMapperOperationDataSourceClasses removeObjectForKey:(id<NSCopying>)self];
    }
}

#pragma mark 

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@, use designated initilizer -initWithRequest:response:data:responseDescriptors:", NSStringFromClass([self class])]
                                 userInfo:nil];
    return [self init];
}

- (instancetype)initWithRequest:(NSURLRequest *)request
             response:(NSHTTPURLResponse *)response
                 data:(NSData *)data
  responseDescriptors:(NSArray *)responseDescriptors;
{
    NSParameterAssert(request);
    NSParameterAssert(response);
    NSParameterAssert(responseDescriptors);
    
    self = [super init];
    if (self) {
        self.request = request;
        self.response = response;
        self.data = data;
        self.responseDescriptors = responseDescriptors;
        self.matchingResponseDescriptors = [self buildMatchingResponseDescriptors];
        self.responseMappingsDictionary = [self buildResponseMappingsDictionary];
        self.responseMappingArgumentsDictionary = [self buildResponseMappingArgumentsDictionary];
        self.treatsEmptyResponseAsSuccess = YES;
        self.mappingMetadata = @{}; // Initialize the metadata
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

- (NSArray *)buildMatchingResponseDescriptors
{
    NSIndexSet *indexSet = [self.responseDescriptors indexesOfObjectsPassingTest:^BOOL(RKResponseDescriptor *responseDescriptor, NSUInteger idx, BOOL *stop) {
        return [responseDescriptor matchesResponse:self.response] && (RKRequestMethodFromString(self.request.HTTPMethod) & responseDescriptor.method);
    }];
    return [self.responseDescriptors objectsAtIndexes:indexSet];
}

- (NSDictionary *)buildResponseMappingsDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (RKResponseDescriptor *responseDescriptor in self.matchingResponseDescriptors) {
        dictionary[(responseDescriptor.keyPath ?: [NSNull null])] = responseDescriptor.mapping;
    }

    return dictionary;
}

- (NSDictionary *)buildResponseMappingArgumentsDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (RKResponseDescriptor *responseDescriptor in self.matchingResponseDescriptors) {
        
        NSDictionary *arguments = [responseDescriptor parsedArgumentsFromResponse:self.response];
        if (arguments)
        {
            // We don't add nil keypath at an [NSNull null] key, because that causes a crash later
            // in RKDictionaryByMergingDictionaryWithDictionary
            if (responseDescriptor.keyPath)
            {
                [dictionary setObject:arguments forKey:responseDescriptor.keyPath];
            }
            else
            {
                [dictionary addEntriesFromDictionary:arguments];
            }
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

- (void)setMappingMetadata:(NSDictionary *)mappingMetadata
{
    NSDictionary *HTTPMetadata = @{ @"HTTP": @{ @"request":  @{ @"URL": self.request.URL, @"method": self.request.HTTPMethod, @"headers": [self.request allHTTPHeaderFields] ?: @{} },
                                                @"response": @{ @"URL": self.response.URL, @"headers": [self.response allHeaderFields] ?: @{} } } };
    _mappingMetadata = RKDictionaryByMergingDictionaryWithDictionary(HTTPMetadata, mappingMetadata);
    
    if (self.responseMappingArgumentsDictionary)
    {
        NSDictionary *argumentsMetadata = @{ @"network" : @{ @"arguments" : self.responseMappingArgumentsDictionary } };
        _mappingMetadata = RKDictionaryByMergingDictionaryWithDictionary(argumentsMetadata, _mappingMetadata);
    }
}

- (void)cancel
{
    BOOL cancelledBeforeExecution = ![self isExecuting] && ![self isCancelled];
    
    [super cancel];
    [self.mapperOperation cancel];
 
    // NOTE: If we are cancelled before being started, then `main` and the `completionBlock` are never executed. We must ensure that we invoke `didFinishMappingBlock`, see Github issue #1494
    if (cancelledBeforeExecution) {
        [self willFinish];
    }
}

- (void)willFinish
{
    if (self.isCancelled && !self.error) self.error = [NSError errorWithDomain:RKErrorDomain code:RKOperationCancelledError userInfo:@{ NSLocalizedDescriptionKey: @"The operation was cancelled." }];
    
    @synchronized(self) {
        if (self.didFinishMappingBlock) {
            if (self.error) self.didFinishMappingBlock(nil, self.error);
            else self.didFinishMappingBlock(self.mappingResult, nil);
            [self setDidFinishMappingBlock:nil];
        }
    }
}

- (void)main
{
    if (self.isCancelled) return [self willFinish];

    BOOL isErrorStatusCode = [RKErrorStatusCodes() containsIndex:self.response.statusCode];
    
    // If we are an error response and empty, we emit an error that the content is unmappable
    if (isErrorStatusCode && [self hasEmptyResponse]) {
        self.error = RKUnprocessableErrorFromResponse(self.response);
        [self willFinish];
        return;
    }

    // If we are successful and empty, we may optionally consider the response mappable (i.e. 204 response or 201 with no body)
    if ([self hasEmptyResponse] && self.treatsEmptyResponseAsSuccess) {
        if (self.targetObject) {
            self.mappingResult = [[RKMappingResult alloc] initWithDictionary:@{[NSNull null]: self.targetObject}];
        } else {
            // NOTE: For alignment with the behavior of loading an empty array or empty dictionary, if there is a nil targetObject we return a nil mappingResult.
            // This informs the caller that operation succeeded, but performed no mapping.
            self.mappingResult = nil;
        }

        [self willFinish];
        return;
    }

    // Parse the response
    NSError *error;
    id parsedBody = [self parseResponseData:&error];
    if (self.isCancelled) return [self willFinish];
    if (! parsedBody) {
        RKLogError(@"Failed to parse response data: %@", [error localizedDescription]);
        self.error = error;
        [self willFinish];
        return;
    }
    if (self.isCancelled) return [self willFinish];        
    
    // Invoke the will map deserialized response block
    if (self.willMapDeserializedResponseBlock) {
        parsedBody = self.willMapDeserializedResponseBlock(parsedBody);
        if (! parsedBody) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Mapping was declined due to a `willMapDeserializedResponseBlock` returning nil." };
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorMappingDeclined userInfo:userInfo];
            RKLogError(@"Failed to parse response data: %@", [error localizedDescription]);
            [self willFinish];
            return;
        }
    }

    // Object map the response
    self.mappingResult = [self performMappingWithObject:parsedBody error:&error];    
    
    // If the response is a client error return either the mapping error or the mapped result to the caller as the error
    if (isErrorStatusCode) {
        if ([self.mappingResult count] > 0) {
            error = RKErrorFromMappingResult(self.mappingResult);
        } else {
            // We encountered a client error that we could not map, throw unprocessable error
            if (! error) error = RKUnprocessableErrorFromResponse(self.response);
        }
        self.error = error;
        [self willFinish];
        return;
    }
    
    // Fail if no response descriptors matched
    if (error.code == RKMappingErrorNotFound && [self.responseMappingsDictionary count] == 0) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"No response descriptors match the response loaded.", nil),
                                    NSLocalizedFailureReasonErrorKey: RKFailureReasonErrorStringForResponseDescriptorsMismatchWithResponse(self.responseDescriptors, self.response),
                                    RKMappingErrorKeyPathErrorKey: [NSNull null],
                                    NSURLErrorFailingURLErrorKey: self.response.URL,
                                    NSURLErrorFailingURLStringErrorKey: [self.response.URL absoluteString],
                                    NSUnderlyingErrorKey: error};
        self.error = [[NSError alloc] initWithDomain:RKErrorDomain code:RKMappingErrorNotFound userInfo:userInfo];
        [self willFinish];
        return;
    }
    
    if (! self.mappingResult) self.error = error;    
    [self willFinish];
}

@end

@implementation RKObjectResponseMapperOperation

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    Class dataSourceClass = RKRegisteredResponseMapperOperationDataSourceClasses[[self class]] ?: [RKObjectMappingOperationDataSource class];
    id<RKMappingOperationDataSource> dataSource = [dataSourceClass new];
    self.mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:sourceObject mappingsDictionary:self.responseMappingsDictionary];
    self.mapperOperation.mappingOperationDataSource = dataSource;
    self.mapperOperation.delegate = self.mapperDelegate;
    self.mapperOperation.metadata = self.mappingMetadata;
    if (NSLocationInRange(self.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))) {
        self.mapperOperation.targetObject = self.targetObject;
    } else {
        RKLogInfo(@"Non-successful status code encountered: performing mapping with nil target object.");
    }
    [self.mapperOperation start];
    if (error) *error = self.mapperOperation.error;
    return self.mapperOperation.mappingResult;
}

@end

#ifdef RKCoreDataIncluded

static inline NSManagedObjectID *RKObjectIDFromObjectIfManaged(id object)
{
    return [object isKindOfClass:[NSManagedObject class]] ? [object objectID] : nil;
}

@interface RKManagedObjectResponseMapperOperation ()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation RKManagedObjectResponseMapperOperation

+ (void)registerMappingOperationDataSourceClass:(Class<RKMappingOperationDataSource>)dataSourceClass
{
    if (dataSourceClass && ![(Class)dataSourceClass isSubclassOfClass:[RKManagedObjectMappingOperationDataSource class]]) {
        [NSException raise:NSInvalidArgumentException format:@"Registered data source class '%@' does not inherit from the `RKManagedObjectMappingOperationDataSource` class: You must subclass `RKManagedObjectMappingOperationDataSource` in order to register a data source class for `RKManagedObjectResponseMapperOperation`.", NSStringFromClass(dataSourceClass)];
    }
    [super registerMappingOperationDataSourceClass:dataSourceClass];
}

- (void)cancel
{
    [super cancel];
    [self.operationQueue cancelAllOperations];
}

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    NSAssert(self.managedObjectContext, @"Unable to perform mapping: No `managedObjectContext` assigned. (Mapping response.URL = %@)", self.response.URL);

    __block NSError *blockError = nil;
    __block RKMappingResult *mappingResult = nil;
    self.operationQueue = [NSOperationQueue new];
    [self.managedObjectContext performBlockAndWait:^{
        // We may have been cancelled before we made it onto the MOC's queue
        if ([self isCancelled]) return;

        // Configure the mapper
        self.mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:sourceObject mappingsDictionary:self.responseMappingsDictionary];
        self.mapperOperation.delegate = self.mapperDelegate;
        self.mapperOperation.metadata = self.mappingMetadata;
        
        // Configure a data source to defer execution of connection operations until mapping is complete
        Class dataSourceClass = RKRegisteredResponseMapperOperationDataSourceClasses[[self class]] ?: [RKManagedObjectMappingOperationDataSource class];
        RKManagedObjectMappingOperationDataSource *dataSource = [[dataSourceClass alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                                                cache:self.managedObjectCache];
        dataSource.operationQueue = self.operationQueue;
        dataSource.parentOperation = self.mapperOperation;

        [self.operationQueue setMaxConcurrentOperationCount:1];
        [self.operationQueue setName:[NSString stringWithFormat:@"Relationship Connection Queue for '%@'", self.mapperOperation]];
        self.mapperOperation.mappingOperationDataSource = dataSource;
        
        if (NSLocationInRange(self.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))) {
            self.mapperOperation.targetObject = self.targetObject;

            if (self.targetObjectID || self.targetObject) {
                NSManagedObjectID *objectID = self.targetObjectID ?: RKObjectIDFromObjectIfManaged(self.targetObject);
                if (objectID) {
                    if ([objectID isTemporaryID]) RKLogWarning(@"Performing object mapping to temporary target objectID. Results may not be accessible without obtaining a permanent object ID.");
                    NSManagedObject *localObject = [self.managedObjectContext existingObjectWithID:objectID error:&blockError];
                    NSAssert(localObject == nil || localObject.managedObjectContext == nil || [localObject.managedObjectContext isEqual:self.managedObjectContext], @"Serious Core Data error: requested existing object with ID %@ in context %@, instead got an object reference in context %@. This may indicate that the objectID for your target managed object was obtained using `obtainPermanentIDsForObjects:error:` in the wrong context.", objectID, self.managedObjectContext, [localObject managedObjectContext]);
                    if (! localObject) {
                        RKLogWarning(@"Failed to retrieve existing object with ID: %@", objectID);
                        RKLogCoreDataError(blockError);
                        return;
                    }
                    self.mapperOperation.targetObject = localObject;
                } else {
                    if (self.mapperOperation.targetObject) RKLogDebug(@"Mapping HTTP response to unmanaged target object with `RKManagedObjectResponseMapperOperation`: %@", self.mapperOperation.targetObject);
                }
            } else {
                RKLogTrace(@"Mapping HTTP response to nil target object...");
            }
        } else {
            RKLogInfo(@"Non-successful status code encountered: performing mapping with nil target object.");
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

#endif
