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
#import "Errors.h"
#import "RKNotifications.h"
#import "RKParser.h"
#import "RKObjectLoader_Internals.h"

// TODO: Move to RKRequest_Internals.h
@interface RKRequest (Private);

- (void)prepareURLRequest;

@end

@implementation RKObjectLoader

@synthesize objectManager = _objectManager, response = _response;
@synthesize targetObject = _targetObject, objectMapping = _objectMapping;

+ (id)loaderWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
    return [[[self alloc] initWithResourcePath:resourcePath objectManager:objectManager delegate:delegate] autorelease];
}

- (id)initWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	if ((self = [super initWithURL:[objectManager.client URLForResourcePath:resourcePath] delegate:delegate])) {		
        _objectManager = objectManager;        
        [self.objectManager.client setupRequest:self];
	}
    
	return self;
}

- (void)dealloc {
    // Weak reference
    _objectManager = nil;
    
	[_response release];
	_response = nil;
	[_objectMapping release];
	_objectMapping = nil;
    
	[super dealloc];
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

/*!
 Overloaded by RKManagedObjectLoader to provide support for creation
 and find/update of managed object instances
 
 @protected
 */
- (id<RKObjectFactory>)createObjectFactory {
    return nil;
}

/*!
 Overloaded by RKManagedObjectLoader to serialize/deserialize managed objects
 at thread boundaries. 
 
 @protected
 */
- (void)processMappingResult:(RKObjectMappingResult*)result {
    [self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithResultDictionary:) withObject:[result asDictionary] waitUntilDone:YES];
}

#pragma mark - Response Object Mapping

- (RKObjectMappingResult*)mapResponseWithMappingProvider:(RKObjectMappingProvider*)mappingProvider {
    id<RKParser> parser = [self.objectManager parserForMIMEType:self.response.MIMEType];
    id parsedData = [parser objectFromString:[self.response bodyAsString]];
    NSAssert1(parser, @"Cannot perform object load without a parser for MIME Type '%@'", self.response.MIMEType);
    NSAssert(parsedData, @"Cannot perform object load without data for mapping");
    
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
    mapper.objectFactory = [self createObjectFactory];
    mapper.targetObject = self.targetObject;
    mapper.delegate = self;
    RKObjectMappingResult* result = [mapper performMapping];
    
    // TODO: Have to handle errors here... Maybe we always return a result with the errors?
    if (nil == result) {
        // TODO: Logging macros
        NSLog(@"GOT MAPPING ERRORS: %@", mapper.errors);
        return nil;
    }
    
    return result;
}

- (void)performMappingOnBackgroundThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    RKObjectMappingProvider* mappingProvider;
    if (self.objectMapping) {
        mappingProvider = [[RKObjectMappingProvider new] autorelease];
        [mappingProvider setMapping:self.objectMapping forKeyPath:@""];
    } else {
        mappingProvider = self.objectManager.mappingProvider;
    }
    
    RKObjectMappingResult* result = [self mapResponseWithMappingProvider:mappingProvider];
    [self processMappingResult:result];

	[pool drain];
}

- (BOOL)canParseMIMEType:(NSString*)MIMEType {
    // TODO: Implement this
    // TODO: Check that we have a parser available for the MIME Type
    // TODO: Should probably be an expected MIME types array set by client/manager
    // if ([self.objectMapper hasParserForMIMEType:[response MIMEType]) canMapFromMIMEType:
    return YES;
}

- (BOOL)isResponseMappable {
	if ([self.response isFailure]) {
		[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:self.response.failureError];
        
		[self finalizeLoad:NO];
        
		return NO;
	} else if ([self.response isError]) {
        
        if ([self.response isServiceUnavailable]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RKServiceDidBecomeUnavailableNotification object:self];
        }
        
        RKObjectMappingResult* result = [self mapResponseWithMappingProvider:self.objectManager.mappingProvider];
        NSError* error = [result asError];
        
        // TODO: Is this returning: [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderRemoteSystemError userInfo:userInfo];
        [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
        
		return NO;
	} else if ([self.response isSuccessful] && NO == [self canParseMIMEType:[self.response MIMEType]]) {
        NSLog(@"Encountered unexpected response code: %d (MIME Type: %@)", self.response.statusCode, self.response.MIMEType);
        if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
            [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
        }
        
        [self finalizeLoad:NO];
        
        return NO;
    }
    
	return YES;
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
	if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[_delegate request:self didFailLoadWithError:error];
	}
    
	[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
    
	[self finalizeLoad:NO];
}

// NOTE: We do NOT call super here. We are overloading the default behavior from RKRequest
- (void)didFinishLoad:(RKResponse*)response {
	_response = [response retain];
    
    if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
        [_delegate request:self didLoadResponse:response];
    }
    
	if ([self isResponseMappable]) {
		[self performSelectorInBackground:@selector(performMappingOnBackgroundThread) withObject:nil];
	}
}

@end
