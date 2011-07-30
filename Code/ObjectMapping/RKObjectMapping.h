//
//  RKObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAbstractMapping.h"
#import "RKObjectAttributeMapping.h"
#import "RKObjectRelationshipMapping.h"

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
@interface RKObjectMapping : RKObjectAbstractMapping {
    Class _objectClass;
    NSMutableArray* _mappings;
    NSMutableArray* _dateFormatStrings;
    NSString* _rootKeyPath;
    BOOL _setDefaultValueForMissingAttributes;
    BOOL _setNilForMissingRelationships;
    BOOL _forceCollectionMapping;
    BOOL _performKeyValueValidation;
}

/**
 The target class this object mapping is defining rules for
 */
@property (nonatomic, assign) Class objectClass;

/**
 The aggregate collection of attribute and relationship mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray* mappings;

/**
 The collection of attribute mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray* attributeMappings;

/**
 The collection of relationship mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray* relationshipMappings;

/**
 The collection of mappable keyPaths that are defined within this object mapping. These
 keyPaths refer to keys within the source object being mapped (i.e. the parsed JSON payload).
 */
@property (nonatomic, readonly) NSArray* mappedKeyPaths;

/**
 The root keyPath for this object. When the object mapping is being used for serialization
 and a root keyPath has been defined, the serialized object will be nested under this root keyPath
 before being encoded for transmission to a remote system.
 
 @see RKObjectSerializer
 */
@property (nonatomic, retain) NSString* rootKeyPath;

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
 Forces the mapper to treat the mapped keyPath as a collection even if it does not
 return an array or a set of objects. This permits mapping where a dictionary identifies
 a collection of objects.
 
 When enabled, each key/value pair in the resolved dictionary will be mapped as a separate
 entity. This is useful when you have a JSON structure similar to:
 
     { "users": 
        { 
            "blake": { "id": 1234, "email": "blake@restkit.org" },
            "rachit": { "id": 5678", "email": "rachit@restkit.org" }
        }
     }
 
 By enabling forceCollectionMapping, RestKit will map "blake" => attributes and
 "rachit" => attributes as independent objects. This can be combined with
 mapKeyOfNestedDictionaryToAttribute: to properly map these sorts of structures.
 
 @default NO
 @see mapKeyOfNestedDictionaryToAttribute
 */
@property (nonatomic, assign) BOOL forceCollectionMapping;

/**
 An array of date format strings to apply when mapping a
 String attribute to a NSDate property. Each format string will be applied
 until the date formatter does not return nil.
 */
@property (nonatomic, retain) NSMutableArray* dateFormatStrings;

/**
 Returns an object mapping for the specified class that is ready for configuration
 */
+ (id)mappingForClass:(Class)objectClass;

/**
 Returns an object mapping useful for configuring a serialization mapping. The object
 class is configured as NSMutableDictionary
 */
+ (id)serializationMapping;

#if NS_BLOCKS_AVAILABLE
/**
 Returns an object mapping targeting the specified class. The RKObjectMapping instance will
 be yieled to the block so that you can perform on the fly configuration without having to
 obtain a reference variable for the mapping.
 
 For example, consider we have a one-off request that will load a few attributes for our object. 
 Using blocks, this is very succinct:
 
    [[RKObjectManager sharedManager] postObject:self delegate:self block:^(RKObjectLoader* loader) {
        loader.objectMapping = [RKObjectMapping mappingForClass:[Person class] block:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"email", @"first_name", nil];
        }];
    }];
 */
+ (id)mappingForClass:(Class)objectClass block:(void(^)(RKObjectMapping*))block;

/**
 Returns serialization mapping for encoding a local object to a dictionary for transport. The RKObjectMapping instance will
 be yieled to the block so that you can perform on the fly configuration without having to
 obtain a reference variable for the mapping.
 
 For example, consider we have a one-off request within which we want to post a subset of our object
 data. Using blocks, this is very succinct:
 
    - (BOOL)changePassword:(NSString*)newPassword error:(NSError**)error {
        if ([self validatePassword:newPassword error:error]) {
            self.password = newPassword;
            [[RKObjectManager sharedManager] putObject:self delegate:self block:^(RKObjectLoader* loader) {
                loader.serializationMapping = [RKObjectMapping serializationMappingWithBlock:^(RKObjectMapping* mapping) {
                    [mapping mapAttributes:@"password", nil];
                }];
            }];
        }
    }
 
 Using the block forms we are able to quickly configure and send this request on the fly.
 */
+ (id)serializationMappingWithBlock:(void(^)(RKObjectMapping*))block;
#endif

/**
 Add a configured attribute mapping to this object mapping
 
 @see RKObjectAttributeMapping
 */
- (void)addAttributeMapping:(RKObjectAttributeMapping*)mapping;

/**
 Add a configured attribute mapping to this object mapping
 
 @see RKObjectRelationshipMapping
 */
- (void)addRelationshipMapping:(RKObjectRelationshipMapping*)mapping;

/**
 Returns the attribute or relationship mapping for the given source keyPath.
 
 @param sourceKeyPath A keyPath within the mappable source object that is mapped to an 
 attribute or relationship in this object mapping.
 */
- (id)mappingForKeyPath:(NSString*)sourceKeyPath;

/**
 Returns the attribute mapping targeting the specified attribute on the destination object
 
 @param attributeKey The name of the attribute we want to retrieve the mapping for
 */
- (RKObjectAttributeMapping*)mappingForAttribute:(NSString*)attributeKey;

/**
 Returns the relationship mapping targeting the specified relationship on the destination object
 
 @param relationshipKey The name of the relationship we want to retrieve the mapping for
 */
- (RKObjectRelationshipMapping*)mappingForRelationship:(NSString*)relationshipKey;

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
- (void)mapAttributes:(NSString*)attributeKey, ... NS_REQUIRES_NIL_TERMINATION;

/**
 Defines a relationship mapping for a key where the source keyPath and the destination relationship property
 have the same name.
 
 For example, given the transformation from a JSON dictionary:
 
 {"name": "My Name", "age": 28, "cat": { "name": "Asia" } }
 
 To a Person class with corresponding 'cat' relationship property, we could configure the mappings via:
 
     RKObjectMapping* catMapping = [RKObjectMapping mappingForClass:[Cat class]];
     [personMapping mapRelationship:@"cat" withObjectMapping:catMapping];
  
 @param relationshipKey A key-value coding key corresponding to a value in the mappable source object and a property 
    on the destination class that have the same name.
 @param objectOrPolymorphicMapping An RKObjectMapping or RKObjectPolymorphic mapping to apply when mapping the relationship
 */
- (void)mapRelationship:(NSString*)relationshipKey withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping;

/**
 Syntactic sugar to improve readability when defining a relationship mapping. Implies that the mapping
 targets a one-to-many relationship nested within the source data.
 
 @see mapRelationship:withObjectMapping:
 */
- (void)hasMany:(NSString*)keyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping;

/**
 Syntactic sugar to improve readability when defining a relationship mapping. Implies that the mapping
 targets a one-to-one relationship nested within the source data.
 
 @see mapRelationship:withObjectMapping:
 */
- (void)hasOne:(NSString*)keyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping;

/**
 Instantiate and add an RKObjectAttributeMapping instance targeting a keyPath within the mappable
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
 @see RKObjectAttributeMapping
 */
- (void)mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationAttribute;

/**
 Instantiate and add an RKObjectRelationshipMapping instance targeting a keyPath within the mappable
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
 @see RKObjectRelationshipMapping
 */
- (void)mapKeyPath:(NSString *)sourceKeyPath toRelationship:(NSString*)destinationRelationship withMapping:(RKObjectAbstractMapping *)objectOrPolymorphicMapping;

/**
 Instantiate and add an RKObjectRelationshipMapping instance targeting a keyPath within the mappable
 source data to a relationship property on the target object. 
 
 Used to indicate whether the relationship should be included in serialization.

 @param sourceKeyPath A key-value coding keyPath to fetch the mappable value from
 @param destinationRelationship The relationship name to assign the mapped value to
 @param objectMapping An object mapping to use when processing the nested objects
 @param serialize A boolean value indicating whether to include this relationship in serialization
 
 @see mapKeyPath:toRelationship:withObjectMapping:
 */
- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withMapping:(RKObjectAbstractMapping *)objectOrPolymorphicMapping serialize:(BOOL)serialize;

/**
 Quickly define a group of attribute mappings using alternating keyPath and attribute names. You must provide
 an equal number of keyPath and attribute pairs or an exception will be generated.
 
 For example:
    [personMapping mapKeyPathsToAttributes:@"name", @"name", @"createdAt", @"createdAt", @"street_address", @"streetAddress", nil];
 
 @param sourceKeyPath A key-value coding key path to fetch a mappable value from
 @param ... A nil-terminated sequence of strings alternating between source key paths and destination attributes
 */
- (void)mapKeyPathsToAttributes:(NSString*)sourceKeyPath, ... NS_REQUIRES_NIL_TERMINATION;


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
 
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[User class]];
    mapping.forceCollectionMapping = YES; // RestKit cannot infer this is a collection, so we force it
    [mapping mapKeyOfNestedDictionaryToAttribute:@"firstName"];
    [mapping mapFromKeyPath:@"(firstName).id" toAttribute:"userID"];
    [mapping mapFromKeyPath:@"(firstName).email" toAttribute:"email"];
 
    [[RKObjectManager sharedManager].mappingProvider setObjectMapping:mapping forKeyPath:@"users"];
 */
- (void)mapKeyOfNestedDictionaryToAttribute:(NSString*)attributeName;

/**
 Removes all currently configured attribute and relationship mappings from the object mapping
 */
- (void)removeAllMappings;

/**
 Removes an instance of an attribute or relationship mapping from the object mapping
 
 @param attributeOrRelationshipMapping The attribute or relationship mapping to remove
 */
- (void)removeMapping:(RKObjectAttributeMapping*)attributeOrRelationshipMapping;

/**
 Remove the attribute or relationship mapping for the specified source keyPath
 
 @param sourceKeyPath A key-value coding key path to remove the mappings for
 */
- (void)removeMappingForKeyPath:(NSString*)sourceKeyPath;

/**
 Generates an inverse mapping for the rules specified within this object mapping. This can be used to
 quickly generate a corresponding serialization mapping from a configured object mapping. The inverse
 mapping will have the source and destination keyPaths swapped for all attribute and relationship mappings.
 */
- (RKObjectMapping*)inverseMapping;

/**
 Returns the default value to be assigned to the specified attribute when it is missing from a
 mappable payload.
 
 The default implementation returns nil for transient object mappings. On managed object mappings, the
 default value returned from the Entity definition will be used.
 
 @see [RKManagedObjectMapping defaultValueForMissingAttribute:]
 */
- (id)defaultValueForMissingAttribute:(NSString*)attributeName;

/**
 Returns an auto-released object that can be used to apply this object mapping
 given a set of mappable data. For transient objects, this generally returns an
 instance of the objectClass. For Core Data backed persistent objects, mappableData
 will be inspected to search for primary key data to lookup existing object instances.
 */
- (id)mappableObjectForData:(id)mappableData;

@end
