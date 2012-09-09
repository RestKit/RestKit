//
//  RKResponseMapperOperation.m
//  GateGuru
//
//  Created by Blake Watters on 8/16/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import "RKObjectMappingOperationDataSource.h"
#import "RKLog.h"
#import "RKResponseDescriptor.h"
#import "RKPathMatcher.h"
#import "RKHTTPUtilities.h"
#import "RKResponseMapperOperation.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

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
    NSError *underlyingError;
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

- (BOOL)responseMatchesMappingDescriptor:(RKResponseDescriptor *)mappingDescriptor
{
    if (mappingDescriptor.pathPattern) {
        RKPathMatcher *pathMatcher = [RKPathMatcher matcherWithPattern:mappingDescriptor.pathPattern];
        if (! [pathMatcher matchesPath:[self.response.URL relativePath] tokenizeQueryStrings:NO parsedArguments:nil]) {
            return NO;
        }
    }

    if (mappingDescriptor.statusCodes) {
        if (! [mappingDescriptor.statusCodes containsIndex:self.response.statusCode]) {
            return NO;
        }
    }

    return YES;
}

- (NSDictionary *)buildResponseMappingsDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (RKResponseDescriptor *mappingDescriptor in self.responseDescriptors) {
        if ([self responseMatchesMappingDescriptor:mappingDescriptor]) {
            id key = mappingDescriptor.keyPath ? mappingDescriptor.keyPath : [NSNull null];
            [dictionary setObject:mappingDescriptor.mapping forKey:key];
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
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:[NSString stringWithFormat:@"Loaded an unprocessable client error response (%ld)", (long) self.response.statusCode] forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:[self.response URL] forKey:NSURLErrorFailingURLErrorKey];

        self.error = [[NSError alloc] initWithDomain:RKErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
        return;
    }

    // If we are successful and empty, we may optionally consider the response mappable (i.e. 204 response or 201 with no body)
    if ([self hasEmptyResponse] && self.treatsEmptyResponseAsSuccess) {
        if (self.targetObject) {
            self.mappingResult = [RKMappingResult mappingResultWithDictionary:[NSDictionary dictionaryWithObject:self.targetObject forKey:@""]];
        } else {
            self.mappingResult = [RKMappingResult mappingResultWithDictionary:[NSDictionary dictionary]];
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
    if (! self.mappingResult) {
        self.error = error;
        return;
    }

    // If the response is a client error and we mapped the payload, return it to the caller as the error
    if (isClientError) self.error = [self.mappingResult asError];
}

@end

@implementation RKObjectResponseMapperOperation

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    RKObjectMapper *mapper = [[RKObjectMapper alloc] initWithObject:sourceObject mappingsDictionary:self.responseMappingsDictionary];
    mapper.mappingOperationDataSource = dataSource;
    return [mapper performMapping:error];
}

@end

@implementation RKManagedObjectResponseMapperOperation

- (RKMappingResult *)performMappingWithObject:(id)sourceObject error:(NSError **)error
{
    NSParameterAssert(self.managedObjectContext);
    NSParameterAssert(self.mappingOperationDataSource);

    __block NSError *blockError = nil;
    __block RKMappingResult *mappingResult;
    [self.managedObjectContext performBlockAndWait:^{
        // Configure the mapper
        RKObjectMapper *mapper = [[RKObjectMapper alloc] initWithObject:sourceObject mappingsDictionary:self.responseMappingsDictionary];
        mapper.delegate = self.mapperDelegate;
        mapper.mappingOperationDataSource = self.mappingOperationDataSource;

        // TODO: if ([self.response isSuccessful] -- Encapsulate HTTP response helpers in category on NSHTTPURLResponse
        if (NSLocationInRange(self.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))) {
            mapper.targetObject = self.targetObject;

            if (self.targetObjectID) {
                if ([self.targetObjectID isTemporaryID]) RKLogWarning(@"Performing object mapping to temporary target objectID. Results may not be accessible without obtaining a permanent object ID.");
                NSManagedObject *localObject = [self.managedObjectContext existingObjectWithID:self.targetObjectID error:&blockError];
                if (! localObject) {
                    RKLogWarning(@"Failed to retrieve existing object with ID: %@", self.targetObjectID);
                    RKLogCoreDataError(blockError);
                }
                mapper.targetObject = localObject;
            }
        } else {
            RKLogInfo(@"Non-successful state code encountered: performing mapping with nil target object.");
        }

        mappingResult = [mapper performMapping:&blockError];
    }];

    if (! mappingResult) {
        if (error) *error = blockError;
        return nil;
    }

    return mappingResult;
}

@end
