//
//  RKObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

// TODO: Factor this dependency out...
#import <UIKit/UIKit.h>

#import "RKObjectLoader.h"
#import "RKObjectManager.h"
#import "Errors.h"
#import "RKNotifications.h"

@implementation RKObjectLoader

@synthesize mapper = _mapper, response = _response, objectClass = _objectClass, keyPath = _keyPath;
@synthesize targetObject = _targetObject;

+ (id)loaderWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [self loaderWithResourcePath:resourcePath client:[RKClient sharedClient] mapper:mapper delegate:delegate];
}

+ (id)loaderWithResourcePath:(NSString*)resourcePath client:(RKClient*)client mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [[[self alloc] initWithResourcePath:resourcePath client:client mapper:mapper delegate:delegate] autorelease];
}

- (id)initWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [self initWithResourcePath:resourcePath client:[RKClient sharedClient] mapper:mapper delegate:delegate];
}

- (id)initWithResourcePath:(NSString*)resourcePath client:(RKClient*)client mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	if ((self = [self initWithURL:[client URLForResourcePath:resourcePath] delegate:delegate])) {
		_mapper = [mapper retain];		
		_client = [client retain];
		[_client setupRequest:self];
	}
	return self;
}

- (void)dealloc {
	[_mapper release];
	_mapper = nil;
	[_response release];
	_response = nil;
	[_keyPath release];
	_keyPath = nil;	
	[_client release];
	_client = nil;	
	[super dealloc];
}


#pragma mark Response Processing

- (void)responseProcessingSuccessful:(BOOL)successful withError:(NSError*)error {
	_isLoading = NO;

	NSDate* receivedAt = [NSDate date];
	if (successful) {
		_isLoaded = YES;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod",
								  [self URL], @"URL",
								  receivedAt, @"receivedAt",
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKResponseReceivedNotification
															object:_response
														  userInfo:userInfo];
	} else {
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod",
								  [self URL], @"URL",
								  receivedAt, @"receivedAt",
								  error, @"error",
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKRequestFailedWithErrorNotification
															object:self
														  userInfo:userInfo];
	}
}

- (BOOL)encounteredErrorWhileProcessingRequest:(RKResponse*)response {
	if ([response isFailure]) {
		[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:response.failureError];

		[self responseProcessingSuccessful:NO withError:response.failureError];

		return YES;
	} else if ([response isError]) {
		NSError* error = nil;

		if ([response isJSON]) {
			error = [_mapper parseErrorFromString:[response bodyAsString]];
			[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];

		} else if ([response isServiceUnavailable] && [_client serviceUnavailableAlertEnabled]) {
			// TODO: Break link with the client by using notifications
			if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
			}

			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[_client serviceUnavailableAlertTitle]
																message:[_client serviceUnavailableAlertMessage]
															   delegate:nil
													  cancelButtonTitle:NSLocalizedString(@"OK", nil)
													  otherButtonTitles:nil];
			[alertView show];
			[alertView release];

		} else {
			if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
			}
		}

		[self responseProcessingSuccessful:NO withError:error];

		return YES;
	}
	return NO;
}

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

- (void)processLoadModelsInBackground:(RKResponse *)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	/**
	 * If this loader is bound to a particular object, then we map
	 * the results back into the instance. This is used for loading and updating
	 * individual object instances via getObject & friends.
	 */
	NSArray* results = nil;
	if (self.targetObject) {
        [_mapper mapObject:self.targetObject fromString:[response bodyAsString]];
        results = [NSArray arrayWithObject:self.targetObject];
	} else {
		id result = [_mapper mapFromString:[response bodyAsString] toClass:self.objectClass keyPath:_keyPath];
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
		// TODO: When other mapping formats are supported, unwind this assumption... Should probably be an expected MIME types array set by client/manager
		if ([response isSuccessful] && [response isJSON]) {
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
