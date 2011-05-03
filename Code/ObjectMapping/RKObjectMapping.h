//
//  RKObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"

// Defines the mapping rules for a given target class
@interface RKObjectMapping : NSObject {
    Class _objectClass;
    NSMutableArray* _mappings;
}

@property (nonatomic, assign) Class objectClass;
@property (nonatomic, readonly) NSArray* mappings;

+ (RKObjectMapping*)mappingForClass:(Class)objectClass;
- (void)addAttributeMapping:(RKObjectAttributeMapping*)mapping;
- (RKObjectAttributeMapping*)mappingForKeyPath:(NSString*)keyPath;

- (NSArray*)mappedKeyPaths;
// TODO: mappedAttributes: mappedRelationships???

@end
