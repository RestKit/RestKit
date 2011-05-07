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

- (id)asCollection {
    return [_keyPathToMappedObjects allValues];
}

- (id)asObject {
    // TODO: Warn that only last object was returned...
    return [[self asCollection] lastObject];
}

@end
