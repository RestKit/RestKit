//
//  RKStaticObjectMappingProvider.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappingProvider.h"

@implementation RKObjectMappingProvider

- (id)init {
    if ((self = [super init])) {
        _mappings = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [_mappings release];
    [super dealloc];
}

- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath {
    return [_mappings objectForKey:keyPath];
}

- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    [_mappings setValue:mapping forKey:keyPath];
}

- (NSDictionary*)objectMappingsByKeyPath {
    return _mappings;
}

@end
