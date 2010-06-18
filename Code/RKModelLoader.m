//
//  RKModelLoader.m
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKModelLoader.h"
#import "RKResponse.h"
#import "RKModelManager.h"
#import "Errors.h"

@implementation RKModelLoader

@synthesize mapper = _mapper, delegate = _delegate, callback = _callback;

+ (id)loaderWithMapper:(RKModelMapper*)mapper {
	return [[[self alloc] initWithMapper:mapper] autorelease];
}

- (id)initWithMapper:(RKModelMapper*)mapper {
	if (self = [self init]) {
		_mapper = [mapper retain];
	}
	
	return self;
}

- (void)dealloc {
	[_mapper release];
	[super dealloc];
}

- (SEL)callback {
	return @selector(loadModelsFromResponse:);
}

- (BOOL)encounteredErrorWhileProcessingRequest:(RKResponse*)response {
	RKRequest* request = response.request;
	if ([response isFailure]) {
		[_delegate modelLoaderRequest:response.request didFailWithError:response.failureError response:response model:(id<RKModelMappable>)request.userData];
		return YES;
	} else if ([response isError]) {
		NSString* errorMessage = nil;
		if ([response isJSON]) {
			errorMessage = [[[response bodyAsJSON] valueForKey:@"errors"] componentsJoinedByString:@", "];
		}
		if (nil == errorMessage) {
			errorMessage = [response bodyAsString];
		}
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  errorMessage, NSLocalizedDescriptionKey,
								  nil];		
		NSError *error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKModelLoaderRemoteSystemError userInfo:userInfo];
		
		[_delegate modelLoaderRequest:response.request didFailWithError:error response:response model:(id<RKModelMappable>)request.userData];
		return YES;
	}
	
	return NO;
}

- (void)informDelegateOfModelLoadWithInfoDictionary:(NSDictionary*)dictionary {
	RKResponse* response = [dictionary objectForKey:@"response"];
	NSArray* models = [dictionary objectForKey:@"models"];
	[dictionary release];
	RKRequest* request = response.request;
	[_delegate modelLoaderRequest:request didLoadModels:models response:response model:(id<RKModelMappable>)request.userData];
	// Release the response now that we have finished all our processing
	[response release];
}

- (void)processLoadModelsInBackground:(RKResponse *)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSManagedObjectContext* managedObjectContext = [[[RKModelManager manager] objectStore] managedObjectContext];
	
	[managedObjectContext lock];
	
	// If the request was sent through a model, we map the results back into that object
	// TODO: Note that this assumption may not work in all cases, other approaches?
	// The issue is that not specifying the object results in new objects being created
	// rather than mapping back into the original. This is a problem for create (POST) operations.
	id mapperResult = nil;
	id model = response.request.userData;	
	if (model) {
		[_mapper mapModel:model fromString:[response bodyAsString]];
		mapperResult = model;
	} else {
		mapperResult = [_mapper mapFromString:[response bodyAsString]];
	}
		
	NSArray* models = nil;
	if ([mapperResult isKindOfClass:[NSArray class]]) {
		models = mapperResult;
	} else if ([mapperResult conformsToProtocol:@protocol(RKModelMappable)]) {
		models = [NSArray arrayWithObject:mapperResult];
	}
	
	[managedObjectContext unlock];
			   
	NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:response, @"response", models, @"models", nil] retain];
	[self performSelectorOnMainThread:@selector(informDelegateOfModelLoadWithInfoDictionary:) withObject:infoDictionary waitUntilDone:NO];
	[pool release];
}

- (void)loadModelsFromResponse:(RKResponse*)response {
	if (NO == [self encounteredErrorWhileProcessingRequest:response] && [response isSuccessful]) {
		// Retain the response to prevent this thread from dealloc'ing before we have finished processing
		[response retain];
		[self performSelectorInBackground:@selector(processLoadModelsInBackground:) withObject:response];
	}	
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// RKRequestDelegate
//
// If our delegate responds to the messages, forward them back...

- (void)requestDidStartLoad:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
		[_delegate requestDidStartLoad:request];
	}
}

- (void)requestDidFinishLoad:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(requestDidFinishLoad:)]) {
		[(NSObject<RKRequestDelegate>*)_delegate requestDidFinishLoad:request];
	}
}

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[(NSObject<RKRequestDelegate>*)_delegate request:request didFailLoadWithError:error];
	}
}

- (void)requestDidCancelLoad:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(requestDidCancelLoad:)]) {
		[(NSObject<RKRequestDelegate>*)_delegate requestDidCancelLoad:request];
	}
}

@end
