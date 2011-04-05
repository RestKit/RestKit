//
//  RKRequestCache.m
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKRequestCache.h"


static NSString* sessionCacheFolder = @"SessionStore";
static NSString* permanentCacheFolder = @"PermanentStore";
static NSString* headersExtension = @"headers";
static NSString* cacheDateHeaderKey = @"X-RESTKIT-CACHEDATE";

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
	if (self = [super init]) {
		_cachePath = [cachePath copy];
		_cacheLock = [[NSRecursiveLock alloc] init];

		NSFileManager* fileManager = [[NSFileManager alloc] init];
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
									  withIntermediateDirectories:NO
													   attributes:nil
															error:&error];
				if (!created || error != nil) {
					NSLog(@"[RestKit] RKRequestCache: Failed to create cache directory at %@: error %@",
						  path, [error localizedDescription]);
				}
			} else if (!isDirectory) {
				NSLog(@"[RestKit] RKRequestCache: Failed to create cache directory: Directory already exists: %@", path);
			}
		}

		[fileManager release];

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
	return pathForRequest;
}

- (BOOL)hasResponseForRequest:(RKRequest*)request {
	[_cacheLock lock];

	BOOL hasEntryForRequest = NO;
	NSFileManager* fileManager = [[NSFileManager alloc] init];

	NSString* cachePath = [self pathForRequest:request];
	hasEntryForRequest = ([fileManager fileExistsAtPath:cachePath] &&
						  [fileManager fileExistsAtPath:
						   [cachePath stringByAppendingPathExtension:headersExtension]]);

	[fileManager release];

	[_cacheLock unlock];
	return hasEntryForRequest;
}

- (void)storeResponse:(RKResponse*)response forRequest:(RKRequest*)request {
	[_cacheLock lock];

	if ([self hasResponseForRequest:request]) {
		[self invalidateRequest:request];
	}

	if (_storagePolicy != RKRequestCacheStoragePolicyDisabled) {
		NSString* cachePath = [self pathForRequest:request];
		if (cachePath) {
			NSData* body = response.body;
			if (body) {
				[body writeToFile:cachePath atomically:NO];
			}

			NSMutableDictionary* headers = [response.allHeaderFields mutableCopy];
			NSLog(@"headers = %@", headers);
			if (headers) {
				[headers setObject:[[RKRequestCache rfc1123DateFormatter] stringFromDate:[NSDate date]]
							forKey:cacheDateHeaderKey];
				[headers writeToFile:[cachePath stringByAppendingPathExtension:headersExtension]
						  atomically:NO];
			}
			[headers release];
		}
	}

	[_cacheLock unlock];
}

//- (void)storeResponse:(RKResponse*)response forRequest:(RKRequest*)request expires:(NSTimeInterval)expirationAge {
//	[_cacheLock lock];
//
//	if (_storagePolicy != RKRequestCacheStoragePolicyDisabled) {
//		NSString* cachePath = [self pathForRequest:request];
//		if (cachePath) {
//			NSData* body = response.body;
//			if (body) {
//				[body writeToFile:cachePath atomically:NO];
//			}
//
//			NSMutableDictionary* headers = [response.allHeaderFields mutableCopy];
//			if (headers) {
//				if (expirationAge != 0) {
//					[headers removeObjectForKey:@"Expires"];
//					[headers setObject:[NSString stringWithFormat:@"max-age=%i",(int)expirationAge]
//								forKey:@"Cache-Control"];
//				}
//				[headers setObject:[[RKRequestCache rfc1123DateFormatter] stringFromDate:[NSDate date]]
//							forKey:cacheDateHeaderKey];
//				[headers writeToFile:[cachePath stringByAppendingPathExtension:headersExtension]
//						  atomically:NO];
//			}
//			[headers release];
//		}
//	}
//
//	[_cacheLock unlock];
//}

- (RKResponse*)responseForRequest:(RKRequest*)request {
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
	return response;
}

- (NSString*)etagForRequest:(RKRequest*)request {
	NSString* etag = nil;
	[_cacheLock lock];

	NSString* cachePath = [self pathForRequest:request];
	if (cachePath) {
		NSDictionary* responseHeaders = [NSDictionary dictionaryWithContentsOfFile:
										 [cachePath stringByAppendingPathExtension:headersExtension]];
		if (responseHeaders) {
			for (NSString* responseHeader in responseHeaders) {
				if ([responseHeader isEqualToString:@"Etag"]) {
					etag = [responseHeaders objectForKey:responseHeader];
				}
			}
		}
	}

	[_cacheLock unlock];
	return etag;
}

- (void)invalidateRequest:(RKRequest*)request {
	[_cacheLock lock];

	NSString* cachePath = [self pathForRequest:request];
	if (cachePath) {
		NSFileManager* fileManager = [[NSFileManager alloc] init];
		[fileManager removeItemAtPath:cachePath error:NULL];
		[fileManager removeItemAtPath:[cachePath stringByAppendingPathExtension:headersExtension]
																		  error:NULL];
		[fileManager release];
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

		NSFileManager* fileManager = [[NSFileManager alloc] init];

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
						NSLog(@"[RestKit] RKRequestCache: Failed to delete cache entry for file: %@", cacheEntryPath);
					}
				}
			} else {
				NSLog(@"[RestKit] RKRequestCache: Failed to fetch list of cache entries for cache path: %@", cachePath);
			}
		}

		[fileManager release];
	}

	[_cacheLock unlock];
}

- (void)invalidateAll {
	[_cacheLock lock];

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
