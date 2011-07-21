//
//  RKObjectMapper_Private.h
//  RestKit
//
//  Created by Blake Watters on 5/9/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

@interface RKObjectMapper (Private) <RKObjectFactory>

- (id)mapObject:(id)mappableObject atKeyPath:keyPath usingMapping:(RKObjectMapping*)mapping;
- (NSArray*)mapCollection:(NSArray*)mappableObjects atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)mapping;
- (BOOL)mapFromObject:(id)mappableObject toObject:(id)destinationObject atKeyPath:keyPath usingMapping:(RKObjectMapping*)mapping;

@end
