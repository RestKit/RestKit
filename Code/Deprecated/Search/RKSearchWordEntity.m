//
//  RKSearchWordEntity.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKSearchWordEntity.h"

NSString * const RKSearchWordEntityName = @"RKSearchWord";
NSString * const RKSearchWordAttributeName = @"word";
NSString * const RKSearchWordsRelationshipName = @"searchWords";

@implementation RKSearchWordEntity

- (id)init
{
    self = [super init];
    if (self) {
        [self setName:RKSearchWordEntityName];
        [self setManagedObjectClassName:RKSearchWordEntityName];
        NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
        [attribute setName:RKSearchWordAttributeName];
        [attribute setIndexed:YES];
        [attribute setAttributeType:NSStringAttributeType];
        [self setProperties:[NSArray arrayWithObject:attribute]];
    }

    return self;
}

@end
