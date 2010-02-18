//
//  RKModelLoader.m
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKModelLoader.h"
#import "RKResponse.h"

@implementation RKModelLoader

@synthesize mapper = _mapper, delegate = _delegate, callback = _callback;

- (id)initWithMapper:(RKModelMapper*)mapper {
	if (self = [self init]) {
		_mapper = [mapper retain];
	}
	
	return self;
}

- (SEL)memberCallback {
	return @selector(loadModelFromResponse:);
}

- (SEL)collectionCallback {
	return @selector(loadModelsFromResponse:);
}

- (BOOL)encounteredErrorWhileProcessingRequest:(RKResponse*)response {
	NSString* errorMessage = nil;
	RKRequest* request = response.request;
	if ([response isFailure]) {
		[_delegate modelLoaderRequest:response.request didFailWithError:response.failureError response:response model:(id<RKModelMappable>)request.userData];
		return YES;
	} else if ([response isClientError]) {
		// TODO: These assumptions are around how Rails serializes error into a payload. Factor out into an adapter...
		if ([response isXML]) {
			errorMessage = [[(Element*)[response payloadXMLDocument] selectElement:@"error"] contentsText];
		} else if ([response isJSON]) {
			errorMessage = [[response payloadJSONDictionary] objectForKey:@"error"];
		}
		if (nil == errorMessage) {
			errorMessage = [response payloadString];
		}
		[_delegate modelLoaderRequest:response.request didReturnErrorMessage:errorMessage response:response model:(id<RKModelMappable>)request.userData];
		return YES;
	} else if ([response isServerError]) {
		errorMessage = [response payloadString];
		[_delegate modelLoaderRequest:response.request didReturnErrorMessage:errorMessage response:response model:(id<RKModelMappable>)request.userData];
		return YES;
	}
	
	return NO;
}

- (void)processLoadModelInBackground:(RKResponse*)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	id model = [_mapper buildModelFromString:[response payloadString]];
	[_delegate performSelectorOnMainThread:self.callback withObject:model waitUntilDone:NO];
	[pool release];
}

- (void)loadModelFromResponse:(RKResponse*)response {
	if (NO == [self encounteredErrorWhileProcessingRequest:response] && [response isSuccessful]) {		
		[self performSelectorInBackground:@selector(processLoadModelInBackground:) withObject:response];
	}	
}

- (void)processLoadModelsInBackground:(RKResponse *)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSArray* models = [_mapper buildModelsFromString:[response payloadString]];
	[_delegate performSelectorOnMainThread:self.callback withObject:models waitUntilDone:NO];
	[pool release];
}

- (void)loadModelsFromResponse:(RKResponse*)response {
	if (NO == [self encounteredErrorWhileProcessingRequest:response] && [response isSuccessful]) {		
		[self performSelectorInBackground:@selector(processLoadModelsInBackground:) withObject:response];
	}	
}

@end
