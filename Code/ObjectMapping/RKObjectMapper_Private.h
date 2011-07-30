//
//  RKObjectMapper_Private.h
//  RestKit
//
//  Created by Blake Watters on 5/9/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

@interface RKObjectMapper (Private)

- (id)mapObject:(id)mappableObject atKeyPath:keyPath usingMapping:(RKObjectAbstractMapping*)mapping;
- (NSArray*)mapCollection:(NSArray*)mappableObjects atKeyPath:(NSString*)keyPath usingMapping:(RKObjectAbstractMapping*)mapping;
- (BOOL)mapFromObject:(id)mappableObject toObject:(id)destinationObject atKeyPath:keyPath usingMapping:(RKObjectAbstractMapping*)mapping;
- (id)objectWithMapping:(RKObjectAbstractMapping*)objectMapping andData:(id)mappableData;

@end
