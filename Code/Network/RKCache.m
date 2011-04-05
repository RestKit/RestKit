//
//  RKCache.m
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKCache.h"
#import "NSString+MD5.h"


NSString* RKCacheKeyForURL(NSURL* URL) {
	return [[URL absoluteString] MD5];
}

static NSString* sessionCacheFolder = @"SessionStore";
static NSString* permanentCacheFolder = @"PermanentStore";

@implementation RKCache

@synthesize storagePolicy = _storagePolicy;

- (id)initWithCachePath:(NSString*)cachePath storagePolicy:(RKCacheStoragePolicy)storagePolicy {
	if (self = [super init]) {
		_cachePath = [cachePath copy];
		_storagePolicy = storagePolicy;
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
					NSLog(@"[RestKit] RKCache: Failed to create cache directory at %@: error %@",
						  path, [error localizedDescription]);
				}
			} else if (!isDirectory) {
				NSLog(@"[RestKit] RKCache: Failed to create cache directory: Directory already exists: %@", path);
			}
		}

		[fileManager release];
	}
	return self;
}

- (NSString*)cachePath {
	return _cachePath;
}

// Key/value storage
- (NSString*)pathForKey:(NSString*)key {
	[_cacheLock lock];

	NSString* pathForKey = nil;

	if (_storagePolicy == RKCacheStoragePolicyForDurationOfSession) {
		pathForKey = [[_cachePath stringByAppendingPathComponent:sessionCacheFolder]
					  stringByAppendingPathComponent:key];

	} else if (_storagePolicy == RKCacheStoragePolicyPermanently) {
		pathForKey = [[_cachePath stringByAppendingPathComponent:permanentCacheFolder]
					  stringByAppendingPathComponent:key];
	}

	[_cacheLock unlock];
	return pathForKey;
}

- (BOOL)hasDataForKey:(NSString*)key {
	[_cacheLock lock];

	BOOL hasDataForKey = NO;
	NSFileManager* fileManager = [[NSFileManager alloc] init];

	if (_storagePolicy == RKCacheStoragePolicyForDurationOfSession) {
		NSString* sessionPath = [[_cachePath stringByAppendingPathComponent:sessionCacheFolder]
								 stringByAppendingPathComponent:key];
		hasDataForKey = [fileManager fileExistsAtPath:sessionPath];

	} else if (_storagePolicy == RKCacheStoragePolicyPermanently) {
		NSString* permanentPath = [[_cachePath stringByAppendingPathComponent:permanentCacheFolder]
								   stringByAppendingPathComponent:key];
		hasDataForKey = [fileManager fileExistsAtPath:permanentPath];
	}

	[fileManager release];

	[_cacheLock unlock];
	return hasDataForKey;
}

- (void)storeData:(NSData*)data forKey:(NSString*)key {
	[_cacheLock lock];

	if (_storagePolicy != RKCacheStoragePolicyDisabled) {
		NSString* path = [self pathForKey:key];
		if (path) {
			[data writeToFile:path atomically:NO];
		}
	}

	[_cacheLock unlock];
}

- (NSData*)dataForKey:(NSString*)key {
	[_cacheLock lock];

	NSData* dataForKey = nil;
	NSString* path = [self pathForKey:key];
	if (path) {
		dataForKey = [NSData dataWithContentsOfFile:path];
	}

	[_cacheLock unlock];
	return dataForKey;
}

- (NSData*)dataForKey:(NSString*)key expires:(NSTimeInterval)expirationAge timestamp:(NSDate**)timestamp {
	[_cacheLock lock];

	/**
	 * TODO: Need to differentiate behavior here from dataForKey:
	 */
	NSData* dataForKey = [self dataForKey:key];

	[_cacheLock unlock];
	return dataForKey;
}

- (void)invalidateKey:(NSString*)key {
	[_cacheLock lock];

	NSString* path = [self pathForKey:key];
	if (path) {
		NSFileManager* fileManager = [[NSFileManager alloc] init];
		[fileManager removeItemAtPath:path error:NULL];
		[fileManager release];
	}

	[_cacheLock unlock];
}

- (void)invalidateAll {
	[_cacheLock lock];

	NSArray* pathArray = [NSArray arrayWithObjects:
						  [_cachePath stringByAppendingPathComponent:sessionCacheFolder],
						  [_cachePath stringByAppendingPathComponent:permanentCacheFolder],
						  nil];

	NSFileManager* fileManager = [[NSFileManager alloc] init];

	for (NSString* path in pathArray) {
		BOOL isDirectory = NO;
		BOOL fileExists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];

		if (!fileExists || !isDirectory) {
			continue;
		}

		NSError* error = nil;
		NSArray* cacheEntries = [fileManager contentsOfDirectoryAtPath:path error:&error];

		if (nil == error) {
			for (NSString* cacheEntry in cacheEntries) {
				NSString* cacheEntryPath = [path stringByAppendingPathComponent:cacheEntry];
				[fileManager removeItemAtPath:cacheEntryPath error:&error];

				if (nil != error) {
					NSLog(@"[RestKit] RKCache: Failed to delete cache entry for file: %@", cacheEntryPath);
				}
			}
		} else {
			NSLog(@"[RestKit] RKCache: Failed to fetch list of cache entries for cache path: %@", path);
		}
	}

	[fileManager release];

	[_cacheLock unlock];
}

@end
