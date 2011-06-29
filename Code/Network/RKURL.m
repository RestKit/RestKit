//
//  RKURL.m
//  RestKit
//
//  Created by Jeff Arena on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKURL.h"

@implementation RKURL

@synthesize baseURLString = _baseURLString;
@synthesize resourcePath = _resourcePath;

+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath {
	return [[[RKURL alloc] initWithBaseURLString:baseURLString resourcePath:resourcePath] autorelease];
}

- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath {
    NSString* completeURL = [NSString stringWithFormat:@"%@%@", baseURLString, resourcePath];    
    completeURL = [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)completeURL, NULL, (CFStringRef)@"+", kCFStringEncodingUTF8) autorelease];
    
    self = [self initWithString:completeURL];
    if (self) {
		_baseURLString = [baseURLString copy];
		_resourcePath = [resourcePath copy];
	}
	return self;
}

- (void)dealloc {
	[_baseURLString release];
	_baseURLString = nil;
	[_resourcePath release];
	_resourcePath = nil;
	[super dealloc];
}

@end
