//
//  RKObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKObjectLoader.h"
#import "RKObjectManager.h"
#import "Errors.h"
#import "RKNotifications.h"

// Private Interfaces - Proxy access to RKObjectManager for convenience
@interface RKObjectLoader (Private)

@property (nonatomic, readonly) RKClient* client;
@property (nonatomic, readonly) RKObjectMapper* objectMapper;

- (void)prepareURLRequest;

@end

@implementation RKObjectLoader

@synthesize objectManager = _objectManager, response = _response, objectClass = _objectClass, keyPath = _keyPath;
@synthesize targetObject = _targetObject;

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
	[_keyPath release];
	_keyPath = nil;
    
	[super dealloc];
}

#pragma mark - RKObjectManager Proxy Methods

- (RKClient*)client {
    return self.objectManager.client;
}

- (RKObjectMapper*)objectMapper {
    return self.objectManager.mapper;
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
		NSError* error = nil;
        
        // TODO: Unwind hard coding of JSON specific assumptions
		if ([response isJSON]) {
			error = [self.objectMapper parseErrorFromString:[response bodyAsString]];
			[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];
		} else {
            if ([response isServiceUnavailable]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RKServiceDidBecomeUnavailableNotification object:self];
            }
            
			if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
			}
		}

		[self responseProcessingSuccessful:NO withError:error];

		return YES;
	}
	return NO;
}

// NOTE: This method is overloaded in RKManagedObjectLoader to provide Core Data support
- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary {
	NSArray* objects = [dictionary objectForKey:@"objects"];
	[dictionary release];

	[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didLoadObjects:objects];
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

// NOTE: This method is overloaded in RKManagedObjectLoader to provide Core Data support
- (void)processLoadModelsInBackground:(RKResponse *)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	/**
	 * If this loader is bound to a particular object, then we map
	 * the results back into the instance. This is used for loading and updating
	 * individual object instances via getObject and friends.
	 */
	NSArray* results = nil;
	if (self.targetObject) {
		[self.objectMapper mapObject:self.targetObject fromString:[response bodyAsString] keyPath:self.keyPath];
        results = [NSArray arrayWithObject:self.targetObject];
	} else {
		id result = [self.objectMapper mapFromString:[response bodyAsString] toClass:self.objectClass keyPath:self.keyPath];
		if ([result isKindOfClass:[NSArray class]]) {
			results = (NSArray*)result;
		} else {
			// Using arrayWithObjects: instead of arrayWithObject:
			// so that in the event result is nil, then we get empty array instead of exception for trying to insert nil.
			results = [NSArray arrayWithObjects:result, nil];
		}
	}

    NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:response, @"response", results, @"objects", nil] retain];
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
        BOOL isAcceptable = (self.objectMapper.format == RKMappingFormatXML && [response isXML]) ||
                            (self.objectMapper.format == RKMappingFormatJSON && [response isJSON]);
		if ([response isSuccessful] && isAcceptable) {
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
