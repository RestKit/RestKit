//
//  RKObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"
#import "RKObjectRelationshipMapping.h"
#import "../Support/RKLog.h"

// Constants
NSString* const RKObjectMappingNestingAttributeKeyName = @"<RK_NESTING_ATTRIBUTE>";

@implementation RKObjectMapping

@synthesize objectClass = _objectClass;
@synthesize mappings = _mappings;
@synthesize dateFormatStrings = _dateFormatStrings;
@synthesize rootKeyPath = _rootKeyPath;
@synthesize setDefaultValueForMissingAttributes = _setDefaultValueForMissingAttributes;
@synthesize setNilForMissingRelationships = _setNilForMissingRelationships;
@synthesize forceCollectionMapping = _forceCollectionMapping;
@synthesize performKeyValueValidation = _performKeyValueValidation;

+ (id)mappingForClass:(Class)objectClass {
    RKObjectMapping* mapping = [self new];
    mapping.objectClass = objectClass;    
    return [mapping autorelease];
}

+ (id)serializationMapping {
    return [self mappingForClass:[NSMutableDictionary class]];
}

#if NS_BLOCKS_AVAILABLE

+ (id)mappingForClass:(Class)objectClass block:(void(^)(RKObjectMapping*))block {
    RKObjectMapping* mapping = [self mappingForClass:objectClass];
    block(mapping);
    return mapping;
}

+ (id)serializationMappingWithBlock:(void(^)(RKObjectMapping*))block {
    RKObjectMapping* mapping = [self serializationMapping];
    block(mapping);
    return mapping;
}

#endif // NS_BLOCKS_AVAILABLE

- (id)init {
    self = [super init];
    if (self) {
        _mappings = [NSMutableArray new];
        _dateFormatStrings = [[NSMutableArray alloc] initWithObjects:@"yyyy-MM-dd'T'HH:mm:ss'Z'", @"MM/dd/yyyy", nil];
        self.setDefaultValueForMissingAttributes = NO;
        self.setNilForMissingRelationships = NO;
        self.forceCollectionMapping = NO;
        self.performKeyValueValidation = YES;
    }
    
    return self;
}

- (void)dealloc {
    [_rootKeyPath release];
    [_mappings release];
    [_dateFormatStrings release];
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

- (id)mappingForKeyPath:(NSString*)keyPath {
    for (RKObjectAttributeMapping* mapping in _mappings) {
        if ([mapping.sourceKeyPath isEqualToString:keyPath]) {
            return mapping;
        }
    }
    
    return nil;
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

- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withMapping:(RKObjectAbstractMapping *)objectOrPolymorphicMapping serialize:(BOOL)serialize {
    RKObjectRelationshipMapping* mapping = [RKObjectRelationshipMapping mappingFromKeyPath:relationshipKeyPath toKeyPath:keyPath withMapping:objectOrPolymorphicMapping reversible:serialize];
    [self addRelationshipMapping:mapping];
}

- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping {
    [self mapKeyPath:relationshipKeyPath toRelationship:keyPath withMapping:objectOrPolymorphicMapping serialize:YES];
}

- (void)mapRelationship:(NSString*)relationshipKeyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping {
    [self mapKeyPath:relationshipKeyPath toRelationship:relationshipKeyPath withMapping:objectOrPolymorphicMapping];
}

- (void)mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationKeyPath {
    RKObjectAttributeMapping* mapping = [RKObjectAttributeMapping mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    [self addAttributeMapping:mapping];
}

- (void)hasMany:(NSString*)keyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping {
    [self mapRelationship:keyPath withMapping:objectOrPolymorphicMapping];
}

- (void)hasOne:(NSString*)keyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping {
    [self mapRelationship:keyPath withMapping:objectOrPolymorphicMapping];
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

#ifndef MAX_INVERSE_MAPPING_RECURSION_DEPTH
#define MAX_INVERSE_MAPPING_RECURSION_DEPTH (100)
#endif
- (RKObjectMapping*)inverseMappingAtDepth:(NSInteger)depth {
    NSAssert(depth < MAX_INVERSE_MAPPING_RECURSION_DEPTH, @"Exceeded max recursion level in inverseMapping. This is likely due to a loop in the serialization graph. To break this loop, specify one-way relationships by setting serialize to NO in mapKeyPath:toRelationship:withObjectMapping:serialize:");
    RKObjectMapping* inverseMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    for (RKObjectAttributeMapping* attributeMapping in self.attributeMappings) {
        [inverseMapping mapKeyPath:attributeMapping.destinationKeyPath toAttribute:attributeMapping.sourceKeyPath];
    }
    
    for (RKObjectRelationshipMapping* relationshipMapping in self.relationshipMappings) {
        if (relationshipMapping.reversible) {
            RKObjectAbstractMapping* mapping = relationshipMapping.mapping;
            if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
                RKLogWarning(@"Unable to generate inverse mapping for relationship '%@': %@ relationships cannot be inversed.", relationshipMapping.sourceKeyPath, NSStringFromClass([mapping class]));
                continue;
            }
            [inverseMapping mapKeyPath:relationshipMapping.destinationKeyPath toRelationship:relationshipMapping.sourceKeyPath withMapping:[(RKObjectMapping*)mapping inverseMappingAtDepth:depth+1]];
        }
    }
    
    return inverseMapping;
}

- (RKObjectMapping*)inverseMapping {
    return [self inverseMappingAtDepth:0];
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

- (void)mapKeyOfNestedDictionaryToAttribute:(NSString*)attributeName {    
    [self mapKeyPath:RKObjectMappingNestingAttributeKeyName toAttribute:attributeName];
}

- (RKObjectAttributeMapping*)mappingForAttribute:(NSString*)attributeKey {
    for (RKObjectAttributeMapping* mapping in [self attributeMappings]) {
        if ([mapping.destinationKeyPath isEqualToString:attributeKey]) {
            return mapping;
        }
    }
    
    return nil;
}

- (RKObjectRelationshipMapping*)mappingForRelationship:(NSString*)relationshipKey {
    for (RKObjectRelationshipMapping* mapping in [self relationshipMappings]) {
        if ([mapping.destinationKeyPath isEqualToString:relationshipKey]) {
            return mapping;
        }
    }
    
    return nil;
}

- (id)defaultValueForMissingAttribute:(NSString*)attributeName {
    return nil;
}

- (id)mappableObjectForData:(id)mappableData {
    return [[self.objectClass new] autorelease];
}

@end
