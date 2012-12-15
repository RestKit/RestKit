//
//  RKInMemoryManagedObjectCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
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

#import "RKInMemoryManagedObjectCache.h"
#import "RKEntityCache.h"
#import "RKLog.h"
#import "RKEntityByAttributeCache.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

@interface RKInMemoryManagedObjectCache ()
@property (nonatomic, strong, readwrite) RKEntityCache *entityCache;
@end

@implementation RKInMemoryManagedObjectCache

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (self) {
        self.entityCache = [[RKEntityCache alloc] initWithManagedObjectContext:managedObjectContext];
    }

    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke initWithManagedObjectContext: instead.",
                                           NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (NSSet *)managedObjectsWithEntity:(NSEntityDescription *)entity
                      attributeValues:(NSDictionary *)attributeValues
               inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeValues);
    NSParameterAssert(managedObjectContext);
    
    NSArray *attributes = [attributeValues allKeys];
    if (! [self.entityCache isEntity:entity cachedByAttributes:attributes]) {
        RKLogInfo(@"Caching instances of Entity '%@' by attributes '%@'", entity.name, [attributes componentsJoinedByString:@", "]);
        [self.entityCache cacheObjectsForEntity:entity byAttributes:attributes];
        RKEntityByAttributeCache *attributeCache = [self.entityCache attributeCacheForEntity:entity attributes:attributes];
        RKLogTrace(@"Cached %ld objects", (long)[attributeCache count]);
    }
    
    return [self.entityCache objectsForEntity:entity withAttributeValues:attributeValues inContext:managedObjectContext];
}

- (void)didFetchObject:(NSManagedObject *)object
{
    [self.entityCache addObject:object];
}

- (void)didCreateObject:(NSManagedObject *)object
{
    [self.entityCache addObject:object];
}

- (void)didDeleteObject:(NSManagedObject *)object
{
    [self.entityCache removeObject:object];
}

@end
