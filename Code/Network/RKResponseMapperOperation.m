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
#import "RKLog.h"
#import "RKResponseDescriptor.h"
#import "RKPathMatcher.h"
#import "RKHTTPUtilities.h"
#import "RKResponseMapperOperation.h"
#import "RKMappingErrors.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

/**
 Returns a representation of a mapping result as an `NSError` value.

 The returned `NSError` object is in the `RKErrorDomain` domain and has the `RKMappingErrorFromMappingResult` code. The value for the `NSLocalizedDescriptionKey` is computed by retrieving the objects in the mapping result as an array, evaluating `valueForKeyPath:@"errorMessage"` against the array, and joining the returned error messages by comma to form a single string value. The source error objects are returned with the `NSError` in the `userInfo` dictionary under the `RKObjectMapperErrorObjectsKey` key.

 The `errorMessage` property is significant as it is an informal protocol that must be adopted by objects wishing to representing response errors.

 @return An error object representing the objects contained in the mapping result.
 @see `RKErrorMessage`
 */
static NSError *RKErrorFromMappingResult(RKMappingResult *mappingResult)
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
    if (! self.mappingResult) {
        self.error = error;
        return;
    }

    // If the response is a client error and we mapped the payload, return it to the caller as the error
    if (isClientError) self.error = RKErrorFromMappingResult(self.mappingResult);
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
