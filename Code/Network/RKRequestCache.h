//
//  RKRequestCache.h
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

/**
 Stores and retrieves cache entries for RestKit request objects.
 */
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

- (RKResponse*)responseForRequest:(RKRequest*)request;

- (NSDictionary*)headersForRequest:(RKRequest*)request;

- (NSString*)etagForRequest:(RKRequest*)request;

- (NSDate*)cacheDateForRequest:(RKRequest*)request;

- (void)setCacheDate:(NSDate*)date forRequest:(RKRequest*)request;

- (void)invalidateRequest:(RKRequest*)request;

- (void)invalidateWithStoragePolicy:(RKRequestCacheStoragePolicy)storagePolicy;

- (void)invalidateAll;

@end
