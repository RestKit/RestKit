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
 An `RKObjectMapping` object describes a transformation between object represenations using key-value coding and run-time type introspection. The mapping is defined in terms of a source object class and a collection of `RKPropertyMapping` objects describing how key paths in the source representation should be transformed into attributes and relationships on the target object. Object mappings are provided to instances of `RKMapperOperation` and `RKMappingOperation` to perform the transformations they describe.

 Object mappings are containers of property mappings that describe the actual key path transformations. There are two types of property mappings:

 1. `RKAttributeMapping`: An attribute mapping describes a transformation between a single value from a source key path to a destination key path. The value to be mapped is read from the source object representation using `valueForKeyPath:` and then set to the destination key path using `setValueForKeyPath:`. Before the value is set, the `RKObjecMappingOperation` performing the mapping performs runtime introspection on the destination property to determine what, if any, type transformation is to be performed. Typical type transformations include reading an `NSString` value representation and mapping it to an `NSDecimalNumber` destination key path or reading an `NSString` and transforming it into an `NSDate` value before assigning to the destination.
 1. `RKRelationshipMapping`: A relationship mapping describes a transformation between a nested child object or objects from a source key path to a destination key path using another `RKObjectMapping`. The child objects to be mapped are read from the source object representation using `valueForKeyPath:`, then mapped recursively using the object mapping associated with the relationship mapping, and then finally assigned to the destination key path. Before assignment to the destination key path runtime type introspection is performed to determine if any type transformation is necessary. For relationship mappings, common type transformations include transforming a single object value in an `NSArray` or transforming an `NSArray` of object values into an `NSSet`.

 All type transformations available are discussed in detail in the documentation for `RKObjectMappingOperation`.

 @see `RKAttributeMapping`
 @see `RKRelationshipMapping`
 @see `RKConnectionMapping`
 @see `RKMappingOperation`
 @see `RKPropertyInspector`
 */
@interface RKObjectMapping : RKMapping <NSCopying>

///---------------------------------
/// @name Creating an Object Mapping
///---------------------------------

/**
 Returns an object mapping for the specified class that is ready for configuration

 @param objectClass The class that the mapping targets.
 @return A new mapping object.
 */
+ (id)mappingForClass:(Class)objectClass;

/**
 Initializes the receiver with a given object class. This is the designated initializer.

 @param objectClass The class that the mapping targets. Cannot be `nil`.
 @return The receiver, initialized with the given class.
 */
- (id)initWithClass:(Class)objectClass;

/**
 Returns an object mapping with an `objectClass` of `NSMutableDictionary`.

 Request mappings are used when configuring mappings that are to be used for transforming local objects into HTTP parameters using the `RKObjectParameterization` class.

 @return An object mapping with an object class of `NSMutableDictionary`.
 @see `RKObjectParameterization`
 @see `RKObjectManager`
 */
+ (id)requestMapping;

///---------------------------------
/// @name Managing Property Mappings
///---------------------------------

/**
 The aggregate collection of attribute and relationship mappings within this object mapping.
 */
@property (nonatomic, strong, readonly) NSArray *propertyMappings;

/**
 The collection of attribute mappings within this object mapping.
 */
@property (nonatomic, readonly) NSArray *attributeMappings;

/**
 The collection of relationship mappings within this object mapping.
 */
@property (nonatomic, readonly) NSArray *relationshipMappings;

/**
 Adds a property mapping to the receiver.

 @param propertyMapping The property mapping to be added to the object mapping.
 */
- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping;

/**
 Adds an array of `RKAttributeMapping` or `RKRelationshipMapping` objects to the receiver.

 @param propertyMappings The array of property mappings to be added to the object mapping.
 */
- (void)addPropertyMappingsFromArray:(NSArray *)arrayOfPropertyMappings;

/**
 Removes an `RKAttributeMapping` or `RKRelationshipMapping` from the receiver.

 @param propertyMapping The attribute or relationship mapping to remove.
 */
- (void)removePropertyMapping:(RKPropertyMapping *)propertyMapping;

/**
 Adds attribute mappings from a given dictionary wherein the keys represent the source key path and the values represent the names of the target attributes on the destination object.

 @param keyPathToAttributeNames A dictionary keyed by source key to destination attribute name.
 */
- (void)addAttributeMappingsFromDictionary:(NSDictionary *)keyPathToAttributeNames;

/**
 Adds attribute mappings to the receiver from a given array.

 The array can contain `RKAttributeMapping` objects or `NSString` values. If an `NSString` is given, then a new `RKAttributeMapping` object is instantiated with a `sourceKeyPath` and `destinationKeyPath` equal to the string value.

 @param An array of `RKAttributeMapping` or `NSString` values to be added to the receiver's set of attribute mappings,
 */
- (void)addAttributeMappingsFromArray:(NSArray *)arrayOfAttributeNamesOrMappings;

///----------------------------------
/// @name Mapping Nested Dictionaries
///----------------------------------

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

 This attribute mapping corresponds to the attributeName configured via `mapKeyOfNestedDictionaryToAttribute:`

 @return An attribute mapping for the key of a nested dictionary being mapped or nil
 @see `mapKeyOfNestedDictionaryToAttribute:`
 */
- (RKAttributeMapping *)attributeMappingForKeyOfNestedDictionary;

///----------------------------------
/// @name Configuring Mapping Options
///----------------------------------

/**
 The target class that the receiver describes a mapping for.
 */
@property (nonatomic, weak, readonly) Class objectClass;

/**
 When `YES`, any attributes that have mappings defined but are not present within the source object will be set to nil, clearing any existing value.
 */
@property (nonatomic, assign, getter = shouldSetDefaultValueForMissingAttributes) BOOL setDefaultValueForMissingAttributes;

/**
 When `YES`, any relationships that have mappings defined but are not present within the source object will be set to `nil`, clearing any existing value.
 */
@property (nonatomic, assign) BOOL setNilForMissingRelationships;

/**
 When `YES`, key-value validation will be invoked at object mapping time.

 **Default**: `YES`
 @see `validateValue:forKey:error:`
 */
@property (nonatomic, assign) BOOL performKeyValueValidation;

/**
 When `YES`, the mapping operation will check that the object being mapped is key-value coding compliant for the mapped key. If it is not, the attribute/relationship mapping will be ignored and mapping will continue. When `NO`, property mappings for unknown key paths will trigger `NSUnknownKeyException` exceptions for the unknown keyPath.

 Defaults to `NO` to help the developer catch incorrect mapping configurations during development.

 **Default**: `NO`
 */
@property (nonatomic, assign) BOOL ignoreUnknownKeyPaths;

/**
 Returns the default value to be assigned to the specified attribute when it is missing from a mappable payload.

 The default implementation returns nil for transient object mappings. On managed object mappings, the default value returned from the Entity definition will be used.

 @see `[RKManagedObjectMapping defaultValueForMissingAttribute:]`
 */
- (id)defaultValueForMissingAttribute:(NSString *)attributeName;

///----------------------------------
/// @name Configuring Date Formatters
///----------------------------------

/**
 An array of `NSFormatter` objects to use when mapping string values into `NSDate` attributes on the target `objectClass`. Each date formatter will be invoked with the string value being mapped until one of the date formatters does not return nil.

 Defaults to the application-wide collection of date formatters configured via `[RKObjectMapping setDefaultDateFormatters:]`

 @see `[RKObjectMapping defaultDateFormatters]`
 */
@property (nonatomic, strong) NSArray *dateFormatters;

/**
 The `NSFormatter` object for your application's preferred date and time configuration. This date formatter will be used when generating string representations of NSDate attributes (i.e. during serialization to URL form encoded or JSON format).

 Defaults to the application-wide preferred date formatter configured via: `[RKObjectMapping setPreferredDateFormatter:]`

 @see `[RKObjectMapping preferredDateFormatter]`
 */
@property (nonatomic, strong) NSFormatter *preferredDateFormatter;

/**
 Generates an inverse mapping for the rules specified within this object mapping. This can be used to
 quickly generate a corresponding serialization mapping from a configured object mapping. The inverse
 mapping will have the source and destination keyPaths swapped for all attribute and relationship mappings.
 */
//- (RKObjectMapping *)inverseMapping;
// TODO: Keep or kill inverse???

///---------------------------------------------------
/// @name Obtaining Information About the Target Class
///---------------------------------------------------

/**
 Returns the class of the attribute or relationship property of the target `objectClass` with the given name.

 Given the name of a string property, this will return an `NSString`, etc.

 @param propertyName The name of the property we would like to retrieve the type of.
 @return The class of the property.
 */
- (Class)classForProperty:(NSString *)propertyName;
// TODO: Can I eliminate this and just use classForKeyPath:????

/**
 Returns the class of the attribute or relationship property of the target `objectClass` at the given key path.

 Given a key path to a string property, this will return an `NSString`, etc.

 @param propertyName The name of the property we would like to retrieve the type of.
 @return The class of the property at the given key path.
 */
- (Class)classForKeyPath:(NSString *)keyPath;

@end

/////////////////////////////////////////////////////////////////////////////

/**
 Defines the interface for configuring time and date formatting handling within RestKit object mappings. For performance reasons, RestKit reuses a pool of date formatters rather than constructing them at mapping time. This collection of date formatters can be configured on a per-object mapping or application-wide basis using the static methods exposed in this category.
 */
@interface RKObjectMapping (DateAndTimeFormatting)

/**
 Returns the collection of default date formatters that will be used for all object mappings that have not been configured specifically.

 Out of the box, RestKit initializes default date formatters for you in the UTC time zone with the following format strings:

 * `yyyy-MM-dd'T'HH:mm:ss'Z'`
 * `MM/dd/yyyy`

 @return An array of `NSFormatter` objects used when mapping strings into NSDate attributes
 */
+ (NSArray *)defaultDateFormatters;

/**
 Sets the collection of default date formatters to the specified array. The array should contain configured instances of NSDateFormatter in the order in which you want them applied during object mapping operations.

 @param dateFormatters An array of date formatters to replace the existing defaults.
 @see `defaultDateFormatters`
 */
+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters;

/**
 Adds a date formatter instance to the default collection

 @param dateFormatter An `NSFormatter` object to prepend to the default formatters collection
 @see `defaultDateFormatters`
 */
+ (void)addDefaultDateFormatter:(NSFormatter *)dateFormatter;

/**
 Convenience method for quickly constructing a date formatter and adding it to the collection of default date formatters. The locale is auto-configured to `en_US_POSIX`.

 @param dateFormatString The dateFormat string to assign to the newly constructed `NSDateFormatter` instance
 @param nilOrTimeZone The NSTimeZone object to configure on the `NSDateFormatter` instance. Defaults to UTC time.
 @return A new `NSDateFormatter` will be prepended to the `defaultDateFormatters` with the specified date format and time zone
 @see `NSDateFormatter`
 */
+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone;

/**
 Returns the preferred date formatter to use when generating NSString representations from NSDate attributes. This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations that do not have a native time construct.

 Defaults to a date formatter configured for the UTC Time Zone with a format string of "yyyy-MM-dd HH:mm:ss Z"

 @return The preferred NSFormatter object to use when serializing dates into strings
 */
+ (NSFormatter *)preferredDateFormatter;

/**
 Sets the preferred date formatter to use when generating NSString representations from NSDate attributes. This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations that do not have a native time construct.

 @param dateFormatter The NSFormatter object to designate as the new preferred instance
 */
+ (void)setPreferredDateFormatter:(NSFormatter *)dateFormatter;

@end
