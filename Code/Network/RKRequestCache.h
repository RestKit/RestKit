//
//  RKRequestCache.h
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKRequest.h"
#import "RKResponse.h"


/**
 * Storage policy. Determines if we clear the cache out when the app is shut down.
 * Cache instance needs to register for
 */
typedef enum {
    RKRequestCacheStoragePolicyDisabled,				// The cache has been disabled. Attempts to store data will silently fail
    RKRequestCacheStoragePolicyForDurationOfSession,	// Cache data for the length of the session. Clear cache at app exit.
    RKRequestCacheStoragePolicyPermanently				// Cache data permanently, until explicitly expired or flushed
} RKRequestCacheStoragePolicy;


@interface RKRequestCache : NSObject {
    NSString* _cachePath;
    RKRequestCacheStoragePolicy _storagePolicy;
	NSRecursiveLock* _cacheLock;
}

@property (nonatomic, readonly) NSString* cachePath; // Full path to the cache
@property (nonatomic, assign) RKRequestCacheStoragePolicy storagePolicy; // User can change storage policy.

+ (NSDateFormatter*)rfc1123DateFormatter;

- (id)initWithCachePath:(NSString*)cachePath storagePolicy:(RKRequestCacheStoragePolicy)storagePolicy;

- (NSString*)pathForRequest:(RKRequest*)request;

- (BOOL)hasResponseForRequest:(RKRequest*)request;

- (void)storeResponse:(RKResponse*)response forRequest:(RKRequest*)request;

//- (void)storeResponse:(RKResponse*)response forRequest:(RKRequest*)request expires:(NSTimeInterval)expirationAge;

- (RKResponse*)responseForRequest:(RKRequest*)request;

- (NSDictionary*)headersForRequest:(RKRequest*)request;

- (NSString*)etagForRequest:(RKRequest*)request;

- (NSDate*)cacheDateForRequest:(RKRequest*)request;

- (void)setCacheDate:(NSDate*)date forRequest:(RKRequest*)request;

- (void)invalidateRequest:(RKRequest*)request;

- (void)invalidateWithStoragePolicy:(RKRequestCacheStoragePolicy)storagePolicy;

- (void)invalidateAll;

@end
