//
//  RKObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"
#import "RKObjectRelationshipMapping.h"

// Defines the mapping rules for a given target class
@interface RKObjectMapping : NSObject {
    Class _objectClass;
    NSMutableArray* _mappings;
    NSMutableArray* _dateFormatStrings;
}

@property (nonatomic, assign) Class objectClass;
@property (nonatomic, readonly) NSArray* mappings;
@property (nonatomic, readonly) NSArray* attributeMappings;
@property (nonatomic, readonly) NSArray* relationshipMappings;
@property (nonatomic, readonly) NSArray* mappedKeyPaths;

/*!
 An array of date format strings to apply when mapping a
 String attribute to a NSDate property
 */
@property (nonatomic, retain) NSMutableArray* dateFormatStrings;

+ (RKObjectMapping*)mappingForClass:(Class)objectClass;
- (void)addAttributeMapping:(RKObjectAttributeMapping*)mapping;
- (void)addRelationshipMapping:(RKObjectRelationshipMapping*)mapping;

- (RKObjectAttributeMapping*)mappingForKeyPath:(NSString*)keyPath;

// TODO: Probably become properties...
- (BOOL)shouldSetNilForMissingAttributes;
- (BOOL)shouldSetNilForMissingRelationships;

@end
