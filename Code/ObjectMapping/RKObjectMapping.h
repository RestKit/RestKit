//
//  RKObjectMapping.h
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

#import "RKMacros.h"
#import "RKMapping.h"

@class RKPropertyMapping, RKAttributeMapping, RKRelationshipMapping;

/**
 An object mapping defines the rules for transforming a key-value coding
 compliant object into another representation. The mapping is defined in terms
 of a source object class and a collection of rules defining how keyPaths should
 be transformed into target attributes and relationships.

 There are two types of transformations possible:

 1. keyPath to attribute. Defines that the value found at the keyPath should be
transformed and assigned to the property specified by the attribute. The transformation
to be performed is determined by inspecting the type of the target property at runtime.
 1. keyPath to relationship. Defines that the value found at the keyPath should be
transformed into another object instance and assigned to the property specified by the
relationship. Relationships are processed using an object mapping as well.

 Through the use of relationship mappings, an arbitrarily complex object graph can be mapped for you.

 Instances of RKObjectMapping are used to configure RKObjectMappingOperation instances, which actually
 perform the mapping work. Both object loading and serialization are defined in terms of object mappings.
 */
@interface RKObjectMapping : RKMapping <NSCopying>

/**
 The target class this object mapping is defining rules for
 */
@property (nonatomic, assign, readonly) Class objectClass;

/**
 The aggregate collection of attribute and relationship mappings within this object mapping
 */
@property (nonatomic, strong, readonly) NSArray *propertyMappings;

/**
 The collection of attribute mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *attributeMappings;

/**
 The collection of relationship mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *relationshipMappings;

/**
 When YES, any attributes that have mappings defined but are not present within the source
 object will be set to nil, clearing any existing value.
 */
@property (nonatomic, assign, getter = shouldSetDefaultValueForMissingAttributes) BOOL setDefaultValueForMissingAttributes;

/**
 When YES, any relationships that have mappings defined but are not present within the source
 object will be set to nil, clearing any existing value.
 */
@property (nonatomic, assign) BOOL setNilForMissingRelationships;

/**
 When YES, RestKit will invoke key-value validation at object mapping time.

 **Default**: YES
 @see validateValue:forKey:error:
 */
@property (nonatomic, assign) BOOL performKeyValueValidation;

/**
 When YES, RestKit will check that the object being mapped is key-value coding
 compliant for the mapped key. If it is not, the attribute/relationship mapping will
 be ignored and mapping will continue. When NO, unknown keyPath mappings will generate
 NSUnknownKeyException errors for the unknown keyPath.

 Defaults to NO to help the developer catch incorrect mapping configurations during
 development.

 **Default**: NO
 */
@property (nonatomic, assign) BOOL ignoreUnknownKeyPaths;

/**
 An array of NSDateFormatter objects to use when mapping string values
 into NSDate attributes on the target objectClass. Each date formatter
 will be invoked with the string value being mapped until one of the date
 formatters does not return nil.

 Defaults to the application-wide collection of date formatters configured via:
 [RKObjectMapping setDefaultDateFormatters:]

 @see [RKObjectMapping defaultDateFormatters]
 */
@property (nonatomic, retain) NSArray *dateFormatters;

/**
 The NSFormatter object for your application's preferred date
 and time configuration. This date formatter will be used when generating
 string representations of NSDate attributes (i.e. during serialization to
 URL form encoded or JSON format).

 Defaults to the application-wide preferred date formatter configured via:
 [RKObjectMapping setPreferredDateFormatter:]

 @see [RKObjectMapping preferredDateFormatter]
 */
@property (nonatomic, retain) NSFormatter *preferredDateFormatter;

#pragma mark - Mapping Instantiation

/**
 Returns an object mapping for the specified class that is ready for configuration
 */
+ (id)mappingForClass:(Class)objectClass;

/**
 Returns an object mapping useful for configuring a serialization mapping. The object
 class is configured as NSMutableDictionary
 */
+ (id)requestMapping;

- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping;
- (void)addPropertyMappingsFromArray:(NSArray *)arrayOfPropertyMappings;

#pragma mark - Attribute & Relationship Mapping

/**
 Define an attribute mapping for one or more keyPaths where the source keyPath and destination attribute property
 have the same name.

 For example, given the transformation from a JSON dictionary:

    {"name": "My Name", "age": 28}

 To a Person class with corresponding name &amp; age properties, we could configure the attribute mappings via:

    [mapping mapAttributes:@"name", @"age", nil];

 @param attributeKey A key-value coding key corresponding to a value in the mappable source object and an attribute
 on the destination class that have the same name.
 */
- (void)mapAttributes:(NSString *)attributeKey, ... DEPRECATED_ATTRIBUTE NS_REQUIRES_NIL_TERMINATION;

/**
 Adds attribute mappings from a given dictionary wherein the keys represent the source key path
 and the values represent the names of the target attributes on the destination object.
 
 @param keyPathToAttributeNames A dictionary keyed by source key to destination attribute name.
 */
- (void)addAttributeMappingsFromDictionary:(NSDictionary *)keyPathToAttributeNames;

/**
 Adds attribute mappings to the rec
 */
- (void)addAttributeMappingsFromArray:(NSArray *)arrayOfAttributeNamesOrMappings;

/**
 Defines an attribute mapping for each string attribute in the collection where the source keyPath and the
 destination attribute property have the same name.

 For example, given the transformation from a JSON dictionary:

    {"name": "My Name", "age": 28}

 To a Person class with corresponding name &amp; age properties, we could configure the attribute mappings via:

    [mapping mapAttributesFromSet:[NSSet setWithObjects:@"name", @"age", nil]];

 @param set A set of string attribute keyPaths to deifne mappings for
 */
- (void)mapAttributesFromSet:(NSSet *)set DEPRECATED_ATTRIBUTE;

/**
 Defines an attribute mapping for each string attribute in the collection where the source keyPath and the
 destination attribute property have the same name.

 For example, given the transformation from a JSON dictionary:

    {"name": "My Name", "age": 28}

 To a Person class with corresponding name &amp; age properties, we could configure the attribute mappings via:

    [mapping mapAttributesFromArray:[NSArray arrayWithObjects:@"name", @"age", nil]];

 @param array An array of string attribute keyPaths to deifne mappings for
 */
- (void)mapAttributesFromArray:(NSArray *)set DEPRECATED_ATTRIBUTE;

/**
 Defines a relationship mapping for a key where the source keyPath and the destination relationship property
 have the same name.

 For example, given the transformation from a JSON dictionary:

 {"name": "My Name", "age": 28, "cat": { "name": "Asia" } }

 To a Person class with corresponding 'cat' relationship property, we could configure the mappings via:

     RKObjectMapping *catMapping = [RKObjectMapping mappingForClass:[Cat class]];
     [personMapping mapRelationship:@"cat" withObjectMapping:catMapping];

 @param relationshipKey A key-value coding key corresponding to a value in the mappable source object and a property
    on the destination class that have the same name.
 @param objectOrDynamicMapping An RKObjectMapping or RKObjectDynamic mapping to apply when mapping the relationship
 */
- (void)mapRelationship:(NSString *)relationshipKey withMapping:(RKMapping *)objectOrDynamicMapping DEPRECATED_ATTRIBUTE;

/**
 Syntactic sugar to improve readability when defining a relationship mapping. Implies that the mapping
 targets a one-to-many relationship nested within the source data.

 @see mapRelationship:withObjectMapping:
 */
- (void)hasMany:(NSString *)keyPath withMapping:(RKMapping *)objectOrDynamicMapping DEPRECATED_ATTRIBUTE;

/**
 Syntactic sugar to improve readability when defining a relationship mapping. Implies that the mapping
 targets a one-to-one relationship nested within the source data.

 @see mapRelationship:withObjectMapping:
 */
- (void)hasOne:(NSString *)keyPath withMapping:(RKMapping *)objectOrDynamicMapping DEPRECATED_ATTRIBUTE;

/**
 Instantiate and add an RKAttributeMapping instance targeting a keyPath within the mappable
 source data to an attribute on the target object.

 Used to quickly define mappings where the source value is deeply nested in the mappable data or
 the source and destination do not have corresponding names.

 Examples:
    // We want to transform the name to something Cocoa-esque
    [mapping mapKeyPath:@"created_at" toAttribute:@"createdAt"];

    // We want to extract nested data and map it to a property
    [mapping mapKeyPath:@"results.metadata.generated_on" toAttribute:@"generationTimestamp"];

 @param sourceKeyPath A key-value coding keyPath to fetch the mappable value from
 @param destinationAttribute The attribute name to assign the mapped value to
 @see RKAttributeMapping
 */
- (void)mapKeyPath:(NSString *)sourceKeyPath toAttribute:(NSString *)destinationAttribute DEPRECATED_ATTRIBUTE;

/**
 Instantiate and add an RKRelationshipMapping instance targeting a keyPath within the mappable
 source data to a relationship property on the target object.

 Used to quickly define mappings where the source value is deeply nested in the mappable data or
 the source and destination do not have corresponding names.

 Examples:
     // We want to transform the name to something Cocoa-esque
     [mapping mapKeyPath:@"best_friend" toRelationship:@"bestFriend" withObjectMapping:friendMapping];

     // We want to extract nested data and map it to a property
     [mapping mapKeyPath:@"best_friend.favorite_cat" toRelationship:@"bestFriendsFavoriteCat" withObjectMapping:catMapping];

 @param sourceKeyPath A key-value coding keyPath to fetch the mappable value from
 @param destinationRelationship The relationship name to assign the mapped value to
 @param objectMapping An object mapping to use when processing the nested objects
 @see RKRelationshipMapping
 */
- (void)mapKeyPath:(NSString *)sourceKeyPath toRelationship:(NSString *)destinationRelationship withMapping:(RKMapping *)objectOrDynamicMapping DEPRECATED_ATTRIBUTE;

/**
 Instantiate and add an RKRelationshipMapping instance targeting a keyPath within the mappable
 source data to a relationship property on the target object.

 Used to indicate whether the relationship should be included in serialization.

 @param sourceKeyPath A key-value coding keyPath to fetch the mappable value from
 @param destinationRelationship The relationship name to assign the mapped value to
 @param objectMapping An object mapping to use when processing the nested objects
 @param serialize A boolean value indicating whether to include this relationship in serialization

 @see mapKeyPath:toRelationship:withObjectMapping:
 */
- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString *)keyPath withMapping:(RKMapping *)objectOrDynamicMapping serialize:(BOOL)serialize DEPRECATED_ATTRIBUTE;

/**
 Quickly define a group of attribute mappings using alternating keyPath and attribute names. You must provide
 an equal number of keyPath and attribute pairs or an exception will be generated.

 For example:
    [personMapping mapKeyPathsToAttributes:@"name", @"name", @"createdAt", @"createdAt", @"street_address", @"streetAddress", nil];

 @param sourceKeyPath A key-value coding key path to fetch a mappable value from
 @param ... A nil-terminated sequence of strings alternating between source key paths and destination attributes
 */
- (void)mapKeyPathsToAttributes:(NSString *)sourceKeyPath, ... NS_REQUIRES_NIL_TERMINATION DEPRECATED_ATTRIBUTE;


/**
 Configures a sub-key mapping for cases where JSON has been nested underneath a key named after an attribute.

 For example, consider the following JSON:

     { "users":
        {
            "blake": { "id": 1234, "email": "blake@restkit.org" },
            "rachit": { "id": 5678", "email": "rachit@restkit.org" }
        }
     }

 We can configure our mappings to handle this in the following form:

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[User class]];
    mapping.forceCollectionMapping = YES; // RestKit cannot infer this is a collection, so we force it
    [mapping mapKeyOfNestedDictionaryToAttribute:@"firstName"];
    [mapping mapFromKeyPath:@"(firstName).id" toAttribute:"userID"];
    [mapping mapFromKeyPath:@"(firstName).email" toAttribute:"email"];

    [[RKObjectManager sharedManager].mappingProvider setObjectMapping:mapping forKeyPath:@"users"];
 */
- (void)mapKeyOfNestedDictionaryToAttribute:(NSString *)attributeName;

/**
 Returns the attribute mapping targeting the key of a nested dictionary in the source JSON.
 This attribute mapping corresponds to the attributeName configured via mapKeyOfNestedDictionaryToAttribute:

 @see mapKeyOfNestedDictionaryToAttribute:
 @returns An attribute mapping for the key of a nested dictionary being mapped or nil
 */
- (RKAttributeMapping *)attributeMappingForKeyOfNestedDictionary;

/**
 Removes an instance of an attribute or relationship mapping from the object mapping

 @param attributeOrRelationshipMapping The attribute or relationship mapping to remove
 */
- (void)removePropertyMapping:(RKPropertyMapping *)propertyMapping;

#pragma mark - Inverse Mappings

/**
 Generates an inverse mapping for the rules specified within this object mapping. This can be used to
 quickly generate a corresponding serialization mapping from a configured object mapping. The inverse
 mapping will have the source and destination keyPaths swapped for all attribute and relationship mappings.
 */
//- (RKObjectMapping *)inverseMapping;

/**
 Returns the default value to be assigned to the specified attribute when it is missing from a
 mappable payload.

 The default implementation returns nil for transient object mappings. On managed object mappings, the
 default value returned from the Entity definition will be used.

 @see [RKManagedObjectMapping defaultValueForMissingAttribute:]
 */
- (id)defaultValueForMissingAttribute:(NSString *)attributeName;

/**
 Returns the class of the attribute or relationship property of the target objectClass

 Given the name of a string property, this will return an NSString, etc.

 @param propertyName The name of the property we would like to retrieve the type of
 */
- (Class)classForProperty:(NSString *)propertyName;

@end

/////////////////////////////////////////////////////////////////////////////

/**
 Defines the inteface for configuring time and date formatting handling within RestKit
 object mappings. For performance reasons, RestKit reuses a pool of date formatters rather
 than constructing them at mapping time. This collection of date formatters can be configured
 on a per-object mapping or application-wide basis using the static methods exposed in this
 category.
 */
@interface RKObjectMapping (DateAndTimeFormatting)

/**
 Returns the collection of default date formatters that will be used for all object mappings
 that have not been configured specifically.

 Out of the box, RestKit initializes the following default date formatters for you in the
 UTC time zone:
    * yyyy-MM-dd'T'HH:mm:ss'Z'
    * MM/dd/yyyy

 @return An array of NSFormatter objects used when mapping strings into NSDate attributes
 */
+ (NSArray *)defaultDateFormatters;

/**
 Sets the collection of default date formatters to the specified array. The array should
 contain configured instances of NSDateFormatter in the order in which you want them applied
 during object mapping operations.

 @param dateFormatters An array of date formatters to replace the existing defaults
 @see defaultDateFormatters
 */
+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters;

/**
 Adds a date formatter instance to the default collection

 @param dateFormatter An NSFormatter object to append to the end of the default formatters collection
 @see defaultDateFormatters
 */
+ (void)addDefaultDateFormatter:(NSFormatter *)dateFormatter;

/**
 Convenience method for quickly constructing a date formatter and adding it to the collection of default
 date formatters. The locale is auto-configured to en_US_POSIX

 @param dateFormatString The dateFormat string to assign to the newly constructed NSDateFormatter instance
 @param nilOrTimeZone The NSTimeZone object to configure on the NSDateFormatter instance. Defaults to UTC time.
 @result A new NSDateFormatter will be appended to the defaultDateFormatters with the specified date format and time zone
 @see NSDateFormatter
 */
+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone;

/**
 Returns the preferred date formatter to use when generating NSString representations from NSDate attributes.
 This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations
 that do not have a native time construct.

 Defaults to a date formatter configured for the UTC Time Zone with a format string of "yyyy-MM-dd HH:mm:ss Z"

 @return The preferred NSFormatter object to use when serializing dates into strings
 */
+ (NSFormatter *)preferredDateFormatter;

/**
 Sets the preferred date formatter to use when generating NSString representations from NSDate attributes.
 This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations
 that do not have a native time construct.

 @param dateFormatter The NSFormatter object to designate as the new preferred instance
 */
+ (void)setPreferredDateFormatter:(NSFormatter *)dateFormatter;

@end
