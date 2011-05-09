//
//  RKObjectMappingResult.m
//  RestKit
//
//  Created by Blake Watters on 5/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappingResult.h"


@implementation RKObjectMappingResult

- (id)initWithDictionary:(id)dictionary {
    self = [self init];
    if (self) {
        _keyPathToMappedObjects = [dictionary retain];
    }
    
    return self;
}

- (void)dealloc {
    [_keyPathToMappedObjects release];
    [super dealloc];
}

+ (RKObjectMappingResult*)mappingResultWithDictionary:(NSDictionary*)keyPathToMappedObjects {
    return [[[self alloc] initWithDictionary:keyPathToMappedObjects] autorelease];
}

/*!
 Return the mapping result as a dictionary
 */
- (NSDictionary*)asDictionary {
    return _keyPathToMappedObjects;
}

// TODO: Test me explicitly...
- (NSArray*)asCollection {
    // Flatten results down into a single array
    NSMutableArray* collection = [NSMutableArray array];
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

- (id)asObject {
    // TODO: Warn that only last object was returned...
    return [[self asCollection] objectAtIndex:0];
}

@end
