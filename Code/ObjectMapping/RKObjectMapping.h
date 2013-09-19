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
#import "RKValueTransformers.h"

@class RKPropertyMapping, RKAttributeMapping, RKRelationshipMapping;
@protocol RKValueTransforming;

/**
 An `RKObjectMapping` object describes a transformation between object represenations using key-value coding and run-time type introspection. The mapping is defined in terms of a source object class and a collection of `RKPropertyMapping` objects describing how key paths in the source representation should be transformed into attributes and relationships on the target object. Object mappings are provided to instances of `RKMapperOperation` and `RKMappingOperation` to perform the transformations they describe.

 Object mappings are containers of property mappings that describe the actual key path transformations. There are two types of property mappings:

 1. `RKAttributeMapping`: An attribute mapping describes a transformation between a single value from a source key path to a destination key path. The value to be mapped is read from the source object representation using `valueForKeyPath:` and then set to the destination key path using `setValueForKeyPath:`. Before the value is set, the `RKObjecMappingOperation` performing the mapping performs runtime introspection on the destination property to determine what, if any, type transformation is to be performed. Typical type transformations include reading an `NSString` value representation and mapping it to an `NSDecimalNumber` destination key path or reading an `NSString` and transforming it into an `NSDate` value before assigning to the destination.
 1. `RKRelationshipMapping`: A relationship mapping describes a transformation between a nested child object or objects from a source key path to a destination key path using another `RKObjectMapping`. The child objects to be mapped are read from the source object representation using `valueForKeyPath:`, then mapped recursively using the object mapping associated with the relationship mapping, and then finally assigned to the destination key path. Before assignment to the destination key path runtime type introspection is performed to determine if any type transformation is necessary. For relationship mappings, common type transformations include transforming a single object value in an `NSArray` or transforming an `NSArray` of object values into an `NSSet`.

 All type transformations available are discussed in detail in the documentation for `RKValueTransformer`.
 
 ## Transforming Representation to Property Keys
 
 Configuring object mappings can become quite repetitive if the keys in your serialized object representations follow a different convention than their local domain counterparts. For example, consider a typical JSON document in the "snake case" format:
 
    {"user": {"first_name": "Blake", "last_name": "Watters", "email_address": "blake@restkit.org"}}
 
 Typically when configuring a mapping for the object represented in this document we would transform the destination properties into the Objective-C idiomatic "llama case" variation. This can produce lengthy, error-prone mapping configurations in which the transformations are specified manually:
 
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"first_name": @"firstName", @"last_name": @"lastName", @"email_address", @"emailAddress" }];
 
 To combat this repetition, a block can be designated to perform a transformation on source keys to produce corresponding destination keys:
 
    [userMapping setSourceToDestinationKeyTransformationBlock:^NSString *(RKObjectMapping *mapping, NSString *sourceKey) {
        // Value transformer compliments of TransformerKit (See https://github.com/mattt/TransformerKit)
        return [[NSValueTransformer valueTransformerForName:TKLlamaCaseStringTransformerName] transformedValue:sourceKey];
    }];
 
 With the block configured, the original configuration can be changed into a simpler array based invocation:
 
    [userMapping addAttributeMappingsFromArray:@[ @"first_name", @"last_name", @"email_address" ]];
 
 Transformation blocks can be configured on a per-mapping basis via `setSourceToDestinationKeyTransformationBlock:` or globally via `[RKObjectMapping setDefaultSourceToDestinationKeyTransformationBlock:]`.

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
+ (instancetype)mappingForClass:(Class)objectClass;

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
+ (RKObjectMapping *)requestMapping;

///----------------------------------
/// @name Accessing Property Mappings
///----------------------------------

/**
 The aggregate collection of attribute and relationship mappings within this object mapping.
 */
@property (nonatomic, strong, readonly) NSArray *propertyMappings;

/**
 Returns the property mappings of the receiver in a dictionary, where the keys are the source key paths and the values are instances of `RKAttributeMapping` or `RKRelationshipMapping`.
 
 @return The property mappings of the receiver in a dictionary, where the keys are the source key paths and the values are instances of `RKAttributeMapping` or `RKRelationshipMapping`.
 @warning Note this method does not return any property mappings with a `nil` value for the source key path in the dictionary returned.
 */
@property (nonatomic, readonly) NSDictionary *propertyMappingsBySourceKeyPath;

/**
 Returns the property mappings of the receiver in a dictionary, where the keys are the destination key paths and the values are instances of `RKAttributeMapping` or `RKRelationshipMapping`.
 
 @return The property mappings of the receiver in a dictionary, where the keys are the destination key paths and the values are instances of `RKAttributeMapping` or `RKRelationshipMapping`.
 @warning Note this method does not return any property mappings with a `nil` value for the source key path in the dictionary returned.
 */
@property (nonatomic, readonly) NSDictionary *propertyMappingsByDestinationKeyPath;

/**
 The collection of attribute mappings within this object mapping.
 */
@property (nonatomic, readonly) NSArray *attributeMappings;

/**
 The collection of relationship mappings within this object mapping.
 */
@property (nonatomic, readonly) NSArray *relationshipMappings;

/**
 Returns the property mapping registered with the receiver with the given source key path.
 
 @param sourceKeyPath The key path to retrieve.
 */
- (id)mappingForSourceKeyPath:(NSString *)sourceKeyPath;

/**
 Returns the property mapping registered with the receiver with the given destinationKeyPath key path.
 
 @param destinationKeyPath The key path to retrieve.
 */
- (id)mappingForDestinationKeyPath:(NSString *)destinationKeyPath;

///---------------------------
/// Managing Property Mappings
///---------------------------

/**
 Adds a property mapping to the receiver.

 @param propertyMapping The property mapping to be added to the object mapping.
 */
- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping;

/**
 Adds an array of `RKAttributeMapping` or `RKRelationshipMapping` objects to the receiver.

 @param arrayOfPropertyMappings The array of property mappings to be added to the object mapping.
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

 @param arrayOfAttributeNamesOrMappings An array of `RKAttributeMapping` or `NSString` values to be added to the receiver's set of attribute mappings,
 */
- (void)addAttributeMappingsFromArray:(NSArray *)arrayOfAttributeNamesOrMappings;

/**
 Adds a relationship mapping to the receiver with the given source key path and mapping.
 
 The destination key path will be the same as the source key path or processed by the source to destination key transformation block, if any is configured.
 
 @param sourceKeyPath The source key path at which to read the nested representation of the related objects.
 @param mapping The object mapping with which to process the related object representation.
 */
- (void)addRelationshipMappingWithSourceKeyPath:(NSString *)sourceKeyPath mapping:(RKMapping *)mapping;

///-------------------------------------
/// @name Configuring Key Transformation
///-------------------------------------

/**
 Sets an application-wide default transformation block to be used when attribute or relationship mappings are added to an object mapping by source key path.
 
 @param block The block to be set as the default source to destination key transformer for all object mappings in the application.
 @see [RKObjectMapping setPropertyNameTransformationBlock:]
 */
+ (void)setDefaultSourceToDestinationKeyTransformationBlock:(NSString * (^)(RKObjectMapping *mapping, NSString *sourceKey))block;

/**
 Sets a block to executed to transform a source key into a destination key.
 
 The transformation block set with this method is used whenever an attribute or relationship mapping is added to the receiver via a method that accepts a string value for the source key. The block will be executed with the source key as the only argument and the value returned will be taken as the corresponding destination key. Methods on the `RKObjectMapping` class that will trigger the execution of the block configured via this method include:
 * `addAttributeMappingsFromArray:` - Each string element contained in the given array is interpretted as a source key path and will be evaluated with the block to obtain a corresponding destination key path.
 * `addRelationshipMappingWithSourceKeyPath:mapping:` - The source key path will be evaluated with the block to obtain a corresponding destination key path.
 
 @param block The block to execute when the receiver needs to transform a source key into a destination key. The block has a string return value specifying the destination key and accepts a single string argument: the source key that is to be transformed.
 @warning Please note that the block given accepts a **key** as opposed to a **key path**. When a key path is given to a method supporting key transformation it will be decomposed into its key components by splitting the key path at the '.' (period) character, then each key will be evaluated using the transformation block and the results will be joined together into a new key path with the period character delimiter.
 */
- (void)setSourceToDestinationKeyTransformationBlock:(NSString * (^)(RKObjectMapping *mapping, NSString *sourceKey))block;

///----------------------------------
/// @name Mapping Nested Dictionaries
///----------------------------------

/**
 Adds an attribute mapping from a dynamic nesting key value to an attribute. The mapped attribute name can then be referenced within other attribute mappings to access the nested content.

 For example, consider the following JSON:

     { "users":
         {
             "blake": {  "id": 1234, "email": "blake@restkit.org" },
             "rachit": { "id": 5678, "email": "rachit@restkit.org" }
         }
     }

 We can configure our mappings to handle this in the following form:

     RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[User class]];
     mapping.forceCollectionMapping = YES; // RestKit cannot infer this is a collection, so we force it
     [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"firstName"];
     [mapping addAttributeMappingsFromDictionary:@{ @"{firstName}.id": @"userID", @"{firstName}.email": @"email" }];
 */
- (void)addAttributeMappingFromKeyOfRepresentationToAttribute:(NSString *)attributeName;

/**
 Adds an attribute mapping to a dynamic nesting key from an attribute. The mapped attribute name can then be referenced wthin other attribute mappings to map content under the nesting key path.
 
 For example, consider that we wish to map a local user object with the properties 'id', 'firstName' and 'email':
 
    RKUser *user = [RKUser new];
    user.firstName = @"blake";
    user.userID = @(1234);
    user.email = @"blake@restkit.org";

 And we wish to map it into JSON that looks like:
 
    { "blake": { "id": 1234, "email": "blake@restkit.org" } }
 
 We can configure our request mapping to handle this like so:
 
     RKObjectMapping *mapping = [RKObjectMapping requestMapping];
     [mapping addAttributeMappingToKeyOfRepresentationFromAttribute:@"firstName"];
     [mapping addAttributeMappingsFromDictionary:@{ @"userID": @"{firstName}.id", @"email": @"{firstName}.email" }];
 */
- (void)addAttributeMappingToKeyOfRepresentationFromAttribute:(NSString *)attributeName;

///----------------------------------
/// @name Configuring Mapping Options
///----------------------------------

/**
 The target class that the receiver describes a mapping for.
 */
@property (nonatomic, weak, readonly) Class objectClass;

/**
 When `YES`, any attributes that have mappings defined but are not present within the source object will be set to nil, clearing any existing value.

 **Default**: `NO`
 */
@property (nonatomic, assign) BOOL assignsDefaultValueForMissingAttributes;

/**
 When `YES`, any relationships that have mappings defined but are not present within the source object will be set to `nil`, clearing any existing value.

 **Default**: `NO`
 */
@property (nonatomic, assign) BOOL assignsNilForMissingRelationships;

/**
 When `YES`, key-value validation will be invoked at object mapping time.

 **Default**: `YES`
 @see `validateValue:forKey:error:`
 */
@property (nonatomic, assign) BOOL performsKeyValueValidation;

/**
 A value transformer with which to process input values being mapped with the receiver. Defaults to a copy of `[RKValueTransformer defaultTransformer]`.
 */
@property (nonatomic, strong) id<RKValueTransforming> valueTransformer;

/**
 Returns the default value to be assigned to the specified attribute when it is missing from a mappable payload.

 The default implementation returns nil for transient object mappings. On an entity mapping, the default value returned from the Entity definition will be used.

 @see `[RKEntityMapping defaultValueForAttribute:]`
 */
- (id)defaultValueForAttribute:(NSString *)attributeName;

///----------------------------------
/// @name Generating Inverse Mappings
///----------------------------------

/**
 Generates an inverse mapping for the rules specified within this object mapping. 
 
 This can be used to quickly generate a corresponding serialization mapping from a configured object mapping. The inverse mapping will have the source and destination keyPaths swapped for all attribute and relationship mappings. All mapping configuration and date formatters are copied from the parent to the inverse mapping.
 
 @return A new mapping that will map the inverse of the receiver.
 */
- (instancetype)inverseMapping;

/**
 Generates an inverse mapping with all property mappings of the receiver that pass the given test. Each `RKAttributeMapping` and `RKRelationshipMapping` added to the receiver is yielded to the block for evaluation. The block is also invoked for any nested relationships that are traversed during the inversion process.

 @param predicate A block object to be invoked for each `RKPropertyMapping` that is considered for inversion. The block has a Boolean return value and accepts a single argument: the property mapping that is being evaluated for inversion.
 @return A new mapping that will map the inverse of the receiver.
 @see inverseMapping
 */
- (instancetype)inverseMappingWithPropertyMappingsPassingTest:(BOOL (^)(RKPropertyMapping *propertyMapping))predicate;

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

/**
 Returns the class of the attribute or relationship property of the target `objectClass` at the given key path.

 Given a key path to a string property, this will return an `NSString`, etc.

 @param keyPath The name of the property we would like to retrieve the type of.
 @return The class of the property at the given key path.
 */
- (Class)classForKeyPath:(NSString *)keyPath;

@end

/////////////////////////////////////////////////////////////////////////////

/**
 **Deprecated in v0.21.0**
 
 This category contains deprecated API interfaces for configuring date formatters. Starting in RestKit 0.20.4 date formatting is configured via the `RKValueTransformer` API's.

 Defines the interface for configuring time and date formatting handling within RestKit object mappings. For performance reasons, RestKit reuses a pool of date formatters rather than constructing them at mapping time. This collection of date formatters can be configured on a per-object mapping or application-wide basis using the static methods exposed in this category.
 */
@interface RKObjectMapping (LegacyDateAndTimeFormatting)

/**
 **Deprecated in v0.21.0**
 
 This method accesses `[RKValueTransformer defaultTransformer]` and returns all `NSDate` <-> `NSString` value transformers.

 Returns the collection of default date formatters that will be used for all object mappings that have not been configured specifically.

 Out of the box, RestKit initializes default date formatters for you in the UTC time zone with the following format strings:

 * `yyyy-MM-dd'T'HH:mm:ss'Z'`
 * `MM/dd/yyyy`

 @return An array of `NSFormatter` objects used when mapping strings into NSDate attributes
 */
+ (NSArray *)defaultDateFormatters DEPRECATED_ATTRIBUTE_MESSAGE("Configure `[RKValueTransformer defaultValueTransformer]` instead");

/**
 **Deprecated in v0.21.0**
 
 This method accesses `[RKValueTransformer defaultTransformer]` and removes all `NSDate` <-> `NSString` value transformers that are instances of `NSFormatter` and then adds the given array of formatters to the default transformer.

 Sets the collection of default date formatters to the specified array. The array should contain configured instances of NSDateFormatter in the order in which you want them applied during object mapping operations.

 @param dateFormatters An array of date formatters to replace the existing defaults.
 @see `defaultDateFormatters`
 */
+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters DEPRECATED_ATTRIBUTE_MESSAGE("Configure `[RKValueTransformer defaultValueTransformer]` instead");

/**
 **Deprecated in v0.21.0**
 
 This methods prepends the given date formatter to `[RKValueTransformer defaultValueTransformer]`.

 Adds a date formatter instance to the default collection

 @param dateFormatter An `NSFormatter` object to prepend to the default formatters collection
 @see `defaultDateFormatters`
 */
+ (void)addDefaultDateFormatter:(NSFormatter *)dateFormatter DEPRECATED_ATTRIBUTE_MESSAGE("Configure `[RKValueTransformer defaultValueTransformer]` instead");

/**
 **Deprecated in v0.21.0**
 
 This method instantiates a new `NSDateFormatter` object with the given format string and time zone and prepends it to `[RKValueTransformer defaultValueTransformer]`.

 Convenience method for quickly constructing a date formatter and adding it to the collection of default date formatters. The locale is auto-configured to `en_US_POSIX`.

 @param dateFormatString The dateFormat string to assign to the newly constructed `NSDateFormatter` instance
 @param nilOrTimeZone The NSTimeZone object to configure on the `NSDateFormatter` instance. Defaults to UTC time.
 @see `NSDateFormatter`
 */
+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone  DEPRECATED_ATTRIBUTE_MESSAGE("Configure `[RKValueTransformer defaultValueTransformer]` instead");

/**
 **Deprecated in v0.21.0**
 
 This method returns the first `NSString` -> `NSDate` value transformer that is an instance of `NSFormatter` in `[RKValueTransformer defaultValueTransformer]`.

 Returns the preferred date formatter to use when generating NSString representations from NSDate attributes. This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations that do not have a native time construct.

 Defaults to an instance of the `RKISO8601DateFormatter` configured with the UTC time-zone. The format string is equal to "yyyy-MM-DDThh:mm:ssTZD"
 
 For details about the ISO-8601 format, see http://www.w3.org/TR/NOTE-datetime

 @return The preferred NSFormatter object to use when serializing dates into strings
 */
+ (NSFormatter *)preferredDateFormatter DEPRECATED_ATTRIBUTE_MESSAGE("Access `[RKValueTransformer defaultValueTransformer]` instead");

/**
 **Deprecated in v0.21.0**
 
 This method inserts the given date formatter at position zero in `[RKValueTransformer defaultValueTransformer]`, ensuring that it will be used for all transformations from `NSDate` -> `NSString`.

 Sets the preferred date formatter to use when generating NSString representations from NSDate attributes. This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations that do not have a native time construct.

 @param dateFormatter The NSFormatter object to designate as the new preferred instance
 */
+ (void)setPreferredDateFormatter:(NSFormatter *)dateFormatter DEPRECATED_ATTRIBUTE_MESSAGE("Configure `[RKValueTransformer defaultValueTransformer]` instead");

///----------------------------------
/// @name Configuring Date Formatters
///----------------------------------

/**
 **Deprecated in v0.21.0**
 
 An array of `NSFormatter` objects to use when mapping string values into `NSDate` attributes on the target `objectClass`. Each date formatter will be invoked with the string value being mapped until one of the date formatters does not return nil.

 Defaults to the application-wide collection of date formatters configured via `[RKObjectMapping setDefaultDateFormatters:]`

 @see `[RKObjectMapping defaultDateFormatters]`
 */
@property (nonatomic, strong) NSArray *dateFormatters DEPRECATED_ATTRIBUTE_MESSAGE("Use `valueTransformer` instead");

/**
 **Deprecated in v0.21.0**

 The `NSFormatter` object for your application's preferred date and time configuration. This date formatter will be used when generating string representations of NSDate attributes (i.e. during serialization to URL form encoded or JSON format).

 Defaults to the application-wide preferred date formatter configured via: `[RKObjectMapping setPreferredDateFormatter:]`

 @see `[RKObjectMapping preferredDateFormatter]`
 */
@property (nonatomic, strong) NSFormatter *preferredDateFormatter  DEPRECATED_ATTRIBUTE_MESSAGE("Use `valueTransformer` instead");

@end

@interface RKObjectMapping (Deprecations)
// These methods were named to be more idiomation. Properties beginning with `set` generate method names like `setSetDefaultValueForMissingAttributes` and `performKeyValueValidation` reads more as a command to perform something than a configuration switch.
@property (nonatomic, assign, getter = shouldSetDefaultValueForMissingAttributes) BOOL setDefaultValueForMissingAttributes DEPRECATED_ATTRIBUTE_MESSAGE("Renamed to `assignsDefaultValueForMissingAttributes`");
@property (nonatomic, assign) BOOL setNilForMissingRelationships DEPRECATED_ATTRIBUTE_MESSAGE("Renamed to `assignsNilForMissingRelationships`");
@property (nonatomic, assign) BOOL performKeyValueValidation DEPRECATED_ATTRIBUTE_MESSAGE("Renamed to `performsKeyValueValidation`");
@end

///----------------
/// @name Functions
///----------------

/**
 Returns an date representation of a given string value by attempting to parse the string with all default date formatters in turn.

 @param dateString A string object encoding a date value.
 @return An `NSDate` object parsed from the given string, or `nil` if the string was found to be unparsable by all default date formatters.
 @see [RKObjectMapping defaultDateFormatters]
 */
NSDate *RKDateFromString(NSString *dateString);

/**
 Returns a string representation of a given date formatted with the preferred date formatter.

 This is a convenience function that is equivalent to the following example code:

 NSString *string = [[RKObjectMapping preferredDateFormatter] stringForObjectValue:date]

 @param date The date object to be formatted.
 @return An `NSString` object representation of the given date formatted by the preferred date formatter.
 @see [RKObjectMapping preferredDateFormatter]
 */
NSString *RKStringFromDate(NSDate *date);
