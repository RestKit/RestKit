//
//  RKObjectMappingResult.m
//  RestKit
//
//  Created by Blake Watters on 5/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapper.h" // TODO: Eliminate import once we get the errors in the right place
#import "RKObjectMappingResult.h"
#import "Errors.h"

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

- (NSError*)asError {
    NSArray* collection = [self asCollection];
    // TODO: What is the correct behavior when there is an empty collection we expect to contain an error???
    NSAssert([collection count] > 0, @"Expected mapping result to contain at least one object to construct an error");
    NSString* description = [[collection valueForKeyPath:@"description"] componentsJoinedByString:@", "];
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey,
                              collection, RKObjectMapperErrorObjectsKey, nil];
    
    NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorFromMappingResult userInfo:userInfo];
    return error;
}

@end
