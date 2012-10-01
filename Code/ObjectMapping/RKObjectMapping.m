//
//  RKObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKObjectMapping.h"
#import "RKRelationshipMapping.h"
#import "RKPropertyInspector.h"
#import "RKLog.h"
#import "RKISO8601DateFormatter.h"

// Constants
NSString * const RKObjectMappingNestingAttributeKeyName = @"<RK_NESTING_ATTRIBUTE>";

@interface RKObjectMapping () {
    NSMutableArray *_mappings;
}
@end

@implementation RKObjectMapping

@synthesize objectClass = _objectClass;
@synthesize mappings = _mappings;
@synthesize dateFormatters = _dateFormatters;
@synthesize preferredDateFormatter = _preferredDateFormatter;
@synthesize rootKeyPath = _rootKeyPath;
@synthesize setDefaultValueForMissingAttributes = _setDefaultValueForMissingAttributes;
@synthesize setNilForMissingRelationships = _setNilForMissingRelationships;
@synthesize performKeyValueValidation = _performKeyValueValidation;
@synthesize ignoreUnknownKeyPaths = _ignoreUnknownKeyPaths;

+ (id)mappingForClass:(Class)objectClass
{
    RKObjectMapping *mapping = [self new];
    mapping.objectClass = objectClass;
    return [mapping autorelease];
}

+ (id)mappingForClassWithName:(NSString *)objectClassName
{
    return [self mappingForClass:NSClassFromString(objectClassName)];
}

+ (id)serializationMapping
{
    return [self mappingForClass:[NSMutableDictionary class]];
}

#if NS_BLOCKS_AVAILABLE

+ (id)mappingForClass:(Class)objectClass usingBlock:(void (^)(RKObjectMapping *))block
{
    RKObjectMapping *mapping = [self mappingForClass:objectClass];
    block(mapping);
    return mapping;
}

+ (id)serializationMappingUsingBlock:(void (^)(RKObjectMapping *))block
{
    RKObjectMapping *mapping = [self serializationMapping];
    block(mapping);
    return mapping;
}

// Deprecated... Move to category or bottom...
+ (id)mappingForClass:(Class)objectClass withBlock:(void (^)(RKObjectMapping *))block
{
    return [self mappingForClass:objectClass usingBlock:block];
}

+ (id)mappingForClass:(Class)objectClass block:(void (^)(RKObjectMapping *))block
{
    return [self mappingForClass:objectClass usingBlock:block];
}

+ (id)serializationMappingWithBlock:(void (^)(RKObjectMapping *))block
{
    RKObjectMapping *mapping = [self serializationMapping];
    block(mapping);
    return mapping;
}

#endif // NS_BLOCKS_AVAILABLE

- (id)init
{
    self = [super init];
    if (self) {
        _mappings = [NSMutableArray new];
        self.setDefaultValueForMissingAttributes = NO;
        self.setNilForMissingRelationships = NO;
        self.forceCollectionMapping = NO;
        self.performKeyValueValidation = YES;
        self.ignoreUnknownKeyPaths = NO;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    RKObjectMapping *copy = [[[self class] allocWithZone:zone] init];
    copy.objectClass = self.objectClass;
    copy.rootKeyPath = self.rootKeyPath;
    copy.setDefaultValueForMissingAttributes = self.setDefaultValueForMissingAttributes;
    copy.setNilForMissingRelationships = self.setNilForMissingRelationships;
    copy.forceCollectionMapping = self.forceCollectionMapping;
    copy.performKeyValueValidation = self.performKeyValueValidation;
    copy.dateFormatters = self.dateFormatters;
    copy.preferredDateFormatter = self.preferredDateFormatter;

    for (RKAttributeMapping *mapping in self.mappings) {
        [copy addAttributeMapping:mapping];
    }

    return copy;
}

- (void)dealloc
{
    [_rootKeyPath release];
    [_mappings release];
    [_dateFormatters release];
    [_preferredDateFormatter release];
    [super dealloc];
}

- (NSString *)objectClassName
{
    return NSStringFromClass(self.objectClass);
}

- (void)setObjectClassName:(NSString *)objectClassName
{
    self.objectClass = NSClassFromString(objectClassName);
}

- (NSArray *)mappedKeyPaths
{
    return [_mappings valueForKey:@"destinationKeyPath"];
}

- (NSArray *)attributeMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in self.mappings) {
        if ([mapping isMemberOfClass:[RKAttributeMapping class]]) {
            [mappings addObject:mapping];
        }
    }

    return mappings;
}

- (NSArray *)relationshipMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in self.mappings) {
        if ([mapping isMemberOfClass:[RKRelationshipMapping class]]) {
            [mappings addObject:mapping];
        }
    }

    return mappings;
}

- (void)addAttributeMapping:(RKAttributeMapping *)mapping
{
    NSAssert1([[self mappedKeyPaths] containsObject:mapping.destinationKeyPath] == NO, @"Unable to add mapping for keyPath %@, one already exists...", mapping.destinationKeyPath);
    [_mappings addObject:mapping];
}

- (void)addRelationshipMapping:(RKRelationshipMapping *)mapping
{
    [self addAttributeMapping:mapping];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p objectClass=%@ keyPath mappings => %@>", NSStringFromClass([self class]), self, NSStringFromClass(self.objectClass), _mappings];
}

- (id)mappingForKeyPath:(NSString *)keyPath
{
    return [self mappingForSourceKeyPath:keyPath];
}

- (id)mappingForSourceKeyPath:(NSString *)sourceKeyPath
{
    for (RKAttributeMapping *mapping in _mappings) {
        if ([mapping.sourceKeyPath isEqualToString:sourceKeyPath]) {
            return mapping;
        }
    }

    return nil;
}

- (id)mappingForDestinationKeyPath:(NSString *)destinationKeyPath
{
    for (RKAttributeMapping *mapping in _mappings) {
        if ([mapping.destinationKeyPath isEqualToString:destinationKeyPath]) {
            return mapping;
        }
    }

    return nil;
}

- (void)mapAttributesCollection:(id<NSFastEnumeration>)attributes
{
    for (NSString *attributeKeyPath in attributes) {
        [self addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:attributeKeyPath toKeyPath:attributeKeyPath]];
    }
}

- (void)mapAttributes:(NSString *)attributeKeyPath, ...
{
    va_list args;
    va_start(args, attributeKeyPath);
    NSMutableSet *attributeKeyPaths = [NSMutableSet set];

    for (NSString *keyPath = attributeKeyPath; keyPath != nil; keyPath = va_arg(args, NSString *)) {
        [attributeKeyPaths addObject:keyPath];
    }

    va_end(args);

    [self mapAttributesCollection:attributeKeyPaths];
}

- (void)addAttributeMappingsFromDictionary:(NSDictionary *)keyPathToAttributeNames
{
    for (NSString *attributeKeyPath in keyPathToAttributeNames) {
        [self addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:attributeKeyPath toKeyPath:[keyPathToAttributeNames objectForKey:attributeKeyPath]]];
    }
}

- (void)mapAttributesFromSet:(NSSet *)set
{
    [self mapAttributesCollection:set];
}

- (void)mapAttributesFromArray:(NSArray *)array
{
    [self mapAttributesCollection:[NSSet setWithArray:array]];
}

- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString *)keyPath withMapping:(RKMapping *)objectOrDynamicMapping serialize:(BOOL)serialize
{
    RKRelationshipMapping *mapping = [RKRelationshipMapping mappingFromKeyPath:relationshipKeyPath toKeyPath:keyPath withMapping:objectOrDynamicMapping reversible:serialize];
    [self addRelationshipMapping:mapping];
}

- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString *)keyPath withMapping:(RKMapping *)objectOrDynamicMapping
{
    [self mapKeyPath:relationshipKeyPath toRelationship:keyPath withMapping:objectOrDynamicMapping serialize:YES];
}

- (void)mapRelationship:(NSString *)relationshipKeyPath withMapping:(RKMapping *)objectOrDynamicMapping
{
    [self mapKeyPath:relationshipKeyPath toRelationship:relationshipKeyPath withMapping:objectOrDynamicMapping];
}

- (void)mapKeyPath:(NSString *)sourceKeyPath toAttribute:(NSString *)destinationKeyPath
{
    RKAttributeMapping *mapping = [RKAttributeMapping mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    [self addAttributeMapping:mapping];
}

- (void)hasMany:(NSString *)keyPath withMapping:(RKMapping *)objectOrDynamicMapping
{
    [self mapRelationship:keyPath withMapping:objectOrDynamicMapping];
}

- (void)hasOne:(NSString *)keyPath withMapping:(RKMapping *)objectOrDynamicMapping
{
    [self mapRelationship:keyPath withMapping:objectOrDynamicMapping];
}

- (void)removeAllMappings
{
    [_mappings removeAllObjects];
}

- (void)removeMapping:(RKAttributeMapping *)attributeOrRelationshipMapping
{
    [_mappings removeObject:attributeOrRelationshipMapping];
}

- (void)removeMappingForKeyPath:(NSString *)keyPath
{
    RKAttributeMapping *mapping = [self mappingForKeyPath:keyPath];
    [self removeMapping:mapping];
}

#ifndef MAX_INVERSE_MAPPING_RECURSION_DEPTH
#define MAX_INVERSE_MAPPING_RECURSION_DEPTH (100)
#endif
- (RKObjectMapping *)inverseMappingAtDepth:(NSInteger)depth
{
    NSAssert(depth < MAX_INVERSE_MAPPING_RECURSION_DEPTH, @"Exceeded max recursion level in inverseMapping. This is likely due to a loop in the serialization graph. To break this loop, specify one-way relationships by setting serialize to NO in mapKeyPath:toRelationship:withObjectMapping:serialize:");
    RKObjectMapping *inverseMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    for (RKAttributeMapping *attributeMapping in self.attributeMappings) {
        [inverseMapping mapKeyPath:attributeMapping.destinationKeyPath toAttribute:attributeMapping.sourceKeyPath];
    }

    for (RKRelationshipMapping *relationshipMapping in self.relationshipMappings) {
        if (relationshipMapping.reversible) {
            RKMapping *mapping = relationshipMapping.mapping;
            if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
                RKLogWarning(@"Unable to generate inverse mapping for relationship '%@': %@ relationships cannot be inversed.", relationshipMapping.sourceKeyPath, NSStringFromClass([mapping class]));
                continue;
            }
            [inverseMapping mapKeyPath:relationshipMapping.destinationKeyPath toRelationship:relationshipMapping.sourceKeyPath withMapping:[(RKObjectMapping *)mapping inverseMappingAtDepth:depth+1]];
        }
    }

    return inverseMapping;
}

- (RKObjectMapping *)inverseMapping
{
    return [self inverseMappingAtDepth:0];
}

- (void)mapKeyPathsToAttributes:(NSString *)firstKeyPath, ...
{
    va_list args;
    va_start(args, firstKeyPath);
    for (NSString *keyPath = firstKeyPath; keyPath != nil; keyPath = va_arg(args, NSString *)) {
        NSString *attributeKeyPath = va_arg(args, NSString *);
        NSAssert(attributeKeyPath != nil, @"Cannot map a keyPath without a destination attribute keyPath");
        [self mapKeyPath:keyPath toAttribute:attributeKeyPath];
        // TODO: Raise proper exception here, argument error...
    }
    va_end(args);
}

- (void)mapKeyOfNestedDictionaryToAttribute:(NSString *)attributeName
{
    [self mapKeyPath:RKObjectMappingNestingAttributeKeyName toAttribute:attributeName];
}

- (RKAttributeMapping *)attributeMappingForKeyOfNestedDictionary
{
    return [self mappingForKeyPath:RKObjectMappingNestingAttributeKeyName];
}

- (RKAttributeMapping *)mappingForAttribute:(NSString *)attributeKey
{
    for (RKAttributeMapping *mapping in [self attributeMappings]) {
        if ([mapping.destinationKeyPath isEqualToString:attributeKey]) {
            return mapping;
        }
    }

    return nil;
}

- (RKRelationshipMapping *)mappingForRelationship:(NSString *)relationshipKey
{
    for (RKRelationshipMapping *mapping in [self relationshipMappings]) {
        if ([mapping.destinationKeyPath isEqualToString:relationshipKey]) {
            return mapping;
        }
    }

    return nil;
}

- (id)defaultValueForMissingAttribute:(NSString *)attributeName
{
    return nil;
}

- (Class)classForProperty:(NSString *)propertyName
{
    return [[RKPropertyInspector sharedInspector] typeForProperty:propertyName ofClass:self.objectClass];
}

#pragma mark - Date and Time

- (NSFormatter *)preferredDateFormatter
{
    return _preferredDateFormatter ? _preferredDateFormatter : [RKObjectMapping preferredDateFormatter];
}

- (NSArray *)dateFormatters
{
    return _dateFormatters ? _dateFormatters : [RKObjectMapping defaultDateFormatters];
}

- (BOOL)isEqualToMapping:(RKObjectMapping *)otherMapping
{
    if (! [otherMapping isKindOfClass:[RKObjectMapping class]]) return NO;
    if ((self.objectClass && otherMapping.objectClass) &&
        ! [otherMapping.objectClass isEqual:self.objectClass]) {
        return NO;
    } else if (self.objectClass != nil && otherMapping.objectClass == nil) {
        return NO;
    } else if (self.objectClass == nil && otherMapping.objectClass != nil) {
        return NO;
    }

    // Check that the number of attribute/relationship mappings is equal and compare all
    if ([self.mappings count] != [otherMapping.mappings count]) return NO;

    for (RKAttributeMapping *attributeMapping in self.mappings) {
        RKAttributeMapping *otherAttributeMapping = [otherMapping mappingForSourceKeyPath:attributeMapping.sourceKeyPath];
        if (! [attributeMapping isEqualToMapping:otherAttributeMapping]) return NO;
    }

    return YES;
}

@end

/////////////////////////////////////////////////////////////////////////////

static NSMutableArray *defaultDateFormatters = nil;
static NSDateFormatter *preferredDateFormatter = nil;

@implementation RKObjectMapping (DateAndTimeFormatting)

+ (NSArray *)defaultDateFormatters
{
    if (!defaultDateFormatters) {
        defaultDateFormatters = [[NSMutableArray alloc] initWithCapacity:2];

        // Setup the default formatters
        RKISO8601DateFormatter *isoFormatter = [[RKISO8601DateFormatter alloc] init];
        [self addDefaultDateFormatter:isoFormatter];
        [isoFormatter release];

        [self addDefaultDateFormatterForString:@"MM/dd/yyyy" inTimeZone:nil];
        [self addDefaultDateFormatterForString:@"yyyy-MM-dd'T'HH:mm:ss'Z'" inTimeZone:nil];
    }

    return defaultDateFormatters;
}

+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters
{
    [defaultDateFormatters release];
    defaultDateFormatters = nil;
    if (dateFormatters) {
        defaultDateFormatters = [[NSMutableArray alloc] initWithArray:dateFormatters];
    }
}


+ (void)addDefaultDateFormatter:(id)dateFormatter
{
    [self defaultDateFormatters];
    [defaultDateFormatters insertObject:dateFormatter atIndex:0];
}

+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = dateFormatString;
    dateFormatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    if (nilOrTimeZone) {
        dateFormatter.timeZone = nilOrTimeZone;
    } else {
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }

    [self addDefaultDateFormatter:dateFormatter];
    [dateFormatter release];

}

+ (NSFormatter *)preferredDateFormatter
{
    if (!preferredDateFormatter) {
        // A date formatter that matches the output of [NSDate description]
        preferredDateFormatter = [NSDateFormatter new];
        [preferredDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        preferredDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        preferredDateFormatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    }

    return preferredDateFormatter;
}

+ (void)setPreferredDateFormatter:(NSDateFormatter *)dateFormatter
{
    [dateFormatter retain];
    [preferredDateFormatter release];
    preferredDateFormatter = dateFormatter;
}

@end
