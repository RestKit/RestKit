//
//  RKMappingResult.m
//  RestKit
//
//  Created by Blake Watters on 5/7/11.
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

#import "RKMappingResult.h"
#import "RKMappingErrors.h"
#import "RKLog.h"

@interface RKMappingResult ()
@property (nonatomic, retain) NSDictionary *keyPathToMappedObjects;
@end

@implementation RKMappingResult

@synthesize keyPathToMappedObjects = _keyPathToMappedObjects;

- (id)initWithDictionary:(id)dictionary
{
    self = [self init];
    if (self) {
        self.keyPathToMappedObjects = dictionary;
    }

    return self;
}

- (void)dealloc
{
    self.keyPathToMappedObjects = nil;
    [super dealloc];
}

+ (RKMappingResult *)mappingResultWithDictionary:(NSDictionary *)keyPathToMappedObjects
{
    return [[[self alloc] initWithDictionary:keyPathToMappedObjects] autorelease];
}

- (NSDictionary *)asDictionary
{
    return _keyPathToMappedObjects;
}

- (NSArray *)asCollection
{
    // Flatten results down into a single array
    NSMutableArray *collection = [NSMutableArray array];
    for (id object in [_keyPathToMappedObjects allValues]) {
        // We don't want to strip the keys off of a mapped dictionary result

        if (NO == [object isKindOfClass:[NSDictionary class]] && [object respondsToSelector:@selector(allObjects)]) {
            [collection addObjectsFromArray:[object allObjects]];
        } else {
            [collection addObject:object];
        }
    }

    return collection;
}

- (id)asObject
{
    NSArray *collection = [self asCollection];
    NSUInteger count = [collection count];
    if (count == 0) {
        return nil;
    }

    if (count > 1) RKLogWarning(@"Coerced object mapping result containing %lu objects into singular result.", (unsigned long)count);
    return [collection objectAtIndex:0];
}

- (NSError *)asError
{
    NSArray *collection = [self asCollection];
    NSString *description = nil;
    if ([collection count] > 0) {
        description = [[collection valueForKeyPath:@"description"] componentsJoinedByString:@", "];
    } else {
        RKLogWarning(@"Expected mapping result to contain at least one object to construct an error");
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:collection, RKObjectMapperErrorObjectsKey,
                              description, NSLocalizedDescriptionKey, nil];

    NSError *error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorFromMappingResult userInfo:userInfo];
    return error;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, results=%@>", NSStringFromClass([self class]), self, self.keyPathToMappedObjects];
}

@end
