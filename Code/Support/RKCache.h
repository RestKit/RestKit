//
//  RKCache.h
//  RestKit
//
//  Created by Jeff Arena on 8/26/11.
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

@interface RKCache : NSObject {
    NSString *_cachePath;
    NSRecursiveLock *_cacheLock;
}

@property (nonatomic, readonly) NSString *cachePath;

- (id)initWithPath:(NSString *)cachePath subDirectories:(NSArray *)subDirectories;
- (BOOL)hasEntry:(NSString *)cacheKey;
- (void)invalidateEntry:(NSString *)cacheKey;
- (void)invalidateSubDirectory:(NSString *)subDirectory;
- (void)invalidateAll;
- (void)writeDictionary:(NSDictionary *)dictionary withCacheKey:(NSString *)cacheKey;
- (void)writeData:(NSData *)data withCacheKey:(NSString *)cacheKey;
- (NSDictionary *)dictionaryForCacheKey:(NSString *)cacheKey ;
- (NSData *)dataForCacheKey:(NSString *)cacheKey;

@end
