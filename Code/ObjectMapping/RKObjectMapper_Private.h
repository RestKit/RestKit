//
//  RKObjectMapper_Private.h
//  RestKit
//
//  Created by Blake Watters on 5/9/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

@interface RKObjectMapper (Private)

- (id)mapObject:(id)mappableObject atKeyPath:keyPath usingMapping:(id<RKObjectMappingDefinition>)mapping;
- (NSArray*)mapCollection:(NSArray*)mappableObjects atKeyPath:(NSString*)keyPath usingMapping:(id<RKObjectMappingDefinition>)mapping;
- (BOOL)mapFromObject:(id)mappableObject toObject:(id)destinationObject atKeyPath:keyPath usingMapping:(id<RKObjectMappingDefinition>)mapping;
- (id)objectWithMapping:(id<RKObjectMappingDefinition>)objectMapping andData:(id)mappableData;

@end
