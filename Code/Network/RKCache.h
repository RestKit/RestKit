//
//  RKCache.h
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>


NSString* RKCacheKeyForURL(NSURL* URL);

/**
 * Storage policy. Determines if we clear the cache out when the app is shut down.
 * Cache instance needs to register for
 */
typedef enum {
    RKCacheStoragePolicyDisabled,				// The cache has been disabled. Attempts to store data will silently fail
    RKCacheStoragePolicyForDurationOfSession,	// Cache data for the length of the session. Clear cache at app exit.
    RKCacheStoragePolicyPermanently				// Cache data permanently, until explicitly expired or flushed
} RKCacheStoragePolicy;


@interface RKCache : NSObject {
    NSString* _cachePath;
    RKCacheStoragePolicy _storagePolicy;
	NSRecursiveLock* _cacheLock;
}

@property (nonatomic, readonly) NSString* cachePath; // Full path to the cache
@property (nonatomic, assign) RKCacheStoragePolicy storagePolicy; // User can change storage policy.

- (id)initWithCachePath:(NSString*)cachePath storagePolicy:(RKCacheStoragePolicy)storagePolicy;

// Key/value storage
- (NSString*)pathForKey:(NSString*)key;

- (BOOL)hasDataForKey:(NSString*)key;

- (void)storeData:(NSData*)data forKey:(NSString*)key;

- (NSData*)dataForKey:(NSString*)key;

- (NSData*)dataForKey:(NSString*)key expires:(NSTimeInterval)expirationAge timestamp:(NSDate**)timestamp;

// Cache Invalidation
- (void)invalidateKey:(NSString*)key;

- (void)invalidateAll;

@end
