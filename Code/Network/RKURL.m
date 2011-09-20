//
//  RKURL.m
//  RestKit
//
//  Created by Jeff Arena on 10/18/10.
//  Copyright 2010 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKURL.h"
#import "RKClient.h"

@implementation RKURL

@synthesize baseURLString = _baseURLString;
@synthesize resourcePath = _resourcePath;
@synthesize queryParams = _queryParams;

+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath {
	return [[[self alloc] initWithBaseURLString:baseURLString resourcePath:resourcePath] autorelease];
}

+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams {
	return [[[self alloc] initWithBaseURLString:baseURLString resourcePath:resourcePath queryParams:queryParams] autorelease];
}

- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath {
	return [self initWithBaseURLString:baseURLString resourcePath:resourcePath queryParams:nil];
}

- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams {
	NSString* resourcePathWithQueryString = RKPathAppendQueryParams(resourcePath, queryParams);
	NSURL *baseURL = [NSURL URLWithString:baseURLString];
	NSString* completePath = [[baseURL path] stringByAppendingPathComponent:resourcePathWithQueryString];
    // Preserve trailing slash in resourcePath
    if (resourcePath && [resourcePath characterAtIndex:[resourcePath length] - 1] == '/') {
        completePath = [completePath stringByAppendingString:@"/"];
    }
	NSURL* completeURL = [NSURL URLWithString:completePath relativeToURL:baseURL];
	if (!completeURL) {
		[self release];
		return nil;
	}
	
	// You can't safely use initWithString:relativeToURL: in a NSURL subclass, see http://www.openradar.me/9729706
	self = [self initWithString:[completeURL absoluteString]];
	if (self) {
		_baseURLString = [baseURLString copy];
		_resourcePath = [resourcePath copy];
		_queryParams = [queryParams retain];
	}
	return self;
}

- (void)dealloc {
	[_baseURLString release];
	_baseURLString = nil;
	[_resourcePath release];
	_resourcePath = nil;
	[_queryParams release];
	_queryParams = nil;
	[super dealloc];
}

@end
