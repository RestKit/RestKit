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
#import "RKAttributeMapping.h"
#import "RKRelationshipMapping.h"

// Constants
NSString * const RKObjectMappingNestingAttributeKeyName = @"<RK_NESTING_ATTRIBUTE>";

@interface RKObjectMapping ()
@property (nonatomic, weak, readwrite) Class objectClass;
@property (nonatomic, strong) NSMutableArray *mutablePropertyMappings;

@property (weak, nonatomic, readonly) NSArray *mappedKeyPaths;
@end

@implementation RKObjectMapping

@synthesize objectClass = _objectClass;
@synthesize dateFormatters = _dateFormatters;
@synthesize preferredDateFormatter = _preferredDateFormatter;
@synthesize setDefaultValueForMissingAttributes = _setDefaultValueForMissingAttributes;
@synthesize setNilForMissingRelationships = _setNilForMissingRelationships;
@synthesize performKeyValueValidation = _performKeyValueValidation;
@synthesize ignoreUnknownKeyPaths = _ignoreUnknownKeyPaths;

+ (id)mappingForClass:(Class)objectClass
{
    return [[self alloc] initWithClass:objectClass];
}

+ (id)requestMapping
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
        self.ignoreUnknownKeyPaths = NO;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    RKObjectMapping *copy = [[[self class] allocWithZone:zone] init];
    copy.objectClass = self.objectClass;
    copy.setDefaultValueForMissingAttributes = self.setDefaultValueForMissingAttributes;
    copy.setNilForMissingRelationships = self.setNilForMissingRelationships;
    copy.forceCollectionMapping = self.forceCollectionMapping;
    copy.performKeyValueValidation = self.performKeyValueValidation;
    copy.dateFormatters = self.dateFormatters;
    copy.preferredDateFormatter = self.preferredDateFormatter;

    for (RKPropertyMapping *propertyMapping in self.propertyMappings) {
        [copy addPropertyMapping:propertyMapping];
    }

    return copy;
}

- (NSArray *)propertyMappings
{
    return [NSArray arrayWithArray:_mutablePropertyMappings];
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
    [self.mutablePropertyMappings addObject:propertyMapping];
}

- (void)addPropertyMappingsFromArray:(NSArray *)arrayOfPropertyMappings
{
    for (RKPropertyMapping *propertyMapping in arrayOfPropertyMappings) {
        [self addPropertyMapping:propertyMapping];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p objectClass=%@ propertyMappings=%@>",
            NSStringFromClass([self class]), self, NSStringFromClass(self.objectClass), self.propertyMappings];
}

- (id)mappingForKeyPath:(NSString *)keyPath
{
    return [self mappingForSourceKeyPath:keyPath];
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

- (void)addAttributeMappingsFromDictionary:(NSDictionary *)keyPathToAttributeNames
{
    for (NSString *attributeKeyPath in keyPathToAttributeNames) {
        [self addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:attributeKeyPath toKeyPath:[keyPathToAttributeNames objectForKey:attributeKeyPath]]];
    }
}

- (void)addAttributeMappingsFromArray:(NSArray *)arrayOfAttributeNamesOrMappings
{
    for (id entry in arrayOfAttributeNamesOrMappings) {
        if ([entry isKindOfClass:[NSString class]]) {
            [self addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:entry toKeyPath:entry]];
        } else if ([entry isKindOfClass:[RKAttributeMapping class]]) {
            [self addPropertyMapping:entry];
        } else {
            [NSException raise:NSInvalidArgumentException
                        format:@"*** - [%@ %@]: Unable to attribute mapping from unsupported entry of type '%@' (%@).", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromClass([entry class]), entry];
        }
    }
}

- (void)removePropertyMapping:(RKPropertyMapping *)attributeOrRelationshipMapping
{
    [self.mutablePropertyMappings removeObject:attributeOrRelationshipMapping];
}

#ifndef MAX_INVERSE_MAPPING_RECURSION_DEPTH
#define MAX_INVERSE_MAPPING_RECURSION_DEPTH (100)
#endif
//- (RKObjectMapping *)inverseMappingAtDepth:(NSInteger)depth
//{
//    NSAssert(depth < MAX_INVERSE_MAPPING_RECURSION_DEPTH, @"Exceeded max recursion level in inverseMapping. This is likely due to a loop in the serialization graph. To break this loop, specify one-way relationships by setting serialize to NO in mapKeyPath:toRelationship:withObjectMapping:serialize:");
//    RKObjectMapping *inverseMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
//    for (RKAttributeMapping *attributeMapping in self.attributeMappings) {
//        [inverseMapping mapKeyPath:attributeMapping.destinationKeyPath toAttribute:attributeMapping.sourceKeyPath];
//    }
//
//    for (RKRelationshipMapping *relationshipMapping in self.relationshipMappings) {
//        if (relationshipMapping.reversible) {
//            RKMapping *mapping = relationshipMapping.mapping;
//            if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
//                RKLogWarning(@"Unable to generate inverse mapping for relationship '%@': %@ relationships cannot be inversed.", relationshipMapping.sourceKeyPath, NSStringFromClass([mapping class]));
//                continue;
//            }
//            [inverseMapping mapKeyPath:relationshipMapping.destinationKeyPath toRelationship:relationshipMapping.sourceKeyPath withMapping:[(RKObjectMapping *)mapping inverseMappingAtDepth:depth+1]];
//        }
//    }
//
//    return inverseMapping;
//}
//
//- (RKObjectMapping *)inverseMapping
//{
//    return [self inverseMappingAtDepth:0];
//}

- (void)mapKeyOfNestedDictionaryToAttribute:(NSString *)attributeName
{
    [self addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:RKObjectMappingNestingAttributeKeyName toKeyPath:attributeName]];
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
static NSDateFormatter *preferredDateFormatter = nil;

@implementation RKObjectMapping (DateAndTimeFormatting)

+ (NSArray *)defaultDateFormatters
{
    // TODO: Migrate into load/initialize...
    if (!defaultDateFormatters) {
        defaultDateFormatters = [[NSMutableArray alloc] initWithCapacity:2];

        // Setup the default formatters
        RKISO8601DateFormatter *isoFormatter = [[RKISO8601DateFormatter alloc] init];
        [self addDefaultDateFormatter:isoFormatter];

        [self addDefaultDateFormatterForString:@"MM/dd/yyyy" inTimeZone:nil];
        [self addDefaultDateFormatterForString:@"yyyy-MM-dd'T'HH:mm:ss'Z'" inTimeZone:nil];
    }

    return defaultDateFormatters;
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
        // A date formatter that matches the output of [NSDate description]
        preferredDateFormatter = [NSDateFormatter new];
        [preferredDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        preferredDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        preferredDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    }

    return preferredDateFormatter;
}

+ (void)setPreferredDateFormatter:(NSDateFormatter *)dateFormatter
{
    preferredDateFormatter = dateFormatter;
}

@end
