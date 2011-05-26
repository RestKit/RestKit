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
// TODO: Document me!
@interface RKObjectMapping : NSObject {
    Class _objectClass;
    NSMutableArray* _mappings;
    NSMutableArray* _dateFormatStrings;
    NSString* _rootKeyPath;
}

@property (nonatomic, assign) Class objectClass;
@property (nonatomic, readonly) NSArray* mappings;
@property (nonatomic, readonly) NSArray* attributeMappings;
@property (nonatomic, readonly) NSArray* relationshipMappings;
@property (nonatomic, readonly) NSArray* mappedKeyPaths;
@property (nonatomic, retain) NSString* rootKeyPath;

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

- (void)mapAttributes:(NSString*)attributeKeyPath, ...;
- (void)mapRelationship:(NSString*)relationshipKeyPath withObjectMapping:(RKObjectMapping*)objectMapping;

- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withObjectMapping:(RKObjectMapping *)objectMapping;
- (void)mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationKeyPath;

- (void)hasMany:(NSString*)keyPath withMapping:(RKObjectMapping*)mapping;
- (void)belongsTo:(NSString*)keyPath withMapping:(RKObjectMapping*)mapping;
- (void)removeAllMappings;
- (void)removeMapping:(RKObjectAttributeMapping*)attributeOrRelationshipMapping;
- (void)removeMappingForKeyPath:(NSString*)keyPath;
- (RKObjectMapping*)inverseMapping;

- (void)mapKeyPathsAndAttributes:(NSString*)keyPath, ...;

@end
