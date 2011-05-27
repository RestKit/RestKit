//
//  RKObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"
#import "RKObjectRelationshipMapping.h"

@implementation RKObjectMapping

@synthesize objectClass = _objectClass;
@synthesize mappings = _mappings;
@synthesize dateFormatStrings = _dateFormatStrings;
@synthesize rootKeyPath = _rootKeyPath;

+ (RKObjectMapping*)mappingForClass:(Class)objectClass {
    RKObjectMapping* mapping = [RKObjectMapping new];
    mapping.objectClass = objectClass;    
    return [mapping autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _mappings = [NSMutableArray new];
        _dateFormatStrings = [[NSMutableArray alloc] initWithObjects:@"yyyy-MM-dd'T'HH:mm:ss'Z'", @"MM/dd/yyyy", nil];
    }
    
    return self;
}

- (void)dealloc {
    [_mappings release];
    [super dealloc];
}

- (NSArray*)mappedKeyPaths {
    return [_mappings valueForKey:@"destinationKeyPath"];
}

- (NSArray*)attributeMappings {
    NSMutableArray* mappings = [NSMutableArray array];
    for (RKObjectAttributeMapping* mapping in self.mappings) {
        if ([mapping isMemberOfClass:[RKObjectAttributeMapping class]]) {
            [mappings addObject:mapping];
        }
    }
    
    return mappings;
}

- (NSArray*)relationshipMappings {
    NSMutableArray* mappings = [NSMutableArray array];
    for (RKObjectAttributeMapping* mapping in self.mappings) {
        if ([mapping isMemberOfClass:[RKObjectRelationshipMapping class]]) {
            [mappings addObject:mapping];
        }
    }
    
    return mappings;
}

- (void)addAttributeMapping:(RKObjectAttributeMapping*)mapping {
    NSAssert1([[self mappedKeyPaths] containsObject:mapping.destinationKeyPath] == NO, @"Unable to add mapping for keyPath %@, one already exists...", mapping.destinationKeyPath);
    [_mappings addObject:mapping];
}

- (void)addRelationshipMapping:(RKObjectRelationshipMapping*)mapping {
    [self addAttributeMapping:mapping];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMapping class => %@: keyPath mappings => %@", NSStringFromClass(self.objectClass), _mappings];
}

- (RKObjectAttributeMapping*)mappingForKeyPath:(NSString*)keyPath {
    for (RKObjectAttributeMapping* mapping in _mappings) {
        if ([mapping.sourceKeyPath isEqualToString:keyPath]) {
            return mapping;
        }
    }
    
    return nil;
}

// TODO: This is a stub. Need to figure out where the real behavior lives...
- (BOOL)shouldSetNilForMissingAttributes {
    return YES;
}

- (BOOL)shouldSetNilForMissingRelationships {
    return YES;
}

- (void)mapAttributesSet:(NSSet*)attributes {
    for (NSString* attributeKeyPath in attributes) {
        [self addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:attributeKeyPath toKeyPath:attributeKeyPath]];
    }
}

- (void)mapAttributes:(NSString*)attributeKeyPath, ... {
    va_list args;
    va_start(args, attributeKeyPath);
	NSMutableSet* attributeKeyPaths = [NSMutableSet set];
                                       
    for (NSString* keyPath = attributeKeyPath; keyPath != nil; keyPath = va_arg(args, NSString*)) {
        [attributeKeyPaths addObject:keyPath];
    }
    
    va_end(args);
    
    [self mapAttributesSet:attributeKeyPaths];
}

- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withObjectMapping:(RKObjectMapping *)objectMapping {
    RKObjectRelationshipMapping* mapping = [RKObjectRelationshipMapping mappingFromKeyPath:relationshipKeyPath toKeyPath:keyPath objectMapping:objectMapping];
    [self addRelationshipMapping:mapping];
}

- (void)mapRelationship:(NSString*)relationshipKeyPath withObjectMapping:(RKObjectMapping*)objectMapping {
    [self mapKeyPath:relationshipKeyPath toRelationship:relationshipKeyPath withObjectMapping:objectMapping];
}

- (void)mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationKeyPath {
    RKObjectAttributeMapping* mapping = [RKObjectAttributeMapping mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    [self addAttributeMapping:mapping];
}

- (void)hasMany:(NSString*)keyPath withMapping:(RKObjectMapping*)objectMapping {
    [self mapRelationship:keyPath withObjectMapping:objectMapping];
}

- (void)belongsTo:(NSString*)keyPath withMapping:(RKObjectMapping*)mapping {
    [self mapRelationship:keyPath withObjectMapping:mapping];
}

- (void)removeAllMappings {
    [_mappings removeAllObjects];
}

- (void)removeMapping:(RKObjectAttributeMapping*)attributeOrRelationshipMapping {
    [_mappings removeObject:attributeOrRelationshipMapping];
}

- (void)removeMappingForKeyPath:(NSString*)keyPath {
    RKObjectAttributeMapping* mapping = [self mappingForKeyPath:keyPath];
    [self removeMapping:mapping];
}

- (RKObjectMapping*)inverseMapping {
    RKObjectMapping* inverseMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    for (RKObjectAttributeMapping* attributeMapping in self.attributeMappings) {
        [inverseMapping mapKeyPath:attributeMapping.destinationKeyPath toAttribute:attributeMapping.sourceKeyPath];
    }
    
    for (RKObjectRelationshipMapping* relationshipMapping in self.relationshipMappings) {
        [inverseMapping mapKeyPath:relationshipMapping.destinationKeyPath toRelationship:relationshipMapping.sourceKeyPath withObjectMapping:[relationshipMapping.objectMapping inverseMapping]];
    }
    
    return inverseMapping;
}

- (void)mapKeyPathsToAttributes:(NSString*)firstKeyPath, ... {
    va_list args;
    va_start(args, firstKeyPath);
    for (NSString* keyPath = firstKeyPath; keyPath != nil; keyPath = va_arg(args, NSString*)) {
		NSString* attributeKeyPath = va_arg(args, NSString*);
        NSAssert(attributeKeyPath != nil, @"Cannot map a keyPath without a destination attribute keyPath");
        [self mapKeyPath:keyPath toAttribute:attributeKeyPath];
        // TODO: Raise proper exception here, argument error...
    }
    va_end(args);
}

@end
