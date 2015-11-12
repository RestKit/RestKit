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

#import <CoreFoundation/CoreFoundation.h>
#import <ISO8601DateFormatterValueTransformer/ISO8601DateFormatterValueTransformer.h>
#import <RKValueTransformers/RKValueTransformers.h>
#import <RestKit/ObjectMapping/RKAttributeMapping.h>
#import <RestKit/ObjectMapping/RKObjectMapping.h>
#import <RestKit/ObjectMapping/RKPropertyInspector.h>
#import <RestKit/ObjectMapping/RKRelationshipMapping.h>
#import <RestKit/Support/RKLog.h>

typedef NSString * (^RKSourceToDesinationKeyTransformationBlock)(RKObjectMapping *, NSString *);

// Constants
NSString * const RKObjectMappingNestingAttributeKeyName = @"<RK_NESTING_ATTRIBUTE>";

static RKSourceToDesinationKeyTransformationBlock defaultSourceToDestinationKeyTransformationBlock = nil;

@interface RKObjectMapping (Copying)
- (void)copyPropertiesFromMapping:(RKObjectMapping *)mapping;
@end

@interface RKMappingInverter : NSObject
@property (nonatomic, strong) RKObjectMapping *mapping;
@property (nonatomic, strong) NSMutableDictionary *invertedMappings;

- (instancetype)initWithMapping:(RKObjectMapping *)mapping;
- (RKObjectMapping *)inverseMappingWithPredicate:(BOOL (^)(RKPropertyMapping *propertyMapping))predicate;
@end

@implementation RKMappingInverter

- (instancetype)initWithMapping:(RKObjectMapping *)mapping
{
    self = [self init];
    if (self) {
        self.mapping = mapping;
        self.invertedMappings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (RKObjectMapping *)invertMapping:(RKObjectMapping *)mapping withPredicate:(BOOL (^)(RKPropertyMapping *propertyMapping))predicate
{
    // Use an NSValue to obtain a non-copied key into our inversed mappings dictionary
    NSValue *dictionaryKey = [NSValue valueWithNonretainedObject:mapping];
    RKObjectMapping *inverseMapping = (self.invertedMappings)[dictionaryKey];
    if (inverseMapping) return inverseMapping;
    
    inverseMapping = [RKObjectMapping requestMapping];
    (self.invertedMappings)[dictionaryKey] = inverseMapping;
    [inverseMapping copyPropertiesFromMapping:mapping];
    // We want to serialize `nil` values
    inverseMapping.assignsDefaultValueForMissingAttributes = YES;
    
    for (RKAttributeMapping *attributeMapping in mapping.attributeMappings) {
        if (predicate && !predicate(attributeMapping)) continue;
        [inverseMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:attributeMapping.destinationKeyPath toKeyPath:attributeMapping.sourceKeyPath]];
    }
    
    for (RKRelationshipMapping *relationshipMapping in mapping.relationshipMappings) {
        RKObjectMapping *mapping = (RKObjectMapping *) relationshipMapping.mapping;
        if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
            RKLogWarning(@"Unable to generate inverse mapping for relationship '%@': %@ relationships cannot be inversed.", relationshipMapping.sourceKeyPath, NSStringFromClass([mapping class]));
            continue;
        }
        if (predicate && !predicate(relationshipMapping)) continue;
        RKMapping *inverseRelationshipMapping = [self invertMapping:mapping withPredicate:predicate];
        if (inverseRelationshipMapping) [inverseMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:relationshipMapping.destinationKeyPath toKeyPath:relationshipMapping.sourceKeyPath withMapping:inverseRelationshipMapping]];
    }
    
    return inverseMapping;
}

- (RKObjectMapping *)inverseMappingWithPredicate:(BOOL (^)(RKPropertyMapping *propertyMapping))predicate
{
    return [self invertMapping:self.mapping withPredicate:predicate];
}

@end

@interface RKPropertyMapping ()
@property (nonatomic, weak, readwrite) RKObjectMapping *objectMapping;
@end

@interface RKObjectMapping ()
@property (nonatomic, weak, readwrite) Class objectClass;
@property (nonatomic, copy, readwrite) NSArray *propertyMappings;

@property (nonatomic, strong) NSArray *relationshipMappings;
@property (nonatomic, strong) NSArray *attributeMappings;
@property (nonatomic, strong) NSArray *keyAttributeMappings;
@property (nonatomic, strong) NSArray *keyPathAttributeMappings;
@property (nonatomic, strong) NSMutableDictionary *propertiesBySourceKeyPath;
@property (nonatomic, strong) NSMutableDictionary *propertiesByDestinationKeyPath;

@property (nonatomic, weak, readonly) NSArray *mappedKeyPaths;
@property (nonatomic, copy) RKSourceToDesinationKeyTransformationBlock sourceToDestinationKeyTransformationBlock;
@end

@implementation RKObjectMapping

+ (instancetype)mappingForClass:(Class)objectClass
{
    return [[self alloc] initWithClass:objectClass];
}

+ (RKObjectMapping *)requestMapping
{
    if (! [self isEqual:[RKObjectMapping class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"`%@` is not meant to be invoked on `%@`. You probably want to invoke `[RKObjectMapping requestMapping]`.",
                                               NSStringFromSelector(_cmd),
                                               NSStringFromClass(self)]
                                     userInfo:nil];
    }

    // TODO: Hook up value transformers from `RKObjectParameterization`
    RKObjectMapping *objectMapping = [self mappingForClass:[NSMutableDictionary class]];
    objectMapping.assignsDefaultValueForMissingAttributes = YES;
    return objectMapping;
}

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Add an ISO8601DateFormatter to the transformation stack for backwards compatibility
        RKISO8601DateFormatter *dateFormatter = [RKISO8601DateFormatter defaultISO8601DateFormatter];
        [[RKValueTransformer defaultValueTransformer] insertValueTransformer:dateFormatter atIndex:0];
    });
}

- (instancetype)initWithClass:(Class)objectClass
{
    self = [super init];
    if (self) {
        self.objectClass = objectClass;
        self.propertyMappings = [NSArray new];
        self.relationshipMappings = [NSArray new];
        self.attributeMappings = [NSArray new];
        self.keyAttributeMappings = [NSArray new];
        self.keyPathAttributeMappings = [NSArray new];
        self.propertiesBySourceKeyPath = [NSMutableDictionary new];
        self.propertiesByDestinationKeyPath = [NSMutableDictionary new];
        self.assignsDefaultValueForMissingAttributes = NO;
        self.assignsNilForMissingRelationships = NO;
        self.forceCollectionMapping = NO;
        self.performsKeyValueValidation = YES;
        self.sourceToDestinationKeyTransformationBlock = defaultSourceToDestinationKeyTransformationBlock;
        self.valueTransformer = [[RKValueTransformer defaultValueTransformer] copy];
    }

    return self;
}

- (void)copyPropertiesFromMapping:(RKObjectMapping *)mapping
{
    self.assignsDefaultValueForMissingAttributes = mapping.assignsDefaultValueForMissingAttributes;
    self.assignsNilForMissingRelationships = mapping.assignsNilForMissingRelationships;
    self.forceCollectionMapping = mapping.forceCollectionMapping;
    self.performsKeyValueValidation = mapping.performsKeyValueValidation;
    self.valueTransformer = mapping.valueTransformer;
    self.sourceToDestinationKeyTransformationBlock = mapping.sourceToDestinationKeyTransformationBlock;
}

- (id)copyWithZone:(NSZone *)zone
{
    RKObjectMapping *copy = [[[self class] allocWithZone:zone] initWithClass:self.objectClass];
    [copy copyPropertiesFromMapping:self];

    for (RKPropertyMapping *propertyMapping in self.propertyMappings) {
        [copy addPropertyMapping:[propertyMapping copy]];
    }

    return copy;
}

+ (void)setDefaultSourceToDestinationKeyTransformationBlock:(RKSourceToDesinationKeyTransformationBlock)block
{
    defaultSourceToDestinationKeyTransformationBlock = block;
}

- (NSDictionary *)propertyMappingsBySourceKeyPath
{
    return [self.propertiesBySourceKeyPath copy];
}

- (NSDictionary *)propertyMappingsByDestinationKeyPath
{
    return [self.propertiesByDestinationKeyPath copy];
}

- (NSArray *)mappedKeyPaths
{
    return [self.propertyMappings valueForKey:@"destinationKeyPath"];
}

- (NSArray *)attributeMappings
{
    return _attributeMappings;
}

- (NSArray *)relationshipMappings
{
    return _relationshipMappings;
}

- (NSArray *)keyAttributeMappings
{
    return _keyAttributeMappings;
}

- (NSArray *)keyPathAttributeMappings
{
    return _keyPathAttributeMappings;
}

static NSArray *RKAddProperty(NSArray *array, RKPropertyMapping *mapping)
{
    return (array)? [array arrayByAddingObject:mapping] : @[mapping];
}

static NSArray *RKRemoveProperty(NSArray *array, RKPropertyMapping *mapping)
{
    if (![array containsObject:mapping]) return array;
    NSMutableArray *mappings = [[NSMutableArray alloc] initWithArray:array]; //alloc/init avoids autorelease
    [mappings removeObject:mapping];
    return [mappings copy];
}

- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping
{
    NSAssert1([[self mappedKeyPaths] containsObject:propertyMapping.destinationKeyPath] == NO,
              @"Unable to add mapping for keyPath %@, one already exists...", propertyMapping.destinationKeyPath);
    NSAssert(self.propertyMappings, @"self.propertyMappings is nil");
    NSAssert(propertyMapping.objectMapping == nil, @"Cannot add a property mapping object that has already been added to another `RKObjectMapping` object. You probably want to obtain a copy of the mapping: `[propertyMapping copy]`");
    propertyMapping.objectMapping = self;
    self.propertyMappings = [self.propertyMappings arrayByAddingObject:propertyMapping];
    [self.propertiesBySourceKeyPath setObject:propertyMapping forKey:propertyMapping.sourceKeyPath ?: [NSNull null]];
    if (propertyMapping.destinationKeyPath) (self.propertiesByDestinationKeyPath)[propertyMapping.destinationKeyPath] = propertyMapping;
    if ([propertyMapping isMemberOfClass:[RKRelationshipMapping class]]) {
        self.relationshipMappings = RKAddProperty(self.relationshipMappings, propertyMapping);
    }
    else if ([propertyMapping isMemberOfClass:[RKAttributeMapping class]])
    {
        self.attributeMappings = RKAddProperty(self.attributeMappings, propertyMapping);
        if ([propertyMapping.sourceKeyPath rangeOfString:@"." options:NSLiteralSearch].length == 0) {
            self.keyAttributeMappings = RKAddProperty(self.keyAttributeMappings, propertyMapping);
        }
        else {
            self.keyPathAttributeMappings = RKAddProperty(self.keyPathAttributeMappings, propertyMapping);
        }
    }
    
    if (propertyMapping.propertyValueClass == Nil && ![self.objectClass isSubclassOfClass:[NSDictionary class]]) {
        propertyMapping.propertyValueClass = [self classForKeyPath:propertyMapping.destinationKeyPath];
    }
}

- (void)addPropertyMappingsFromArray:(NSArray *)arrayOfPropertyMappings
{
    NSAssert([[arrayOfPropertyMappings valueForKeyPath:@"@distinctUnionOfObjects.objectMapping"] count] == 0, @"One or more of the property mappings in the given array has already been added to another `RKObjectMapping` object. You probably want to obtain a copy of the array of mappings: `[[NSArray alloc] initWithArray:arrayOfPropertyMappings copyItems:YES]`");
    for (RKPropertyMapping *propertyMapping in arrayOfPropertyMappings) {
        [self addPropertyMapping:propertyMapping];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p objectClass=%@ propertyMappings=%@>",
            NSStringFromClass([self class]), self, NSStringFromClass(self.objectClass), self.propertyMappings];
}

- (id)mappingForSourceKeyPath:(NSString *)sourceKeyPath
{
    return _propertiesBySourceKeyPath[sourceKeyPath ?: [NSNull null]];
}

- (id)mappingForDestinationKeyPath:(NSString *)destinationKeyPath
{
    return _propertiesByDestinationKeyPath[destinationKeyPath];
}

// Evaluate each component individually so that camelization, etc. considers each component individually
- (NSString *)transformSourceKeyPath:(NSString *)keyPath
{
    if (!self.sourceToDestinationKeyTransformationBlock) return keyPath;

    NSRange dotRange = [keyPath rangeOfString:@"." options:NSLiteralSearch];
    if (dotRange.length == 0) {
        return self.sourceToDestinationKeyTransformationBlock(self, keyPath);
    }

    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    NSMutableArray *mutableComponents = [NSMutableArray arrayWithCapacity:[components count]];
    [components enumerateObjectsUsingBlock:^(id component, NSUInteger idx, BOOL *stop) {
        [mutableComponents addObject:self.sourceToDestinationKeyTransformationBlock(self, component)];
    }];
    
    return [mutableComponents componentsJoinedByString:@"."];
}

- (void)addAttributeMappingsFromDictionary:(NSDictionary *)keyPathToAttributeNames
{
    for (NSString *attributeKeyPath in keyPathToAttributeNames) {
        [self addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:attributeKeyPath toKeyPath:keyPathToAttributeNames[attributeKeyPath]]];
    }
}

- (void)addAttributeMappingsFromArray:(NSArray *)arrayOfAttributeNamesOrMappings
{
    NSMutableArray *arrayOfAttributeMappings = [NSMutableArray arrayWithCapacity:[arrayOfAttributeNamesOrMappings count]];
    for (id entry in arrayOfAttributeNamesOrMappings) {
        if ([entry isKindOfClass:[NSString class]]) {
            NSString *destinationKeyPath = [self transformSourceKeyPath:entry];
            [arrayOfAttributeMappings addObject:[RKAttributeMapping attributeMappingFromKeyPath:entry toKeyPath:destinationKeyPath]];
        } else if ([entry isKindOfClass:[RKAttributeMapping class]]) {
            [arrayOfAttributeMappings addObject:entry];
        } else {
            [NSException raise:NSInvalidArgumentException
                        format:@"*** - [%@ %@]: Unable to attribute mapping from unsupported entry of type '%@' (%@).", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromClass([entry class]), entry];
        }
    }

    [self addPropertyMappingsFromArray:arrayOfAttributeMappings];
}

- (void)addRelationshipMappingWithSourceKeyPath:(NSString *)sourceKeyPath mapping:(RKMapping *)mapping
{
    NSParameterAssert(sourceKeyPath);
    NSParameterAssert(mapping);
    
    NSString *destinationKeyPath = [self transformSourceKeyPath:sourceKeyPath];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:mapping];
    [self addPropertyMapping:relationshipMapping];
}

- (void)removePropertyMapping:(RKPropertyMapping *)attributeOrRelationshipMapping
{
    if ([self.propertyMappings containsObject:attributeOrRelationshipMapping]) {
        attributeOrRelationshipMapping.objectMapping = nil;
        self.propertyMappings = RKRemoveProperty(self.propertyMappings, attributeOrRelationshipMapping);
        self.relationshipMappings = RKRemoveProperty(self.relationshipMappings, attributeOrRelationshipMapping);
        self.attributeMappings = RKRemoveProperty(self.attributeMappings, attributeOrRelationshipMapping);
        self.keyAttributeMappings = RKRemoveProperty(self.keyAttributeMappings, attributeOrRelationshipMapping);
        self.keyPathAttributeMappings = RKRemoveProperty(self.keyPathAttributeMappings, attributeOrRelationshipMapping);
        [self.propertiesBySourceKeyPath removeObjectForKey:attributeOrRelationshipMapping.sourceKeyPath ?: [NSNull null]];
        [self.propertiesByDestinationKeyPath removeObjectForKey:attributeOrRelationshipMapping.destinationKeyPath ?: [NSNull null]];
    }
}

- (instancetype)inverseMappingWithPropertyMappingsPassingTest:(BOOL (^)(RKPropertyMapping *propertyMapping))predicate
{
    RKMappingInverter *mappingInverter = [[RKMappingInverter alloc] initWithMapping:self];
    return [mappingInverter inverseMappingWithPredicate:predicate];
}

- (instancetype)inverseMapping
{
    return [self inverseMappingWithPropertyMappingsPassingTest:nil];
}

- (void)addAttributeMappingFromKeyOfRepresentationToAttribute:(NSString *)attributeName
{
    [self addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:RKObjectMappingNestingAttributeKeyName toKeyPath:attributeName]];
}

- (void)addAttributeMappingToKeyOfRepresentationFromAttribute:(NSString *)attributeName
{
    [self addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:attributeName toKeyPath:RKObjectMappingNestingAttributeKeyName]];
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

- (id)defaultValueForAttribute:(NSString *)attributeName
{
    return nil;
}

- (Class)classForProperty:(NSString *)propertyName
{
    return [[RKPropertyInspector sharedInspector] classForPropertyNamed:propertyName ofClass:self.objectClass isPrimitive:nil];
}

- (Class)classForKeyPath:(NSString *)keyPath
{
    if (keyPath == nil) return self.objectClass;

    RKPropertyInspector *inspector = [RKPropertyInspector sharedInspector];

    if ([keyPath rangeOfString:@"." options:NSLiteralSearch].length == 0) {
        return [inspector classForPropertyNamed:keyPath ofClass:self.objectClass isPrimitive:nil];
    }

    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    Class propertyClass = self.objectClass;
    for (NSString *property in components) {
        propertyClass = [inspector classForPropertyNamed:property ofClass:propertyClass isPrimitive:nil];
        if (! propertyClass) break;
    }

    return propertyClass;
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
    if ([self.propertyMappings count] != [otherMapping.propertyMappings count]) return NO;

    for (RKPropertyMapping *propertyMapping in self.propertyMappings) {
        RKPropertyMapping *otherPropertyMapping = [otherMapping mappingForSourceKeyPath:propertyMapping.sourceKeyPath];
        if (! [propertyMapping isEqualToMapping:otherPropertyMapping]) return NO;
    }

    return YES;
}

@end

/////////////////////////////////////////////////////////////////////////////

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

@implementation RKObjectMapping (LegacyDateAndTimeFormatting)

+ (NSArray *)defaultDateFormatters
{
    NSArray *valueTransformers = [[RKValueTransformer defaultValueTransformer] valueTransformersForTransformingFromClass:[NSString class] toClass:[NSDate class]];
    NSMutableArray *dateFormatters = [NSMutableArray arrayWithCapacity:[valueTransformers count]];
    for (id<RKValueTransforming> valueTransformer in valueTransformers) {
        if ([valueTransformer respondsToSelector:@selector(dateFromString:)]) [dateFormatters addObject:valueTransformer];
    }
    return dateFormatters;
}

+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters
{
    NSArray *defaultDateFormatters = [self defaultDateFormatters];
    for (NSDateFormatter *dateFormatter in defaultDateFormatters) {
        [[RKValueTransformer defaultValueTransformer] removeValueTransformer:dateFormatter];
    }

    for (NSDateFormatter *dateFormatter in dateFormatters) {
        [[RKValueTransformer defaultValueTransformer] addValueTransformer:dateFormatter];
    }
}

+ (void)addDefaultDateFormatter:(id)dateFormatter
{
    [[RKValueTransformer defaultValueTransformer] insertValueTransformer:dateFormatter atIndex:0];
}

+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = dateFormatString;
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = nilOrTimeZone ?: [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [self addDefaultDateFormatter:dateFormatter];
}

+ (NSFormatter *)preferredDateFormatter
{
    NSArray *defaultDateFormatters = [self defaultDateFormatters];
    return [defaultDateFormatters count] ? defaultDateFormatters[0] : nil;
}

+ (void)setPreferredDateFormatter:(NSDateFormatter *)dateFormatter
{
    [[RKValueTransformer defaultValueTransformer] insertValueTransformer:dateFormatter atIndex:0];
}

#pragma mark - Date and Time

- (NSFormatter *)preferredDateFormatter
{
    if ([self.valueTransformer isKindOfClass:[RKCompoundValueTransformer class]]) {
        NSArray *dateToStringTransformers = [(RKCompoundValueTransformer *)self.valueTransformer valueTransformersForTransformingFromClass:[NSDate class] toClass:[NSString class]];
        for (id<RKValueTransforming> valueTransformer in dateToStringTransformers) {
            if ([valueTransformer isKindOfClass:[NSFormatter class]]) return (NSFormatter *)valueTransformer;
        }
    }
    return nil;
}

- (void)setPreferredDateFormatter:(NSFormatter *)preferredDateFormatter
{
    if ([self.valueTransformer isKindOfClass:[RKCompoundValueTransformer class]]) {
        [(RKCompoundValueTransformer *)self.valueTransformer insertValueTransformer:(NSFormatter<RKValueTransforming> *)preferredDateFormatter atIndex:0];
    }
}

- (NSArray *)dateFormatters
{
    if ([self.valueTransformer isKindOfClass:[RKCompoundValueTransformer class]]) {
        return [(RKCompoundValueTransformer *)self.valueTransformer valueTransformersForTransformingFromClass:[NSDate class] toClass:[NSString class]];
    } else return nil;
}

- (void)setDateFormatters:(NSArray *)dateFormatters
{
    if (! [self.valueTransformer isKindOfClass:[RKCompoundValueTransformer class]]) [NSException raise:NSInternalInconsistencyException format:@"Cannot set date formatters: the receiver's `valueTransformer` is not an instance of `RKCompoundValueTransformer`."];
    for (id<RKValueTransforming> dateFormatter in [self dateFormatters]) {
        [(RKCompoundValueTransformer *)self.valueTransformer removeValueTransformer:dateFormatter];
    }
    for (id<RKValueTransforming> dateFormatter in dateFormatters) {
        [(RKCompoundValueTransformer *)self.valueTransformer addValueTransformer:dateFormatter];
    }
}

@end

@implementation RKObjectMapping (Deprecations)

- (BOOL)shouldSetDefaultValueForMissingAttributes
{
    return self.assignsDefaultValueForMissingAttributes;
}

- (void)setSetDefaultValueForMissingAttributes:(BOOL)setDefaultValueForMissingAttributes
{
    self.assignsDefaultValueForMissingAttributes = setDefaultValueForMissingAttributes;
}

- (BOOL)setNilForMissingRelationships
{
    return self.assignsNilForMissingRelationships;
}

- (void)setSetNilForMissingRelationships:(BOOL)setNilForMissingRelationships
{
    self.assignsNilForMissingRelationships = setNilForMissingRelationships;
}

- (BOOL)performKeyValueValidation
{
    return self.performsKeyValueValidation;
}

- (void)setPerformKeyValueValidation:(BOOL)performKeyValueValidation
{
    self.performsKeyValueValidation = performKeyValueValidation;
}

@end

#pragma clang diagnostic pop

#pragma mark - Functions

NSDate *RKDateFromString(NSString *dateString)
{
    NSDate *outputDate = nil;
    NSError *error = nil;
    BOOL success = [[RKValueTransformer defaultValueTransformer] transformValue:dateString toValue:&outputDate ofClass:[NSDate class] error:&error];
    return success ? outputDate : nil;
}

NSString *RKStringFromDate(NSDate *date)
{
    NSString *outputString = nil;
    NSError *error = nil;
    BOOL success = [[RKValueTransformer defaultValueTransformer] transformValue:date toValue:&outputString ofClass:[NSString class] error:&error];
    return success ? outputString : nil;
}
