//
//  OTRestModelLoader.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestModelLoader.h"

@implementation OTRestModelLoader

@synthesize mapper = _mapper, delegate = _delegate, callback = _callback;

- (id)initWithMapper:(OTRestModelMapper*)mapper {
	if (self = [self init]) {
		_mapper = [mapper retain];
	}
	
	return self;
}

- (SEL)mapperCallback {
	return @selector(loadModelFromXML:);
}

- (void)loadModelFromXML:(Element*)XML {
	id model = [_mapper buildModelFromXML:XML];
	[_delegate performSelector:self.callback withObject:model];
}

@end
