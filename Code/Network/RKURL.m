//
//  RKURL.m
//  RestKit
//
//  Created by Jeff Arena on 10/18/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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
#import "NSURL+RKAdditions.h"
#import "NSString+RKAdditions.h"
#import "NSDictionary+RKAdditions.h"
#import "RKLog.h"

@interface RKURL ()
@property (nonatomic, copy, readwrite) NSURL *baseURL;
@property (nonatomic, copy, readwrite) NSString *resourcePath;
@end

@implementation RKURL

@synthesize baseURL;
@synthesize resourcePath;

+ (id)URLWithBaseURL:(NSURL *)baseURL
{
    return [self URLWithBaseURL:baseURL resourcePath:nil queryParameters:nil];
}

+ (id)URLWithBaseURL:(NSURL *)baseURL resourcePath:(NSString *)resourcePath
{
    return [self URLWithBaseURL:baseURL resourcePath:resourcePath queryParameters:nil];
}

+ (id)URLWithBaseURL:(NSURL *)baseURL resourcePath:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters
{
    return [[[self alloc] initWithBaseURL:baseURL resourcePath:resourcePath queryParameters:queryParameters] autorelease];
}

+ (id)URLWithBaseURLString:(NSString *)baseURLString
{
    return [self URLWithBaseURLString:baseURLString resourcePath:nil queryParameters:nil];
}

+ (id)URLWithBaseURLString:(NSString *)baseURLString resourcePath:(NSString *)resourcePath
{
    return [self URLWithBaseURLString:baseURLString resourcePath:resourcePath queryParameters:nil];
}

+ (id)URLWithBaseURLString:(NSString *)baseURLString resourcePath:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters
{
    return [self URLWithBaseURL:[NSURL URLWithString:baseURLString] resourcePath:resourcePath queryParameters:queryParameters];
}

// Designated initializer. Note this diverges from NSURL due to a bug in Cocoa. We can't
// call initWithString:relativeToURL: from a subclass.
- (id)initWithBaseURL:(NSURL *)theBaseURL resourcePath:(NSString *)theResourcePath queryParameters:(NSDictionary *)theQueryParameters
{
    // Merge any existing query parameters with the incoming dictionary
    NSDictionary *resourcePathQueryParameters = [theResourcePath queryParameters];
    NSMutableDictionary *mergedQueryParameters = [NSMutableDictionary dictionaryWithDictionary:[theBaseURL queryParameters]];
    [mergedQueryParameters addEntriesFromDictionary:resourcePathQueryParameters];
    [mergedQueryParameters addEntriesFromDictionary:theQueryParameters];

    // Build the new URL path
    NSRange queryCharacterRange = [theResourcePath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
    NSString *resourcePathWithoutQueryString = (queryCharacterRange.location == NSNotFound) ? theResourcePath : [theResourcePath substringToIndex:queryCharacterRange.location];
    NSString *baseURLPath = [[theBaseURL path] isEqualToString:@"/"] ? @"" : [[theBaseURL path] stringByStandardizingPath];
    NSString *completePath = resourcePathWithoutQueryString ? [baseURLPath stringByAppendingString:resourcePathWithoutQueryString] : baseURLPath;
    NSString *completePathWithQuery = [completePath stringByAppendingQueryParameters:mergedQueryParameters];

    // NOTE: You can't safely use initWithString:relativeToURL: in a NSURL subclass, see http://www.openradar.me/9729706
    // So we unfortunately convert into an NSURL before going back into an NSString -> RKURL
    NSURL *completeURL = [NSURL URLWithString:completePathWithQuery relativeToURL:theBaseURL];
    if (!completeURL) {
        RKLogError(@"Failed to build RKURL by appending resourcePath and query parameters '%@' to baseURL '%@'", theResourcePath, theBaseURL);
        [self release];
        return nil;
    }

    self = [self initWithString:[completeURL absoluteString]];
    if (self) {
        self.baseURL = theBaseURL;
        self.resourcePath = theResourcePath;
    }

    return self;
}

- (void)dealloc
{
    [baseURL release];
    baseURL = nil;
    [resourcePath release];
    resourcePath = nil;

    [super dealloc];
}

- (NSDictionary *)queryParameters
{
    if (self.query) {
        return [NSDictionary dictionaryWithURLEncodedString:self.query];
    }
    return nil;
}

- (RKURL *)URLByAppendingResourcePath:(NSString *)theResourcePath
{
    return [RKURL URLWithBaseURL:self resourcePath:theResourcePath];
}

- (RKURL *)URLByAppendingResourcePath:(NSString *)theResourcePath queryParameters:(NSDictionary *)theQueryParameters
{
    return [RKURL URLWithBaseURL:self resourcePath:theResourcePath queryParameters:theQueryParameters];
}

- (RKURL *)URLByAppendingQueryParameters:(NSDictionary *)theQueryParameters
{
    return [RKURL URLWithBaseURL:self resourcePath:nil queryParameters:theQueryParameters];
}

- (RKURL *)URLByReplacingResourcePath:(NSString *)newResourcePath
{
    return [RKURL URLWithBaseURL:self.baseURL resourcePath:newResourcePath];
}

- (RKURL *)URLByInterpolatingResourcePathWithObject:(id)object
{
    return [self URLByReplacingResourcePath:[self.resourcePath interpolateWithObject:object]];
}

#pragma mark - NSURL Overloads

/*
 Overload implementations from NSURL. We consider a naked string to be initialized
 with a baseURL == self. Otherwise appending/replacing resourcePath will not work.
 */

+ (id)URLWithString:(NSString *)URLString
{
    return [self URLWithBaseURLString:URLString];
}

- (id)initWithString:(NSString *)URLString
{
    self = [super initWithString:URLString];
    if (self) {
        self.baseURL = self;
    }

    return self;
}

@end
