//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TTURLRequest;

/**
 * A general purpose URL cache for caching data in memory and on disk.
 *
 * Etags are supported.
 */
@interface TTURLCache : NSObject {
  NSString*             _name;
  NSString*             _cachePath;
  NSMutableDictionary*  _imageCache;
  NSMutableArray*       _imageSortedList;
  NSUInteger            _totalPixelCount;
  NSUInteger            _maxPixelCount;
  NSInteger             _totalLoading;
  NSTimeInterval        _invalidationAge;
  BOOL                  _disableDiskCache;
  BOOL                  _disableImageCache;
}

/**
 * Disables the disk cache. Disables etag support as well.
 */
@property (nonatomic) BOOL disableDiskCache;

/**
 * Disables the in-memory cache for images.
 */
@property (nonatomic) BOOL disableImageCache;

/**
 * Gets the path to the directory of the disk cache.
 */
@property (nonatomic, copy) NSString* cachePath;

/**
 * Gets the path to the directory of the disk cache for etags.
 */
@property (nonatomic, readonly) NSString* etagCachePath;

/**
 * The maximum number of pixels to keep in memory for cached images.
 *
 * Setting this to zero will allow an unlimited number of images to be cached.  The default
 * is zero.
 */
@property (nonatomic) NSUInteger maxPixelCount;

/**
 * The amount of time to set back the modification timestamp on files when invalidating them.
 */
@property (nonatomic) NSTimeInterval invalidationAge;


/**
 * Gets a shared cache identified with a unique name.
 */
+ (TTURLCache*)cacheWithName:(NSString*)name;

/**
 * Gets the shared cache singleton used across the application.
 */
+ (TTURLCache*)sharedCache;

/**
 * Sets the shared cache singleton used across the application.
 */
+ (void)setSharedCache:(TTURLCache*)cache;

- (id)initWithName:(NSString*)name;

/**
 * Gets the key that would be used to cache a URL response.
 */
- (NSString *)keyForURL:(NSString*)URL;

/**
 * Gets the path in the cache where a URL may be stored.
 */
- (NSString*)cachePathForURL:(NSString*)URL;

/**
 * Gets the path in the cache where a key may be stored.
 */
- (NSString*)cachePathForKey:(NSString*)key;

/**
 * Etag cache files are stored in the following way:
 * File name: <key>
 * File data: <etag value>
 *
 * @return The etag cache path for the given key.
 */
- (NSString*)etagCachePathForKey:(NSString*)key;

/**
 * Determines if there is a cache entry for a URL.
 */
- (BOOL)hasDataForURL:(NSString*)URL;

/**
 * Determines if there is a cache entry for a key.
 */
- (BOOL)hasDataForKey:(NSString*)key expires:(NSTimeInterval)expirationAge;

/**
 * Determines if there is an image cache entry for a URL.
 */
- (BOOL)hasImageForURL:(NSString*)URL fromDisk:(BOOL)fromDisk;

/**
 * Gets the data for a URL from the cache if it exists.
 *
 * @return nil if the URL is not cached.
 */
- (NSData*)dataForURL:(NSString*)URL;

/**
 * Gets the data for a URL from the cache if it exists and is newer than a minimum timestamp.
 *
 * @return nil if hthe URL is not cached or if the cache entry is older than the minimum.
 */
- (NSData*)dataForURL:(NSString*)URL expires:(NSTimeInterval)expirationAge
           timestamp:(NSDate**)timestamp;
- (NSData*)dataForKey:(NSString*)key expires:(NSTimeInterval)expirationAge
           timestamp:(NSDate**)timestamp;

/**
 * Gets an image from the in-memory image cache.
 *
 * @return nil if the URL is not cached.
 */
- (id)imageForURL:(NSString*)URL;
- (id)imageForURL:(NSString*)URL fromDisk:(BOOL)fromDisk;

/**
 * Get an etag value for a given cache key.
 */
- (NSString*)etagForKey:(NSString*)key;

/**
 * Stores a data on disk.
 */
- (void)storeData:(NSData*)data forURL:(NSString*)URL;
- (void)storeData:(NSData*)data forKey:(NSString*)key;

/**
 * Stores an image in the memory cache.
 */
- (void)storeImage:(UIImage*)image forURL:(NSString*)URL;

/**
 * Stores an etag value in the etag cache.
 */
- (void)storeEtag:(NSString*)etag forKey:(NSString*)key;

/**
 * Convenient way to create a temporary URL for some data and cache it in memory.
 *
 * @return The temporary URL
 */
- (NSString*)storeTemporaryImage:(UIImage*)image toDisk:(BOOL)toDisk;

/**
 * Convenient way to create a temporary URL for some data and cache in on disk.
 *
 * @return The temporary URL
 */
- (NSString*)storeTemporaryData:(NSData*)data;

/**
 * Convenient way to create a temporary URL for a file and move it to the disk cache.
 *
 * @return The temporary URL
 */
- (NSString*)storeTemporaryFile:(NSURL*)fileURL;

/**
 * Moves the data currently stored under one URL to another URL.
 *
 * This is handy when you are caching data at a temporary URL while the permanent URL is being
 * retrieved from a server.  Once you know the permanent URL you can use this to move the data.
 */
- (void)moveDataForURL:(NSString*)oldURL toURL:(NSString*)newURL;

- (void)moveDataFromPath:(NSString*)path toURL:(NSString*)newURL;

- (NSString*)moveDataFromPathToTemporaryURL:(NSString*)path;

/**
 * Removes the data for a URL from the memory cache and optionally from the disk cache.
 */
- (void)removeURL:(NSString*)URL fromDisk:(BOOL)fromDisk;

- (void)removeKey:(NSString*)key;

/**
 * Erases the memory cache and optionally the disk cache.
 */
- (void)removeAll:(BOOL)fromDisk;

/**
 * Invalidates the file in the disk cache so that its modified timestamp is the current
 * time minus the default cache expiration age.
 *
 * This ensures that the next time the URL is requested from the cache it will be loaded
 * from the network if the default cache expiration age is used.
 */
- (void)invalidateURL:(NSString*)URL;

- (void)invalidateKey:(NSString*)key;

/**
 * Invalidates all files in the disk cache according to rules explained in `invalidateURL`.
 */
- (void)invalidateAll;

- (void)logMemoryUsage;

@end
