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
 Cache storage policy used to determines how long we keep a specific cache for.
 */
typedef enum {
    /**
     The cache is disabled. Attempts to store data will silently fail.
     */
    RKRequestCacheStoragePolicyDisabled,
    /**
     Cache data for the length of the session and clear when the app exits.
     */
    RKRequestCacheStoragePolicyForDurationOfSession,
    /**
     Cache data permanently until explicitly expired or flushed.
     */
    RKRequestCacheStoragePolicyPermanently
} RKRequestCacheStoragePolicy;

/**
 Stores and retrieves cache entries for RestKit request objects.
 */
@interface RKRequestCache : NSObject {
    NSString *_cachePath;
    RKRequestCacheStoragePolicy _storagePolicy;
	NSRecursiveLock *_cacheLock;
}


///-----------------------------------------------------------------------------
/// @name Creating a Request Cache
///-----------------------------------------------------------------------------

/**
 Returns an RKRequestCache object with the specified cache path and storage
 policy.
 
 @param cachePath A string of the full path to the cache.
 @param storagePolicy The RKRequestStoragePolicy to determine how long to retain
 this cache.
 @return An RKRequestCache object with the cachePath and storagePolicy set.
 */
- (id)initWithCachePath:(NSString *)cachePath storagePolicy:(RKRequestCacheStoragePolicy)storagePolicy;


///-----------------------------------------------------------------------------
/// @name Locating the Cache
///-----------------------------------------------------------------------------

/**
 Returns the full path to the cache.
 */
@property (nonatomic, readonly) NSString *cachePath;

/**
 Returns the cache path for the specified request.
 
 @param request An RKRequest object to determine the cache path.
 @return A string of the cache path for the specified request.
 */
- (NSString *)pathForRequest:(RKRequest *)request;

/**
 Determine if a response exists for a request.
 
 @param request An RKRequest object that is looking for cached content.
 @return A boolean value for if a response exists in the cache.
 */
- (BOOL)hasResponseForRequest:(RKRequest *)request;


///-----------------------------------------------------------------------------
/// @name Populating the Cache
///-----------------------------------------------------------------------------

/**
 Store a request's response in the cache.
 
 @param response The response to be stored in the cache.
 @param request The request that retrieved the response.
 */
- (void)storeResponse:(RKResponse *)response forRequest:(RKRequest *)request;

/**
 Set the cache date for a request.
 
 @param date The date the response for a request was cached.
 @param request The request to store the cache date for.
 */
- (void)setCacheDate:(NSDate *)date forRequest:(RKRequest *)request;


///-----------------------------------------------------------------------------
/// @name Preparing Requests and Responses
///-----------------------------------------------------------------------------

/**
 Returns a dictionary of cached headers for a cached request.
 
 @param request The request to retrieve cached headers for.
 @return An NSDictionary of the cached headers that were stored for the
 specified request.
 */
- (NSDictionary *)headersForRequest:(RKRequest *)request;

/**
 Returns an ETag for a request if it is stored in the cached headers.
 
 @param request The request that an ETag is to be determined for.
 @return A string of the ETag value stored for the specified request.
 */
- (NSString *)etagForRequest:(RKRequest *)request;

/**
 Returns the date of the cached request.
 
 @param request The request that needs a cache date returned.
 @return A date object for the cached request.
 */
- (NSDate *)cacheDateForRequest:(RKRequest *)request;

/**
 Returns the cached response for a given request.
 
 @param request The request used to find the cached response.
 @return An RKResponse object that was cached for a given request.
 */
- (RKResponse *)responseForRequest:(RKRequest *)request;


///-----------------------------------------------------------------------------
/// @name Invalidating the Cache
///-----------------------------------------------------------------------------

/**
 The storage policy for the cache.
 */
@property (nonatomic, assign) RKRequestCacheStoragePolicy storagePolicy;

/**
 Invalidate the cache for a given request.
 
 @param request The request that needs its cache invalidated.
 */
- (void)invalidateRequest:(RKRequest *)request;

/**
 Invalidate any caches that fall under the given storage policy.
 
 @param storagePolicy The RKRequestCacheStorePolicy used to determine which
 caches need to be invalidated.
 */
- (void)invalidateWithStoragePolicy:(RKRequestCacheStoragePolicy)storagePolicy;

/**
 Invalidate all caches on disk.
 */
- (void)invalidateAll;


///-----------------------------------------------------------------------------
/// @name Helpers
///-----------------------------------------------------------------------------

/**
 The date formatter used to generate the cache date for the HTTP header.
 */
+ (NSDateFormatter *)rfc1123DateFormatter;

@end
