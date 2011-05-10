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

// Private Interfaces - Proxy access to RKObjectManager for convenience
@interface RKObjectLoader (Private)

@property (nonatomic, readonly) RKClient* client;

- (RKObjectMappingResult*)mapResponse:(RKResponse*)response withMappingProvider:(RKObjectMappingProvider*)mappingProvider;

@end

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
        
        [self.client setupRequest:self];
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

#pragma mark - RKObjectManager Proxy Methods

- (RKClient*)client {
    return self.objectManager.client;
}

#pragma mark Response Processing

- (void)responseProcessingSuccessful:(BOOL)successful withError:(NSError*)error {
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

- (BOOL)encounteredErrorWhileProcessingRequest:(RKResponse*)response {
	if ([response isFailure]) {
		[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:response.failureError];

		[self responseProcessingSuccessful:NO withError:response.failureError];

		return YES;
	} else if ([response isError]) {
        
        if ([response isServiceUnavailable]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RKServiceDidBecomeUnavailableNotification object:self];
        }
        
        RKObjectMappingResult* result = [self mapResponse:response withMappingProvider:self.objectManager.mappingProvider];
        NSError* error = [result asError];
        
        [(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
        
		return YES;
	}
	return NO;
}

// NOTE: This method is overloaded in RKManagedObjectLoader to provide Core Data support
- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary {
	RKObjectMappingResult* result = [dictionary objectForKey:@"result"];
	[dictionary release];

    if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObjects:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObjects:[result asCollection]];
    } else if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObject:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObject:[result asObject]];
    } else if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObjectDictionary:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObjectDictionary:[result asDictionary]];
    }
    
	[self responseProcessingSuccessful:YES withError:nil];
}

- (void)informDelegateOfObjectLoadErrorWithInfoDictionary:(NSDictionary*)dictionary {
	NSError* error = [dictionary objectForKey:@"error"];
	[dictionary release];

	NSLog(@"[RestKit] RKObjectLoader: Error saving managed object context: error=%@ userInfo=%@", error, error.userInfo);

	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [error localizedDescription], NSLocalizedDescriptionKey,
							  nil];
	NSError *rkError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderRemoteSystemError userInfo:userInfo];

	[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:rkError];

	[self responseProcessingSuccessful:NO withError:rkError];
}

- (RKObjectMappingResult*)mapResponse:(RKResponse*)response withMappingProvider:(RKObjectMappingProvider*)mappingProvider {
    id<RKParser> parser = [self.objectManager parserForMIMEType:response.MIMEType];
    // TODO: Handle case where there is no parser for this MIME type
    id parsedData = [parser objectFromString:[response bodyAsString]];
    
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
    mapper.objectManager = self.objectManager;
    mapper.targetObject = self.targetObject;
    mapper.delegate = self;
    RKObjectMappingResult* result = [mapper performMapping];
    return result;
}

// NOTE: This method is overloaded in RKManagedObjectLoader to provide Core Data support
- (void)processLoadModelsInBackground:(RKResponse *)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    RKObjectMappingProvider* mappingProvider;
    if (self.objectMapping) {
        mappingProvider = [[RKObjectMappingProvider new] autorelease];
        [mappingProvider setMapping:self.objectMapping forKeyPath:@""];
    } else {
        mappingProvider = self.objectManager.mappingProvider;
    }
    
    RKObjectMappingResult* result = [self mapResponse:response withMappingProvider:mappingProvider];

    NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:response, @"response", result, @"result", nil] retain];
    [self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithInfoDictionary:) withObject:infoDictionary waitUntilDone:YES];

	[pool drain];
}

// Give the target object a chance to modify the request
- (void)handleTargetObject {
	if (self.targetObject) {
		if ([self.targetObject respondsToSelector:@selector(willSendWithObjectLoader:)]) {
			[self.targetObject willSendWithObjectLoader:self];
		}
	}
}

// Invoked just before request hits the network
- (void)prepareURLRequest {
    [self handleTargetObject];
    [super prepareURLRequest];
}

- (void)didFailLoadWithError:(NSError*)error {
	if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[_delegate request:self didFailLoadWithError:error];
	}

	[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];

	[self responseProcessingSuccessful:NO withError:error];
}

- (void)didFinishLoad:(RKResponse*)response {
	_response = [response retain];
    
    if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
        [_delegate request:self didLoadResponse:response];
    }
    
	if (NO == [self encounteredErrorWhileProcessingRequest:response]) {
        // TODO: Should probably be an expected MIME types array set by client/manager
        // if ([self.objectMapper hasParserForMIMEType:[response MIMEType]) canMapFromMIMEType:
        
		if ([response isSuccessful]) {
			[self performSelectorInBackground:@selector(processLoadModelsInBackground:) withObject:response];
		} else {
			NSLog(@"Encountered unexpected response code: %d (MIME Type: %@)", response.statusCode, response.MIMEType);
			if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
			}
            
			[self responseProcessingSuccessful:NO withError:nil];
		}
	}
}

@end
