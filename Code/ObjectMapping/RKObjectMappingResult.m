//
//  RKObjectMappingResult.m
//  RestKit
//
//  Created by Blake Watters on 5/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappingResult.h"
#import "RKObjectMapperError.h"
#import "../Support/RKLog.h"

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

- (NSDictionary*)asDictionary {
    return _keyPathToMappedObjects;
}

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
    NSArray* collection = [self asCollection];
    NSUInteger count = [collection count];
    if (count == 0) {
        return nil;
    }
    
    if (count > 1) RKLogWarning(@"Coerced object mapping result containing %d objects into singular result.", count);
    return [collection objectAtIndex:0];
}

- (NSError*)asError {
    NSArray* collection = [self asCollection];
    NSString* description = nil;
    if ([collection count] > 0) {
        description = [[collection valueForKeyPath:@"description"] componentsJoinedByString:@", "];
    } else {
        RKLogWarning(@"Expected mapping result to contain at least one object to construct an error");
    }
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:collection, RKObjectMapperErrorObjectsKey,
                              description, NSLocalizedDescriptionKey, nil];
    
    NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorFromMappingResult userInfo:userInfo];
    return error;
}

@end
