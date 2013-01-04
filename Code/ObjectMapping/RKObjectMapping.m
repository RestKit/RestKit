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
#import "RKObjectMapping.h"
#import "RKRelationshipMapping.h"
#import "RKPropertyInspector.h"
#import "RKLog.h"
#import "RKISO8601DateFormatter.h"
#import "RKAttributeMapping.h"
#import "RKRelationshipMapping.h"

typedef NSString * (^RKSourceToDesinationKeyTransformationBlock)(RKObjectMapping *, NSString *sourceKey);

// Constants
NSString * const RKObjectMappingNestingAttributeKeyName = @"<RK_NESTING_ATTRIBUTE>";

// Private declaration
NSDate *RKDateFromStringWithFormatters(NSString *dateString, NSArray *formatters);

static RKSourceToDesinationKeyTransformationBlock defaultSourceToDestinationKeyTransformationBlock = nil;

@interface RKObjectMapping (Copying)
- (void)copyPropertiesFromMapping:(RKObjectMapping *)mapping;
@end

@interface RKMappingInverter : NSObject
@property (nonatomic, strong) RKObjectMapping *mapping;
@property (nonatomic, strong) NSMutableDictionary *invertedMappings;

- (id)initWithMapping:(RKObjectMapping *)mapping;
- (RKObjectMapping *)inverseMapping;
@end

@implementation RKMappingInverter

- (id)initWithMapping:(RKObjectMapping *)mapping
{
    self = [self init];
    if (self) {
        self.mapping = mapping;
        self.invertedMappings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (RKObjectMapping *)invertMapping:(RKObjectMapping *)mapping
{
    // Use an NSValue to obtain a non-copied key into our inversed mappings dictionary
    NSValue *dictionaryKey = [NSValue valueWithNonretainedObject:mapping];
    RKObjectMapping *inverseMapping = [self.invertedMappings objectForKey:dictionaryKey];
    if (inverseMapping) return inverseMapping;
    
    inverseMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [self.invertedMappings setObject:inverseMapping forKey:dictionaryKey];
    [inverseMapping copyPropertiesFromMapping:mapping];
    
    for (RKAttributeMapping *attributeMapping in mapping.attributeMappings) {
        [inverseMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:attributeMapping.destinationKeyPath toKeyPath:attributeMapping.sourceKeyPath]];
    }
    
    for (RKRelationshipMapping *relationshipMapping in mapping.relationshipMappings) {
        RKObjectMapping *mapping = (RKObjectMapping *) relationshipMapping.mapping;
        if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
            RKLogWarning(@"Unable to generate inverse mapping for relationship '%@': %@ relationships cannot be inversed.", relationshipMapping.sourceKeyPath, NSStringFromClass([mapping class]));
            continue;
        }
        RKMapping *inverseRelationshipMapping = [self invertMapping:mapping];
        if (inverseRelationshipMapping) [inverseMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:relationshipMapping.destinationKeyPath toKeyPath:relationshipMapping.sourceKeyPath withMapping:inverseRelationshipMapping]];
    }
    
    return inverseMapping;
}

- (RKObjectMapping *)inverseMapping
{
    return [self invertMapping:self.mapping];
}

@end

@interface RKPropertyMapping ()
@property (nonatomic, weak, readwrite) RKObjectMapping *objectMapping;
@end

@interface RKObjectMapping ()
@property (nonatomic, weak, readwrite) Class objectClass;
@property (nonatomic, strong) NSMutableArray *mutablePropertyMappings;

@property (nonatomic, weak, readonly) NSArray *mappedKeyPaths;
@property (nonatomic, copy) RKSourceToDesinationKeyTransformationBlock sourceToDestinationKeyTransformationBlock;
@end

@implementation RKObjectMapping

+ (instancetype)mappingForClass:(Class)objectClass
{
    return [[self alloc] initWithClass:objectClass];
}

+ (instancetype)requestMapping
{
    return [self mappingForClass:[NSMutableDictionary class]];
}

- (id)initWithClass:(Class)objectClass
{
    self = [super init];
    if (self) {
        self.objectClass = objectClass;
        self.mutablePropertyMappings = [NSMutableArray new];
        self.setDefaultValueForMissingAttributes = NO;
        self.setNilForMissingRelationships = NO;
        self.forceCollectionMapping = NO;
        self.performKeyValueValidation = YES;
        self.sourceToDestinationKeyTransformationBlock = defaultSourceToDestinationKeyTransformationBlock;
    }

    return self;
}

- (void)copyPropertiesFromMapping:(RKObjectMapping *)mapping
{
    self.setDefaultValueForMissingAttributes = mapping.setDefaultValueForMissingAttributes;
    self.setNilForMissingRelationships = mapping.setNilForMissingRelationships;
    self.forceCollectionMapping = mapping.forceCollectionMapping;
    self.performKeyValueValidation = mapping.performKeyValueValidation;
    self.dateFormatters = mapping.dateFormatters;
    self.preferredDateFormatter = mapping.preferredDateFormatter;
    self.sourceToDestinationKeyTransformationBlock = self.sourceToDestinationKeyTransformationBlock;
}

- (id)copyWithZone:(NSZone *)zone
{
    RKObjectMapping *copy = [[[self class] allocWithZone:zone] init];
    copy.objectClass = self.objectClass;
    [copy copyPropertiesFromMapping:self];
    copy.mutablePropertyMappings = [NSMutableArray new];

    for (RKPropertyMapping *propertyMapping in self.propertyMappings) {
        [copy addPropertyMapping:[propertyMapping copy]];
    }

    return copy;
}

+ (void)setDefaultSourceToDestinationKeyTransformationBlock:(RKSourceToDesinationKeyTransformationBlock)block
{
    defaultSourceToDestinationKeyTransformationBlock = block;
}

- (NSArray *)propertyMappings
{
    return [NSArray arrayWithArray:_mutablePropertyMappings];
}

- (NSDictionary *)propertyMappingsBySourceKeyPath
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[self.propertyMappings count]];
    for (RKPropertyMapping *propertyMapping in self.propertyMappings) {
        if (! propertyMapping.sourceKeyPath) continue;
        [dictionary setObject:propertyMapping forKey:propertyMapping.sourceKeyPath];
    }
    
    return dictionary;
}

- (NSDictionary *)propertyMappingsByDestinationKeyPath
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[self.propertyMappings count]];
    for (RKPropertyMapping *propertyMapping in self.propertyMappings) {
        if (! propertyMapping.destinationKeyPath) continue;
        [dictionary setObject:propertyMapping forKey:propertyMapping.destinationKeyPath];
    }
    
    return dictionary;
}

- (NSArray *)mappedKeyPaths
{
    return [self.propertyMappings valueForKey:@"destinationKeyPath"];
}

- (NSArray *)attributeMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in self.propertyMappings) {
        if ([mapping isMemberOfClass:[RKAttributeMapping class]]) {
            [mappings addObject:mapping];
        }
    }

    return mappings;
}

- (NSArray *)relationshipMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in self.propertyMappings) {
        if ([mapping isMemberOfClass:[RKRelationshipMapping class]]) {
            [mappings addObject:mapping];
        }
    }

    return mappings;
}

- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping
{
    NSAssert1([[self mappedKeyPaths] containsObject:propertyMapping.destinationKeyPath] == NO,
              @"Unable to add mapping for keyPath %@, one already exists...", propertyMapping.destinationKeyPath);
    NSAssert(self.mutablePropertyMappings, @"self.mutablePropertyMappings is nil");
    NSAssert(propertyMapping.objectMapping == nil, @"Cannot add a property mapping object that has already been added to another `RKObjectMapping` object. You probably want to obtain a copy of the mapping: `[propertyMapping copy]`");
    propertyMapping.objectMapping = self;
    [self.mutablePropertyMappings addObject:propertyMapping];
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
    for (RKPropertyMapping *mapping in self.propertyMappings) {
        if ([mapping.sourceKeyPath isEqualToString:sourceKeyPath]) {
            return mapping;
        }
    }

    return nil;
}

- (id)mappingForDestinationKeyPath:(NSString *)destinationKeyPath
{
    for (RKPropertyMapping *mapping in self.propertyMappings) {
        if ([mapping.destinationKeyPath isEqualToString:destinationKeyPath]) {
            return mapping;
        }
    }

    return nil;
}

// Evaluate each component individually so that camelization, etc. considers each component individually
- (NSString *)transformSourceKeyPath:(NSString *)keyPath
{
    if (!self.sourceToDestinationKeyTransformationBlock) return keyPath;
    
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
        [self addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:attributeKeyPath toKeyPath:[keyPathToAttributeNames objectForKey:attributeKeyPath]]];
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
    if ([self.mutablePropertyMappings containsObject:attributeOrRelationshipMapping]) {
        attributeOrRelationshipMapping.objectMapping = nil;
        [self.mutablePropertyMappings removeObject:attributeOrRelationshipMapping];
    }
}

- (instancetype)inverseMapping
{
    RKMappingInverter *mappingInverter = [[RKMappingInverter alloc] initWithMapping:self];
    return [mappingInverter inverseMapping];
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
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    Class propertyClass = self.objectClass;
    for (NSString *property in components) {
        propertyClass = [[RKPropertyInspector sharedInspector] classForPropertyNamed:property ofClass:propertyClass isPrimitive:nil];
        if (! propertyClass) break;
    }

    return propertyClass;
}

#pragma mark - Date and Time

- (NSFormatter *)preferredDateFormatter
{
    return _preferredDateFormatter ?: [RKObjectMapping preferredDateFormatter];
}

- (NSArray *)dateFormatters
{
    return _dateFormatters ?: [RKObjectMapping defaultDateFormatters];
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

static NSMutableArray *defaultDateFormatters = nil;
static NSFormatter *preferredDateFormatter = nil;

@implementation RKObjectMapping (DateAndTimeFormatting)

+ (NSArray *)defaultDateFormatters
{
    if (!defaultDateFormatters) [self resetDefaultDateFormatters];

    return defaultDateFormatters;
}

+ (void)resetDefaultDateFormatters
{    
    defaultDateFormatters = [[NSMutableArray alloc] init];
    
    //NSNumberFormatter which creates dates from Unix timestamps
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    [self addDefaultDateFormatter:numberFormatter];
    
    RKISO8601DateFormatter *isoFormatter = [[RKISO8601DateFormatter alloc] init];
    isoFormatter.parsesStrictly = YES;
    [self addDefaultDateFormatter:isoFormatter];
    
    [self addDefaultDateFormatterForString:@"MM/dd/yyyy" inTimeZone:nil];
    [self addDefaultDateFormatterForString:@"yyyy-MM-dd'T'HH:mm:ss'Z'" inTimeZone:nil];
    [self addDefaultDateFormatterForString:@"yyyy-MM-dd" inTimeZone:nil];
}

+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters
{
    defaultDateFormatters = dateFormatters ? [[NSMutableArray alloc] initWithArray:dateFormatters] : [NSMutableArray array];
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
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    if (nilOrTimeZone) {
        dateFormatter.timeZone = nilOrTimeZone;
    } else {
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }

    [self addDefaultDateFormatter:dateFormatter];
}

+ (NSFormatter *)preferredDateFormatter
{
    if (!preferredDateFormatter) {
        RKISO8601DateFormatter *iso8601Formatter = [[RKISO8601DateFormatter alloc] init];
        iso8601Formatter.defaultTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        iso8601Formatter.includeTime = YES;
        preferredDateFormatter = iso8601Formatter;
    }

    return preferredDateFormatter;
}

+ (void)setPreferredDateFormatter:(NSDateFormatter *)dateFormatter
{
    preferredDateFormatter = dateFormatter;
}

@end

#pragma mark - Functions

NSDate *RKDateFromStringWithFormatters(NSString *dateString, NSArray *formatters)
{
    NSDate *date = nil;
    for (NSFormatter *dateFormatter in formatters) {
        BOOL success;
        @synchronized(dateFormatter) {
            if ([dateFormatter isKindOfClass:[NSDateFormatter class]]) {
                RKLogTrace(@"Attempting to parse string '%@' with format string '%@' and time zone '%@'", dateString, [(NSDateFormatter *)dateFormatter dateFormat], [(NSDateFormatter *)dateFormatter timeZone]);
            }
            NSString *errorDescription = nil;
            success = [dateFormatter getObjectValue:&date forString:dateString errorDescription:&errorDescription];
        }

        if (success && date) {
            if ([dateFormatter isKindOfClass:[NSDateFormatter class]]) {
                RKLogTrace(@"Successfully parsed string '%@' with format string '%@' and time zone '%@' and turned into date '%@'",
                           dateString, [(NSDateFormatter *)dateFormatter dateFormat], [(NSDateFormatter *)dateFormatter timeZone], date);
            } else if ([dateFormatter isKindOfClass:[NSNumberFormatter class]]) {
                NSNumber *formattedNumber = (NSNumber *)date;
                date = [NSDate dateWithTimeIntervalSince1970:[formattedNumber doubleValue]];
            }

            break;
        }
    }

    return date;
}

NSDate *RKDateFromString(NSString *dateString)
{
    return RKDateFromStringWithFormatters(dateString, [RKObjectMapping defaultDateFormatters]);
}

NSString *RKStringFromDate(NSDate *date)
{
    return [[RKObjectMapping preferredDateFormatter] stringForObjectValue:date];
}
