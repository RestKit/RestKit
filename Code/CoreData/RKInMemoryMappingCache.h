//
//  RKInMemoryMappingCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKManagedObjectMappingCache.h"
#import "RKInMemoryEntityCache.h"

@interface RKInMemoryMappingCache : NSObject <RKManagedObjectMappingCache>

@property (nonatomic, readonly) RKInMemoryEntityCache *cache;

@end
