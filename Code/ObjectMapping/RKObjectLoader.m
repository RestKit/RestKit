//
//  RKObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
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

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

@implementation RKObjectLoader

@synthesize objectManager = _objectManager, response = _response;
@synthesize targetObject = _targetObject, objectMapping = _objectMapping;
@synthesize result = _result;

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
    
	[_targetObject release];
	_targetObject = nil;
	[_response release];
	_response = nil;
	[_objectMapping release];
	_objectMapping = nil;
    [_result release];
    _result = nil;
    
	[super dealloc];
}

- (void)reset {
    [super reset];
    [_response release];
    _response = nil;
}

#pragma mark - Response Processing

- (void)finalizeLoad:(BOOL)successful {
	_isLoading = NO;

	if (successful) {
		_isLoaded = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:RKResponseReceivedNotification
															object:_response
														  userInfo:nil];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestFailedWithErrorNotification
															object:self
														  userInfo:nil];
	}
}

// Invoked on the main thread. Inform the delegate.
- (void)informDelegateOfObjectLoadWithResultDictionary:(NSDictionary*)resultDictionary {
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
    
	[self finalizeLoad:YES];
}

#pragma mark - Subclass Hooks

/**
 Overloaded by RKManagedObjectLoader to provide support for creation
 and find/update of managed object instances
 
 @protected
 */
- (id<RKObjectFactory>)createObjectFactory {
    return nil;
}

/**
 Overloaded by RKManagedObjectLoader to serialize/deserialize managed objects
 at thread boundaries. 
 
 @protected
 */
- (void)processMappingResult:(RKObjectMappingResult*)result {
    [self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithResultDictionary:) withObject:[result asDictionary] waitUntilDone:YES];
}

#pragma mark - Response Object Mapping

- (RKObjectMappingResult*)mapResponseWithMappingProvider:(RKObjectMappingProvider*)mappingProvider toObject:(id)targetObject error:(NSError**)error {
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:self.response.MIMEType];
    NSAssert1(parser, @"Cannot perform object load without a parser for MIME Type '%@'", self.response.MIMEType);
    id parsedData = [parser objectFromString:[self.response bodyAsString] error:error];
    if (parsedData == nil && error) {
        return nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(objectLoader:willMapData:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self willMapData:parsedData];
    }
    
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
    mapper.objectFactory = [self createObjectFactory];
    mapper.targetObject = targetObject;
    mapper.delegate = self;
    RKObjectMappingResult* result = [mapper performMapping];
    
    if (nil == result && RKRequestMethodDELETE == self.method && [mapper.errors count] == 1) {
        NSError* error = [mapper.errors objectAtIndex:0];
        if (error.domain == RKRestKitErrorDomain && error.code == RKObjectMapperErrorUnmappableContent) {
            // If this is a delete request, and the error is an "unmappable content" error, return an empty result
            // because delete requests should allow for no objects to come back in the response (you just deleted the object).
            result = [[[RKObjectMappingResult alloc] initWithDictionary:[NSDictionary dictionary]] autorelease];
        }
    }
    
    if (nil == result) {
        RKLogError(@"Encountered errors during mapping: %@", [[mapper.errors valueForKey:@"localizedDescription"] componentsJoinedByString:@", "]);
        
        // TODO: Construct a composite error that wraps up all the other errors
        *error = [mapper.errors lastObject];
        return nil;
    }
    
    return result;
}

- (RKObjectMappingResult*)performMapping:(NSError**)error {
    RKObjectMappingProvider* mappingProvider;
    if (self.objectMapping) {
        mappingProvider = [[RKObjectMappingProvider new] autorelease];
        [mappingProvider setMapping:self.objectMapping forKeyPath:@""];
    } else {
        mappingProvider = self.objectManager.mappingProvider;
    }
    
    return [self mapResponseWithMappingProvider:mappingProvider toObject:self.targetObject error:error];
}
    

- (void)performMappingOnBackgroundThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSError* error = nil;
    self.result = [self performMapping:&error];
    if (self.result) {
        [self processMappingResult:self.result];
    } else {
        [self performSelectorInBackground:@selector(didFailLoadWithError:) withObject:error];
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
	if ([self.response isFailure]) {
		[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:self.response.failureError];
        
		[self finalizeLoad:NO];
        
		return NO;
	} else if ([self.response isError]) {
        [self handleResponseError];
		return NO;
	} else if ([self.response isSuccessful] && NO == [self canParseMIMEType:[self.response MIMEType]]) {
        RKLogWarning(@"Encountered unexpected response code: %d (MIME Type: %@)", self.response.statusCode, self.response.MIMEType);
        if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
            [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
        } else {
            NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderUnexpectedResponseError userInfo:nil];
            [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
        }
        
        [self finalizeLoad:NO];
        
        return NO;
    }
    
	return YES;
}

- (void)handleResponseError {
    if ([self.response isServiceUnavailable]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RKServiceDidBecomeUnavailableNotification object:self];
    }
    
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
}

#pragma mark - RKRequest & RKRequestDelegate methods

// Invoked just before request hits the network
- (void)prepareURLRequest {
    // TODO: This is an informal protocol ATM. Maybe its not obvious enough?
    if (self.targetObject) {
        if ([self.targetObject respondsToSelector:@selector(willSendWithObjectLoader:)]) {
            [self.targetObject performSelector:@selector(willSendWithObjectLoader:) withObject:self];
        }
    }
    
    [super prepareURLRequest];
}

- (void)didFailLoadWithError:(NSError*)error {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
	if (_cachePolicy & RKRequestCachePolicyLoadOnError &&
		[[[RKClient sharedClient] cache] hasResponseForRequest:self]) {

		[self didFinishLoad:[[[RKClient sharedClient] cache] responseForRequest:self]];
	} else {
        if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
            [_delegate request:self didFailLoadWithError:error];
        }
        
        [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
        
        [self finalizeLoad:NO];
    }
    
    [pool release];
}

// NOTE: We do NOT call super here. We are overloading the default behavior from RKRequest
- (void)didFinishLoad:(RKResponse*)response {
	_response = [response retain];

	if ((_cachePolicy & RKRequestCachePolicyEtag) && [response isNotModified]) {
		[_response release];
		_response = nil;
		_response = [[[[RKClient sharedClient] cache] responseForRequest:self] retain];
	}

	if (![_response wasLoadedFromCache] && [_response isSuccessful] && (_cachePolicy != RKRequestCachePolicyNone)) {
		[[[RKClient sharedClient] cache] storeResponse:_response forRequest:self];
	}

    if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
        [_delegate request:self didLoadResponse:response];
    }
    
	if ([self isResponseMappable]) {
        // Determine if we are synchronous here or not.
        if (_sentSynchronously) {
            NSError* error = nil;
            self.result = [self performMapping:&error];
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
