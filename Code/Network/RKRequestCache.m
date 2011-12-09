//
//  RKRequestCache.m
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
//  Copyright 2011 Two Toasters
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

static NSString* sessionCacheFolder = @"SessionStore";
static NSString* permanentCacheFolder = @"PermanentStore";
static NSString* headersExtension = @"headers";
static NSString* cacheDateHeaderKey = @"X-RESTKIT-CACHEDATE";
NSString* cacheResponseCodeKey = @"X-RESTKIT-CACHED-RESPONSE-CODE";
NSString* cacheMIMETypeKey = @"X-RESTKIT-CACHED-MIME-TYPE";
NSString* cacheURLKey = @"X-RESTKIT-CACHED-URL";

static NSDateFormatter* __rfc1123DateFormatter;

@implementation RKRequestCache

@synthesize storagePolicy = _storagePolicy;

+ (NSDateFormatter*)rfc1123DateFormatter {
	if (__rfc1123DateFormatter == nil) {
		__rfc1123DateFormatter = [[NSDateFormatter alloc] init];
		[__rfc1123DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[__rfc1123DateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
	}
	return __rfc1123DateFormatter;
}

- (id)initWithCachePath:(NSString*)cachePath storagePolicy:(RKRequestCacheStoragePolicy)storagePolicy {
    self = [super init];
	if (self) {
		_cachePath = [cachePath copy];
		_cacheLock = [[NSRecursiveLock alloc] init];

		NSFileManager* fileManager = [NSFileManager defaultManager];
		NSArray* pathArray = [NSArray arrayWithObjects:
							  _cachePath,
							  [_cachePath stringByAppendingPathComponent:sessionCacheFolder],
							  [_cachePath stringByAppendingPathComponent:permanentCacheFolder],
							  nil];

		for (NSString* path in pathArray) {
			BOOL isDirectory = NO;
			BOOL fileExists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
			if (!fileExists) {
				NSError* error = nil;
				BOOL created = [fileManager createDirectoryAtPath:path
									  withIntermediateDirectories:YES
													   attributes:nil
															error:&error];
				if (!created || error != nil) {
					RKLogError(@"Failed to create cache directory at %@: error %@", path, [error localizedDescription]);
				} else {
                    RKLogDebug(@"Created cache storage at path '%@'", path);
                }
			} else {
                if (!isDirectory) {
                    RKLogWarning(@"Skipped creation of cache directory as non-directory file exists at path: %@", path);
                }
			}
		}

		self.storagePolicy = storagePolicy;
	}
    
	return self;
}

- (void)dealloc {
	[_cachePath release];
	_cachePath = nil;
	[_cacheLock release];
	_cacheLock = nil;
	[super dealloc];
}

- (NSString*)cachePath {
	return _cachePath;
}

- (NSString*)pathForRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return nil;
    }
    
	[_cacheLock lock];

	NSString* pathForRequest = nil;

	if (_storagePolicy == RKRequestCacheStoragePolicyForDurationOfSession) {
		pathForRequest = [[_cachePath stringByAppendingPathComponent:sessionCacheFolder]
						  stringByAppendingPathComponent:[request cacheKey]];

	} else if (_storagePolicy == RKRequestCacheStoragePolicyPermanently) {
		pathForRequest = [[_cachePath stringByAppendingPathComponent:permanentCacheFolder]
						  stringByAppendingPathComponent:[request cacheKey]];
	}

	[_cacheLock unlock];
    RKLogTrace(@"Found cachePath '%@' for %@", pathForRequest, request);
    
	return pathForRequest;
}

- (BOOL)hasResponseForRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return NO;
    }
    
	[_cacheLock lock];

	BOOL hasEntryForRequest = NO;
	NSFileManager* fileManager = [NSFileManager defaultManager];

	NSString* cachePath = [self pathForRequest:request];
	hasEntryForRequest = ([fileManager fileExistsAtPath:cachePath] &&
						  [fileManager fileExistsAtPath:
						   [cachePath stringByAppendingPathExtension:headersExtension]]);

	[_cacheLock unlock];
    RKLogTrace(@"Determined hasResponseForRequest: %@ => %@", request, hasEntryForRequest ? @"YES" : @"NO");
	return hasEntryForRequest;
}

- (void)writeHeaders:(NSDictionary*)headers toCachePath:(NSString*)cachePath {
    RKLogTrace(@"Writing headers to cache path: '%@'", cachePath);
    BOOL success = [headers writeToFile:[cachePath
                                         stringByAppendingPathExtension:headersExtension]
                             atomically:YES];
    if (success) {
        RKLogTrace(@"Wrote cached response header to path '%@'", cachePath);
        
    } else {
        RKLogError(@"Failed to write cached response headers to path '%@'", cachePath);
    }
}

- (void)storeResponse:(RKResponse*)response forRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return;
    }
    
	[_cacheLock lock];
    
	if ([self hasResponseForRequest:request]) {
		[self invalidateRequest:request];
	}

	if (_storagePolicy != RKRequestCacheStoragePolicyDisabled) {
		NSString* cachePath = [self pathForRequest:request];
		if (cachePath) {
			NSData* body = response.body;
			if (body) {
                NSError* error = nil;
                BOOL success = [body writeToFile:cachePath options:NSDataWritingAtomic error:&error];
                if (success) {
                    RKLogTrace(@"Wrote cached response body to path '%@'", cachePath);                    
                } else {
                    RKLogError(@"Failed to write cached response body to path '%@': %@", cachePath, [error localizedDescription]);
                }
			}

			NSMutableDictionary* headers = [response.allHeaderFields mutableCopy];
			if (headers) {
                NSHTTPURLResponse* urlResponse = [response valueForKey:@"_httpURLResponse"];
                // Cache Loaded Time
				[headers setObject:[[RKRequestCache rfc1123DateFormatter] stringFromDate:[NSDate date]]
							forKey:cacheDateHeaderKey];
                // Cache status code
                [headers setObject:[NSNumber numberWithInteger:urlResponse.statusCode]
							forKey:cacheResponseCodeKey];
                // Cache MIME Type
                [headers setObject:urlResponse.MIMEType
							forKey:cacheMIMETypeKey];
                // Cache URL
                [headers setObject:[urlResponse.URL absoluteString]
							forKey:cacheURLKey];
                // Save
                [self writeHeaders:headers toCachePath:cachePath];
			}
            
			[headers release];
		}
	}

	[_cacheLock unlock];
}

- (RKResponse*)responseForRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return nil;
    }
    
	[_cacheLock lock];

	RKResponse* response = nil;

	NSString* cachePath = [self pathForRequest:request];
	if (cachePath) {
		NSData* responseData = [NSData dataWithContentsOfFile:cachePath];

		NSDictionary* responseHeaders = [NSDictionary dictionaryWithContentsOfFile:
										 [cachePath stringByAppendingPathExtension:headersExtension]];

		response = [[[RKResponse alloc] initWithRequest:request body:responseData headers:responseHeaders] autorelease];
	}

	[_cacheLock unlock];
    RKLogDebug(@"Found cached RKResponse '%@' for '%@'", request, response);
	return response;
}

- (NSDictionary*)headersForRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return nil;
    }
    NSString* cachePath = [self pathForRequest:request];
    
    [_cacheLock lock];
    
    NSDictionary* headers = nil;
    if (cachePath) {
        NSString* headersPath = [cachePath stringByAppendingPathExtension:headersExtension];
        headers = [NSDictionary dictionaryWithContentsOfFile:headersPath];
        if (headers) {
            RKLogDebug(@"Read cached headers '%@' from cachePath '%@' for '%@'", headers, headersPath, request);
        } else {
            RKLogDebug(@"Read nil cached headers from cachePath '%@' for '%@'", headersPath, request);
        }
    } else {
        RKLogDebug(@"Unable to read cached headers for '%@': cachePath not found", request);
    }
    
    [_cacheLock unlock];    
    return headers;
}

- (NSString*)etagForRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return nil;
    }
	NSString* etag = nil;

    NSDictionary* responseHeaders = [self headersForRequest:request];
    
    [_cacheLock lock];
    if (responseHeaders) {
        for (NSString* responseHeader in responseHeaders) {
            if ([[responseHeader uppercaseString] isEqualToString:[@"ETag" uppercaseString]]) {
                etag = [responseHeaders objectForKey:responseHeader];
            }
        }
    }

	[_cacheLock unlock];
    RKLogDebug(@"Found cached ETag '%@' for '%@'", etag, request);
	return etag;
}

- (void)setCacheDate:(NSDate*)date forRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return;
    }
    NSMutableDictionary* responseHeaders = [[self headersForRequest:request] mutableCopy];
    
    [responseHeaders setObject:[[RKRequestCache rfc1123DateFormatter] stringFromDate:date]
                                 forKey:cacheDateHeaderKey];
    [self writeHeaders:responseHeaders toCachePath:[self pathForRequest:request]];
    
    [responseHeaders release];
}

- (NSDate*)cacheDateForRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return nil;
    }
	NSDate* date = nil;
    NSString* dateString = nil;
    
    NSDictionary* responseHeaders = [self headersForRequest:request];
    
    [_cacheLock lock];
    if (responseHeaders) {
        for (NSString* responseHeader in responseHeaders) {
            if ([[responseHeader uppercaseString] isEqualToString:[cacheDateHeaderKey uppercaseString]]) {
                dateString = [responseHeaders objectForKey:responseHeader];
            }
        }
    }
	[_cacheLock unlock];
    date = [[RKRequestCache rfc1123DateFormatter] dateFromString:dateString];
    
    RKLogDebug(@"Found cached date '%@' for '%@'", date, request);
	return date;
}

- (void)invalidateRequest:(RKRequest*)request {
    if (! [request isCacheable]) {
        return;
    }
    
	[_cacheLock lock];
    RKLogDebug(@"Invalidating cache entry for '%@'", request);
    
	NSString* cachePath = [self pathForRequest:request];
	if (cachePath) {
		NSFileManager* fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:cachePath error:NULL];
		[fileManager removeItemAtPath:[cachePath stringByAppendingPathExtension:headersExtension]
																		  error:NULL];
        RKLogTrace(@"Removed cache entry at path '%@' for '%@'", cachePath, request);
	}

	[_cacheLock unlock];
}

- (void)invalidateWithStoragePolicy:(RKRequestCacheStoragePolicy)storagePolicy {
	[_cacheLock lock];

	if (_cachePath && storagePolicy != RKRequestCacheStoragePolicyDisabled) {
		NSString* cachePath = nil;
		if (storagePolicy == RKRequestCacheStoragePolicyForDurationOfSession) {
			cachePath = [_cachePath stringByAppendingPathComponent:sessionCacheFolder];
		} else {
			cachePath = [_cachePath stringByAppendingPathComponent:permanentCacheFolder];
		}
        
        RKLogInfo(@"Invalidating cache at path: %@", cachePath);
		NSFileManager* fileManager = [NSFileManager defaultManager];

		BOOL isDirectory = NO;
		BOOL fileExists = [fileManager fileExistsAtPath:cachePath isDirectory:&isDirectory];

		if (fileExists && isDirectory) {
			NSError* error = nil;
			NSArray* cacheEntries = [fileManager contentsOfDirectoryAtPath:cachePath error:&error];

			if (nil == error) {
				for (NSString* cacheEntry in cacheEntries) {
					NSString* cacheEntryPath = [cachePath stringByAppendingPathComponent:cacheEntry];
					[fileManager removeItemAtPath:cacheEntryPath error:&error];
					[fileManager removeItemAtPath:[cacheEntryPath stringByAppendingPathExtension:headersExtension]
											error:&error];
					if (nil != error) {
						RKLogError(@"Failed to delete cache entry for file: %@", cacheEntryPath);
					}
				}
			} else {
				RKLogWarning(@"Failed to fetch list of cache entries for cache path: %@", cachePath);
			}
		}
	}

	[_cacheLock unlock];
}

- (void)invalidateAll {
	[_cacheLock lock];
    
    RKLogInfo(@"Invalidating all cache entries...");
	[self invalidateWithStoragePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
	[self invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

	[_cacheLock unlock];
}

- (void)setStoragePolicy:(RKRequestCacheStoragePolicy)storagePolicy {
	[self invalidateWithStoragePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
	if (storagePolicy == RKRequestCacheStoragePolicyDisabled) {
		[self invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
	}
	_storagePolicy = storagePolicy;
}

@end
