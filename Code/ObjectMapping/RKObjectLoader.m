//
//  RKObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters
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

#import "RKObjectLoader.h"
#import "RKObjectMapper.h"
#import "RKObjectManager.h"
#import "RKObjectMapperError.h"
#import "Errors.h"
#import "RKNotifications.h"
#import "RKParser.h"
#import "RKObjectLoader_Internals.h"
#import "RKParserRegistry.h"
#import "../Network/RKRequest_Internals.h"
#import "RKObjectSerializer.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

@interface RKRequest (Private)
- (void)updateInternalCacheDate;
@end

@implementation RKObjectLoader

@synthesize objectManager = _objectManager, response = _response;
@synthesize targetObject = _targetObject, objectMapping = _objectMapping;
@synthesize result = _result;
@synthesize serializationMapping = _serializationMapping;
@synthesize serializationMIMEType = _serializationMIMEType;
@synthesize sourceObject = _sourceObject;

+ (id)loaderWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(id<RKObjectLoaderDelegate>)delegate {
    return [[[self alloc] initWithResourcePath:resourcePath objectManager:objectManager delegate:delegate] autorelease];
}

- (id)initWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(id<RKObjectLoaderDelegate>)delegate {
	if ((self = [super initWithURL:[objectManager.client URLForResourcePath:resourcePath] delegate:delegate])) {		
        _objectManager = objectManager;
        [self.objectManager.client setupRequest:self];
	}

	return self;
}

- (void)dealloc {
    // Weak reference
    _objectManager = nil;
    
    [_sourceObject release];
    _sourceObject = nil;
	[_targetObject release];
	_targetObject = nil;
	[_response release];
	_response = nil;
	[_objectMapping release];
	_objectMapping = nil;
    [_result release];
    _result = nil;
    [_serializationMIMEType release];
    [_serializationMapping release];
    
	[super dealloc];
}

- (void)reset {
    [super reset];
    [_response release];
    _response = nil;
    [_result release];
    _result = nil;
}

#pragma mark - Response Processing

// NOTE: This method is significant because the notifications posted are used by
// RKRequestQueue to remove requests from the queue. All requests need to be finalized.
- (void)finalizeLoad:(BOOL)successful error:(NSError*)error {
	_isLoading = NO;
    
	if (successful) {
		_isLoaded = YES;
        if ([self.delegate respondsToSelector:@selector(objectLoaderDidFinishLoading:)]) {
            [(NSObject<RKObjectLoaderDelegate>*)self.delegate performSelectorOnMainThread:@selector(objectLoaderDidFinishLoading:)
                                                                               withObject:self waitUntilDone:YES];            
        }
        
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:_response 
                                                             forKey:RKRequestDidLoadResponseNotificationUserInfoResponseKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidLoadResponseNotification 
                                                            object:self 
                                                          userInfo:userInfo];
	} else {
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:(error ? error : (NSError*)[NSNull null])
                                                             forKey:RKRequestDidFailWithErrorNotificationUserInfoErrorKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidFailWithErrorNotification
															object:self
														  userInfo:userInfo];
	}
}

// Invoked on the main thread. Inform the delegate.
- (void)informDelegateOfObjectLoadWithResultDictionary:(NSDictionary*)resultDictionary {
    NSAssert([NSThread isMainThread], @"RKObjectLoaderDelegate callbacks must occur on the main thread");
    
	RKObjectMappingResult* result = [RKObjectMappingResult mappingResultWithDictionary:resultDictionary];

    if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObjectDictionary:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObjectDictionary:[result asDictionary]];
    }
    
    if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObjects:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObjects:[result asCollection]];
    }
    
    if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObject:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObject:[result asObject]];
    }
    
	[self finalizeLoad:YES error:nil];
}

#pragma mark - Subclass Hooks

/**
 Overloaded by RKManagedObjectLoader to serialize/deserialize managed objects
 at thread boundaries. 
 
 @protected
 */
- (void)processMappingResult:(RKObjectMappingResult*)result {
    NSAssert(![NSThread isMainThread], @"Mapping result processing should occur on a background thread");
    [self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithResultDictionary:) withObject:[result asDictionary] waitUntilDone:YES];
}

#pragma mark - Response Object Mapping

- (RKObjectMappingResult*)mapResponseWithMappingProvider:(RKObjectMappingProvider*)mappingProvider toObject:(id)targetObject error:(NSError**)error {
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:self.response.MIMEType];
    NSAssert1(parser, @"Cannot perform object load without a parser for MIME Type '%@'", self.response.MIMEType);
    
    // Check that there is actually content in the response body for mapping. It is possible to get back a 200 response
    // with the appropriate MIME Type with no content (such as for a successful PUT or DELETE). Make sure we don't generate an error
    // in these cases
    id bodyAsString = [self.response bodyAsString];
    if (bodyAsString == nil || [[bodyAsString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        RKLogDebug(@"Mapping attempted on empty response body...");
        if (self.targetObject) {
            return [RKObjectMappingResult mappingResultWithDictionary:[NSDictionary dictionaryWithObject:self.targetObject forKey:@""]];
        }
        
        return [RKObjectMappingResult mappingResultWithDictionary:[NSDictionary dictionary]];
    }
    
    id parsedData = [parser objectFromString:bodyAsString error:error];
    if (parsedData == nil && error) {
        return nil;
    }
    
    // Allow the delegate to manipulate the data
    if ([self.delegate respondsToSelector:@selector(objectLoader:willMapData:)]) {
        parsedData = [[parsedData mutableCopy] autorelease];
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self willMapData:&parsedData];
    }
    
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
    mapper.targetObject = targetObject;
    mapper.delegate = self;
    RKObjectMappingResult* result = [mapper performMapping];
    
    // Log any mapping errors
    if (mapper.errorCount > 0) {
        RKLogError(@"Encountered errors during mapping: %@", [[mapper.errors valueForKey:@"localizedDescription"] componentsJoinedByString:@", "]);
    }
    
    // The object mapper will return a nil result if mapping failed
    if (nil == result) {
        // TODO: Construct a composite error that wraps up all the other errors. Should probably make it performMapping:&error when we have this?
        if (error) *error = [mapper.errors lastObject];
        return nil;
    }
    
    return result;
}

- (RKObjectMappingResult*)performMapping:(NSError**)error {
    NSAssert(_sentSynchronously || ![NSThread isMainThread], @"Mapping should occur on a background thread");
    
    // TODO: Assert that we are on the background thread
    RKObjectMappingProvider* mappingProvider;
    if (self.objectMapping) {
        NSString* rootKeyPath = self.objectMapping.rootKeyPath ? self.objectMapping.rootKeyPath : @"";
        RKLogDebug(@"Found directly configured object mapping, creating temporary mapping provider %@", (rootKeyPath ? @"for keyPath '%@'" : nil));
        mappingProvider = [[RKObjectMappingProvider new] autorelease];        
        [mappingProvider setMapping:self.objectMapping forKeyPath:rootKeyPath];
    } else {
        RKLogDebug(@"No object mapping provider, using mapping provider from parent object manager to perform KVC mapping");
        mappingProvider = self.objectManager.mappingProvider;
    }
    
    return [self mapResponseWithMappingProvider:mappingProvider toObject:self.targetObject error:error];
}
    

- (void)performMappingOnBackgroundThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSError* error = nil;
    _result = [[self performMapping:&error] retain];
    NSAssert(_result || error, @"Expected performMapping to return a mapping result or an error.");
    if (self.result) {
        [self processMappingResult:self.result];
    } else if (error) {
        [self didFailLoadWithError:error];
    }

	[pool drain];
}

- (BOOL)canParseMIMEType:(NSString*)MIMEType {
    if ([[RKParserRegistry sharedRegistry] parserForMIMEType:self.response.MIMEType]) {
        return YES;
    }
    
    RKLogWarning(@"Unable to find parser for MIME Type '%@'", MIMEType);
    return NO;
}

- (BOOL)isResponseMappable {
    if ([self.response isServiceUnavailable]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RKServiceDidBecomeUnavailableNotification object:self];
    }
    
	if ([self.response isFailure]) {
		[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:self.response.failureError];
        
		[self finalizeLoad:NO error:self.response.failureError];
        
		return NO;
	} else if (NO == [self canParseMIMEType:[self.response MIMEType]]) {
        // We can't parse the response, it's unmappable regardless of the status code
        RKLogWarning(@"Encountered unexpected response with status code: %d (MIME Type: %@)", self.response.statusCode, self.response.MIMEType);
        NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderUnexpectedResponseError userInfo:nil];
        if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
            [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
        } else {            
            [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
        }
        
        // NOTE: We skip didFailLoadWithError: here so that we don't send the delegate
        // conflicting messages around unexpected response and failure with error
        [self finalizeLoad:NO error:error];
        
        return NO;
    } else if ([self.response isError]) {
        // This is an error and we can map the MIME Type of the response
        [self handleResponseError];
		return NO;
    }
    
	return YES;
}

- (void)handleResponseError {
    // Since we are mapping what we know to be an error response, we don't want to map the result back onto our
    // target object
    NSError* error = nil;
    RKObjectMappingResult* result = [self mapResponseWithMappingProvider:self.objectManager.mappingProvider toObject:nil error:&error];
    if (result) {
        error = [result asError];
    } else {
        RKLogError(@"Encountered an error while attempting to map server side errors from payload: %@", [error localizedDescription]);
    }
    
    [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
    [self finalizeLoad:NO error:error];    
}

#pragma mark - RKRequest & RKRequestDelegate methods

// Invoked just before request hits the network
- (BOOL)prepareURLRequest {
    if ((self.sourceObject && self.params == nil) && (self.method == RKRequestMethodPOST || self.method == RKRequestMethodPUT)) {
        NSAssert(self.serializationMapping, @"You must provide a serialization mapping for objects of type '%@'", NSStringFromClass([self.sourceObject class]));
        RKLogDebug(@"POST or PUT request for source object %@, serializing to MIME Type %@ for transport...", self.sourceObject, self.serializationMIMEType);
        RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:self.sourceObject mapping:self.serializationMapping];
        NSError* error = nil;
        id params = [serializer serializationForMIMEType:self.serializationMIMEType error:&error];	
        
        if (error) {
            RKLogError(@"Serializing failed for source object %@ to MIME Type %@: %@", self.sourceObject, self.serializationMIMEType, [error localizedDescription]);
            [self didFailLoadWithError:error];
            return NO;
        }
        
        self.params = params;
    }
    
    // TODO: This is an informal protocol ATM. Maybe its not obvious enough?
    if (self.sourceObject) {
        if ([self.sourceObject respondsToSelector:@selector(willSendWithObjectLoader:)]) {
            [self.sourceObject performSelector:@selector(willSendWithObjectLoader:) withObject:self];
        }
    }
    
    return [super prepareURLRequest];
}

- (void)didFailLoadWithError:(NSError*)error {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
	if (_cachePolicy & RKRequestCachePolicyLoadOnError &&
		[self.cache hasResponseForRequest:self]) {

		[self didFinishLoad:[self.cache responseForRequest:self]];
	} else {
        if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
            [_delegate request:self didFailLoadWithError:error];
        }
        
        [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
        
        [self finalizeLoad:NO error:error];
    }
    
    [pool release];
}

// NOTE: We do NOT call super here. We are overloading the default behavior from RKRequest
- (void)didFinishLoad:(RKResponse*)response {
    NSAssert([NSThread isMainThread], @"RKObjectLoaderDelegate callbacks must occur on the main thread");
	_response = [response retain];

	if ((_cachePolicy & RKRequestCachePolicyEtag) && [response isNotModified]) {
		[_response release];
		_response = nil;
		_response = [[self.cache responseForRequest:self] retain];
        [self updateInternalCacheDate];
	}

	if (![_response wasLoadedFromCache] && [_response isSuccessful] && (_cachePolicy != RKRequestCachePolicyNone)) {
		[self.cache storeResponse:_response forRequest:self];
	}

    if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
        [_delegate request:self didLoadResponse:_response];
    }
    
	if ([self isResponseMappable]) {
        // Determine if we are synchronous here or not.
        if (_sentSynchronously) {
            NSError* error = nil;
            _result = [[self performMapping:&error] retain];
            if (self.result) {
                [self processMappingResult:self.result];
            } else {
                [self performSelectorInBackground:@selector(didFailLoadWithError:) withObject:error];
            }
        } else {
            [self performSelectorInBackground:@selector(performMappingOnBackgroundThread) withObject:nil];
        }
	}
}

@end
