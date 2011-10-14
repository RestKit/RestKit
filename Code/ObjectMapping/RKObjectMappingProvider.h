//
//  RKObjectMappingProvider.h
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 RestKit
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
#import "RKDynamicObjectMapping.h"

/**
 The mapping provider is a repository of registered object mappings for use by instances
 of RKObjectManager and RKObjectMapper. It provides for the storage and retrieval of object
 mappings by keyPath and type.
 
 The mapping provider is responsible for:
    
 1. Providing instances of RKObjectMapper with keyPaths and object mappings for use 
    when attempting to map a parsed payload into objects. Each keyPath is examined using
    valueForKeyPath: to determine if any mappable data exists within the payload. If data is
    found, the RKObjectMapper will instantiate an RKObjectMappingOperation to perform the mapping
    using the RKObjectMapping or RKDynamicObjectMapping associated with the keyPath.
 1. Providing the appropriate serialization mapping to instances of RKObjectManager when an object
    is to be sent to the remote server using [RKObjectManager postObject:delegate:] or 
    [RKObjectManager postObject:delegate]. This mapping is used to serialize the object into a 
    format suitable for encoding into a URL form encoded or JSON representation.
 1. Providing convenient storage of RKObjectMapping references for users who are not using keyPath
    based mapping. Mappings can be added to the provider and retrieved by the [RKObjectMapping objectClass]
    that they target.
 */
@interface RKObjectMappingProvider : NSObject {
    NSMutableArray *_objectMappings;
    NSMutableDictionary *_mappingsByKeyPath;
    NSMutableDictionary *_serializationMappings;
}

/**
 Returns a new autoreleased object mapping provider
 
 @return A new autoreleased object mapping provider instance.
 */
+ (RKObjectMappingProvider *)objectMappingProvider;

/**
 Configures the mapping provider to use the RKObjectMapping or RKDynamicObjectMapping provided when
 content is encountered at the specified keyPath.
 
 When an RKObjectMapper is performing its work, each registered keyPath within the mapping provider will
 be searched for content in the parsed payload. If mappable content is found, the object mapping configured
 for the keyPath will be used to perform an RKObjectMappingOperation.
 
 @param objectOrDynamicMapping An RKObjectMapping or RKDynamicObjectMapping to register for keyPath based mapping.
 @param keyPath The keyPath to register the mapping as being responsible for mapping.
 @see RKObjectMapper
 @see RKObjectMappingOperation
 */
- (void)setObjectMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping forKeyPath:(NSString *)keyPath;

/**
 Returns the RKObjectMapping or RKObjectDynamic mapping configured for use 
 when mappable content is encountered at keyPath
 
 @param keyPath A registered keyPath to retrieve the object mapping for
 @return The RKObjectMapping or RKDynamicObjectMapping for the specified keyPath or nil if none is registered.
 */
- (id<RKObjectMappingDefinition>)objectMappingForKeyPath:(NSString *)keyPath;

/**
 Removes the RKObjectMapping or RKDynamicObjectMapping registered at the specified keyPath
 from the provider.
 
 @param keyPath The keyPath to remove the corresponding mapping for
 */
- (void)removeObjectMappingForKeyPath:(NSString *)keyPath;

/**
 Returns a dictionary where the keys are mappable keyPaths and the values are the RKObjectMapping
 or RKDynamicObjectMapping to use for mappable data that appears at the keyPath.
 
 @warning The returned dictionary can contain RKDynamicObjectMapping instances. Check the type if
    you are using dynamic mapping.
 @return A dictionary of all registered keyPaths and their corresponding object mapping instances
 */
- (NSDictionary *)objectMappingsByKeyPath;

/**
 Registers an object mapping as being rooted at a specific keyPath. The keyPath will be registered
 and an inverse mapping for the object will be generated and used for serialization. 
 
 This is a shortcut for configuring a pair of object mappings that model a simple resource the same
 way when going to and from the server.
 
 For example, if we have a simple resource called 'person' that returns JSON in the following
 format:
 
    { "person": { "first_name": "Blake", "last_name": "Watters" } }
 
 We might configure a mapping like so:
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[Person class]];
    [mapping mapAttributes:@"first_name", @"last_name", nil];
 
 If we want to parse the above JSON and serialize it such that using postObject: or putObject: use the same format,
 we can auto-generate the serialization mapping and set the whole thing up in one shot:
 
    [[RKObjectManager sharedManager].mappingProvider registerMapping:mapping withRootKeyPath:@"person"];
 
 This will call setMapping:forKeyPath: for you, then generate a serialization mapping and set the root
 keyPath as well.
 
 If you want to manipulate the serialization mapping yourself, you can work with the mapping directly:
 
    RKObjectMapping* serializationMappingForPerson = [personMapping inverseMapping];
    // NOTE: Serialization mapping default to a nil root keyPath and will serialize to a flat dictionary
    [[RKObjectManager sharedManager].mappingProvider setSerializationMapping:serializationMappingForPerson forClass:[Person class]];
 
 @param objectMapping An object mapping we wish to register on the provider
 @param keyPath The keyPath we wish to register for the mapping and use as the rootKeyPath for serialization
 */
- (void)registerObjectMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath;

/**
 Adds an object mapping to the provider for later retrieval. The mapping is not bound to a particular keyPath and
 must be explicitly set on an instance of RKObjectLoader or RKObjectMappingOperation to be applied. This is useful
 in cases where the remote system does not namespace resources in a keyPath that can be used for disambiguation.
 
 You can retrieve mappings added to the provider by invoking objectMappingsForClass: and objectMappingForClass:
 
 @param objectMapping An object mapping instance we wish to register with the provider.
 @see objectMappingsForClass:
 @see objectMappingForClass:
 */
- (void)addObjectMapping:(RKObjectMapping *)objectMapping;

/**
 Returns all object mappings registered for a particular class on the provider. The collection of mappings is assembled
 by searching for all mappings added via addObjctMapping: and then consulting those registered via objectMappingForKeyPath:
 
 @param objectClass The class we want to retrieve the mappings for
 @return An array of all object mappings matching the objectClass. Can be empty.
 */
- (NSArray *)objectMappingsForClass:(Class)objectClass;

/**
 Returns the first object mapping for a objectClass registered in the provider.
 
 The objectClass is the class for a model you use to represent data retrieved in
 XML or JSON format. For example, if we were developing a Twitter application we
 might have an objectClass of RKTweet for storing Tweet data. We could retrieve
 the object mapping for this model by invoking 
 `[mappingProvider objectMappingForClass:[RKTweet class]];`
 
 Mappings registered via addObjectMapping: take precedence over those registered 
 via setObjectMapping:forKeyPath:.
 
 @param objectClass The class that we want to return mappings for
 @return An RKObjectMapping matching objectClass or nil
 */
- (RKObjectMapping *)objectMappingForClass:(Class)objectClass;

/**
 Registers an object mapping for use when serializing instances of objectClass for transport
 over HTTP. Used by the object manager during postObject: and putObject:.
 
 Serialization mappings are simply instances of RKObjectMapping that target NSMutableDictionary
 as the target object class. After the object is mapped into an NSMutableDictionary, it can be
 encoded to form encoded string, JSON, XML, etc.
 
 @param objectMapping The serialization mapping to register for use when serializing objectClass
 @param objectClass The class of the object type we are registering a serialization for
 @see [RKObjectMapping serializationMapping]
 */
- (void)setSerializationMapping:(RKObjectMapping *)objectMapping forClass:(Class)objectClass;

/**
 Returns the serialization mapping for a specific object class
 which has been previously registered. The 
 
 @param objectClass The class we wish to obtain the serialization mapping for
 @return The RKObjectMapping instance used for mapping instances of objectClass for transport
 @see setSerializationMapping:forClass:
 */
- (RKObjectMapping *)serializationMappingForClass:(Class)objectClass;

@end

// Method signatures being phased out
@interface RKObjectMappingProvider (CompatibilityAliases)
+ (RKObjectMappingProvider *)mappingProvider;
- (void)registerMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath;
- (void)setMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping forKeyPath:(NSString *)keyPath;
- (id<RKObjectMappingDefinition>)mappingForKeyPath:(NSString *)keyPath;
- (NSDictionary *)mappingsByKeyPath;
- (void)removeMappingForKeyPath:(NSString *)keyPath;
@end
