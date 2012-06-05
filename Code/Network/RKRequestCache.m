//
//  RKRequestCache.m
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
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

#import "RKRequestCache.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetworkCache

NSString * const RKRequestCacheSessionCacheDirectory = @"SessionStore";
NSString * const RKRequestCachePermanentCacheDirectory = @"PermanentStore";
NSString * const RKRequestCacheHeadersExtension = @"headers";
NSString * const RKRequestCacheDateHeaderKey = @"X-RESTKIT-CACHEDATE";
NSString * const RKRequestCacheStatusCodeHeadersKey = @"X-RESTKIT-CACHED-RESPONSE-CODE";
NSString * const RKRequestCacheMIMETypeHeadersKey = @"X-RESTKIT-CACHED-MIME-TYPE";
NSString * const RKRequestCacheURLHeadersKey = @"X-RESTKIT-CACHED-URL";

static NSDateFormatter *__rfc1123DateFormatter;

@implementation RKRequestCache

@synthesize storagePolicy = _storagePolicy;

+ (NSDateFormatter *)rfc1123DateFormatter
{
    if (__rfc1123DateFormatter == nil) {
        __rfc1123DateFormatter = [[NSDateFormatter alloc] init];
        [__rfc1123DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [__rfc1123DateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
    }
    return __rfc1123DateFormatter;
}

- (id)initWithPath:(NSString *)cachePath storagePolicy:(RKRequestCacheStoragePolicy)storagePolicy
{
    self = [super init];
    if (self) {
        _cache = [[RKCache alloc] initWithPath:cachePath
                                     subDirectories:
                  [NSArray arrayWithObjects:RKRequestCacheSessionCacheDirectory,
                   RKRequestCachePermanentCacheDirectory, nil]];
        self.storagePolicy = storagePolicy;
    }

    return self;
}

- (void)dealloc
{
    [_cache release];
    _cache = nil;
    [super dealloc];
}

- (NSString *)path
{
    return _cache.cachePath;
}

- (NSString *)pathForRequest:(RKRequest *)request
{
    NSString *pathForRequest = nil;
    NSString *requestCacheKey = [request cacheKey];
    if (requestCacheKey) {
        if (_storagePolicy == RKRequestCacheStoragePolicyForDurationOfSession) {
            pathForRequest = [RKRequestCacheSessionCacheDirectory stringByAppendingPathComponent:requestCacheKey];

        } else if (_storagePolicy == RKRequestCacheStoragePolicyPermanently) {
            pathForRequest = [RKRequestCachePermanentCacheDirectory stringByAppendingPathComponent:requestCacheKey];
        }
        RKLogTrace(@"Found cacheKey '%@' for %@", pathForRequest, request);
    } else {
        RKLogTrace(@"Failed to find cacheKey for %@ due to nil cacheKey", request);
    }
    return pathForRequest;
}

- (BOOL)hasResponseForRequest:(RKRequest *)request
{
    BOOL hasEntryForRequest = NO;
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        hasEntryForRequest = ([_cache hasEntry:cacheKey] &&
                              [_cache hasEntry:[cacheKey stringByAppendingPathExtension:RKRequestCacheHeadersExtension]]);
    }
    RKLogTrace(@"Determined hasResponseForRequest: %@ => %@", request, hasEntryForRequest ? @"YES" : @"NO");
    return hasEntryForRequest;
}

- (void)storeResponse:(RKResponse *)response forRequest:(RKRequest *)request
{
    if ([self hasResponseForRequest:request]) {
        [self invalidateRequest:request];
    }

    if (_storagePolicy != RKRequestCacheStoragePolicyDisabled) {
        NSString *cacheKey = [self pathForRequest:request];
        if (cacheKey) {
            [_cache writeData:response.body withCacheKey:cacheKey];

            NSMutableDictionary *headers = [response.allHeaderFields mutableCopy];
            if (headers) {
                // TODO: expose this?
                NSHTTPURLResponse *urlResponse = [response valueForKey:@"_httpURLResponse"];
                // Cache Loaded Time
                [headers setObject:[[RKRequestCache rfc1123DateFormatter] stringFromDate:[NSDate date]]
                            forKey:RKRequestCacheDateHeaderKey];
                // Cache status code
                [headers setObject:[NSNumber numberWithInteger:urlResponse.statusCode]
                            forKey:RKRequestCacheStatusCodeHeadersKey];
                // Cache MIME Type
                [headers setObject:urlResponse.MIMEType
                            forKey:RKRequestCacheMIMETypeHeadersKey];
                // Cache URL
                [headers setObject:[urlResponse.URL absoluteString]
                            forKey:RKRequestCacheURLHeadersKey];
                // Save
                [_cache writeDictionary:headers withCacheKey:[cacheKey stringByAppendingPathExtension:RKRequestCacheHeadersExtension]];
            }
            [headers release];
        }
    }
}

- (RKResponse *)responseForRequest:(RKRequest *)request
{
    RKResponse *response = nil;
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        NSData *responseData = [_cache dataForCacheKey:cacheKey];
        NSDictionary *responseHeaders = [_cache dictionaryForCacheKey:[cacheKey stringByAppendingPathExtension:RKRequestCacheHeadersExtension]];
        response = [[[RKResponse alloc] initWithRequest:request body:responseData headers:responseHeaders] autorelease];
    }
    RKLogDebug(@"Found cached RKResponse '%@' for '%@'", response, request);
    return response;
}

- (NSDictionary *)headersForRequest:(RKRequest *)request
{
    NSDictionary *headers = nil;
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        NSString *headersCacheKey = [cacheKey stringByAppendingPathExtension:RKRequestCacheHeadersExtension];
        headers = [_cache dictionaryForCacheKey:headersCacheKey];
        if (headers) {
            RKLogDebug(@"Read cached headers '%@' from headersCacheKey '%@' for '%@'", headers, headersCacheKey, request);
        } else {
            RKLogDebug(@"Read nil cached headers from headersCacheKey '%@' for '%@'", headersCacheKey, request);
        }
    } else {
        RKLogDebug(@"Unable to read cached headers for '%@': cacheKey not found", request);
    }
    return headers;
}

- (NSString *)etagForRequest:(RKRequest *)request
{
    NSString *etag = nil;

    NSDictionary *responseHeaders = [self headersForRequest:request];
    if (responseHeaders) {
        for (NSString *responseHeader in responseHeaders) {
            if ([[responseHeader uppercaseString] isEqualToString:[@"ETag" uppercaseString]]) {
                etag = [responseHeaders objectForKey:responseHeader];
            }
        }
    }
    RKLogDebug(@"Found cached ETag '%@' for '%@'", etag, request);
    return etag;
}

- (void)setCacheDate:(NSDate *)date forRequest:(RKRequest *)request
{
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        NSMutableDictionary *responseHeaders = [[self headersForRequest:request] mutableCopy];

        [responseHeaders setObject:[[RKRequestCache rfc1123DateFormatter] stringFromDate:date]
                                     forKey:RKRequestCacheDateHeaderKey];
        [_cache writeDictionary:responseHeaders
                   withCacheKey:[cacheKey stringByAppendingPathExtension:RKRequestCacheHeadersExtension]];
        [responseHeaders release];
    }
}

- (NSDate *)cacheDateForRequest:(RKRequest *)request
{
    NSDate *date = nil;
    NSString *dateString = nil;

    NSDictionary *responseHeaders = [self headersForRequest:request];
    if (responseHeaders) {
        for (NSString *responseHeader in responseHeaders) {
            if ([[responseHeader uppercaseString] isEqualToString:[RKRequestCacheDateHeaderKey uppercaseString]]) {
                dateString = [responseHeaders objectForKey:responseHeader];
            }
        }
    }
    date = [[RKRequestCache rfc1123DateFormatter] dateFromString:dateString];
    RKLogDebug(@"Found cached date '%@' for '%@'", date, request);
    return date;
}

- (void)invalidateRequest:(RKRequest *)request
{
    RKLogDebug(@"Invalidating cache entry for '%@'", request);
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        [_cache invalidateEntry:cacheKey];
        [_cache invalidateEntry:[cacheKey stringByAppendingPathExtension:RKRequestCacheHeadersExtension]];
        RKLogTrace(@"Removed cache entry at path '%@' for '%@'", cacheKey, request);
    }
}

- (void)invalidateWithStoragePolicy:(RKRequestCacheStoragePolicy)storagePolicy
{
    if (storagePolicy != RKRequestCacheStoragePolicyDisabled) {
        if (storagePolicy == RKRequestCacheStoragePolicyForDurationOfSession) {
            [_cache invalidateSubDirectory:RKRequestCacheSessionCacheDirectory];
        } else {
            [_cache invalidateSubDirectory:RKRequestCachePermanentCacheDirectory];
        }
    }
}

- (void)invalidateAll
{
    RKLogInfo(@"Invalidating all cache entries...");
    [_cache invalidateSubDirectory:RKRequestCacheSessionCacheDirectory];
    [_cache invalidateSubDirectory:RKRequestCachePermanentCacheDirectory];
}

- (void)setStoragePolicy:(RKRequestCacheStoragePolicy)storagePolicy
{
    [self invalidateWithStoragePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
    if (storagePolicy == RKRequestCacheStoragePolicyDisabled) {
        [self invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    }
    _storagePolicy = storagePolicy;
}

@end
