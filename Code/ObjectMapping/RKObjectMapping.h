//
//  RKObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"

@class RKObjectRelationshipMapping;

// Defines the mapping rules for a given target class
@interface RKObjectMapping : NSObject {
    Class _objectClass;
    NSMutableArray* _mappings;
}

@property (nonatomic, assign) Class objectClass;
@property (nonatomic, readonly) NSArray* mappings;
@property (nonatomic, readonly) NSArray* attributeMappings;
@property (nonatomic, readonly) NSArray* relationshipMappings;
@property (nonatomic, readonly) NSArray* mappedKeyPaths;

+ (RKObjectMapping*)mappingForClass:(Class)objectClass;
- (void)addAttributeMapping:(RKObjectAttributeMapping*)mapping;
- (void)addRelationshipMapping:(RKObjectRelationshipMapping*)mapping;

- (RKObjectAttributeMapping*)mappingForKeyPath:(NSString*)keyPath;

// TODO: Probably become properties...
- (BOOL)shouldSetNilForMissingAttributes;
- (BOOL)shouldSetNilForMissingRelationships;

@end
