//
//  OTRestModelLoader.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Objective 3. All rights reserved.
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

- (void)loadModelFromResponse:(OTRestResponse*)response {
	id model = [_mapper buildModelFromString:[response payloadString]];
//	id model = [_mapper buildModelFromXML:[[response payloadXMLDocument] firstChild]];
	[_delegate performSelector:self.callback withObject:model];
}

- (void)loadModelsFromResponse:(OTRestResponse*)response {
	NSArray* models = [_mapper buildModelsFromString:[response payloadString]];
	
//	NSMutableArray* models = [[[NSMutableArray alloc] init] autorelease];
//	NSArray* elements = [[[response payloadXMLDocument] firstChild] childElements];
//	for (Element* element in elements) {
//		id model = [_mapper buildModelFromXML:element];
//		[models addObject:model];
//	}	
	[_delegate performSelector:self.callback withObject:models];
}

@end
