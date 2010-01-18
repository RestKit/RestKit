//
//  OTRestModelLoader.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "OTRestModelLoader.h"
#import "OTRestResponse.h"

@implementation OTRestModelLoader

@synthesize mapper = _mapper, delegate = _delegate, callback = _callback;

- (id)initWithMapper:(OTRestModelMapper*)mapper {
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

- (BOOL)processResponse:(OTRestResponse*)response {
	NSString* errorMessage;
	OTRestRequest* request = response.request;
	if ([response isFailure]) {
		[_delegate modelLoaderRequest:response.request didFailWithError:response.failureError response:response model:(id<OTRestModelMappable>)request.userData];
		return YES;
	} else if ([response isClientError]) {
		if ([response isXML]) {
			errorMessage = [[(Element*)[response payloadXMLDocument] selectElement:@"error"] contentsText];
		} else if ([response isJSON]) {
			// TODO - Need to test!!!
			errorMessage = [[response payloadJSONDictionary] objectForKey:@"error"];
		}
		if (nil == errorMessage) {
			errorMessage = [response payloadString];
		}
		[_delegate modelLoaderRequest:response.request didReturnErrorMessage:errorMessage response:response model:(id<OTRestModelMappable>)request.userData];
		return YES;
	} else if ([response isServerError]) {
		errorMessage = [response payloadString];
		[_delegate modelLoaderRequest:response.request didReturnErrorMessage:errorMessage response:response model:(id<OTRestModelMappable>)request.userData];
		return YES;
	}
	
	return NO;
}

- (void)loadModelFromResponse:(OTRestResponse*)response {
	if (NO == [self processResponse:response] && [response isSuccessful]) {
		id model = [_mapper buildModelFromString:[response payloadString]];	
		[_delegate performSelector:self.callback withObject:model];
	}
	// TODO - What do we do???
}

- (void)loadModelsFromResponse:(OTRestResponse*)response {
	if (NO == [self processResponse:response] && [response isSuccessful]) {
		NSArray* models = [_mapper buildModelsFromString:[response payloadString]];
		[_delegate performSelector:self.callback withObject:models];
	}
}

@end
