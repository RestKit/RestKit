//
//  RKObjectMappingProvider.h
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"

/**
 Responsible for providing object mappings to an instance of the object mapper
 by evaluating the current keyPath being operated on
 */
@interface RKObjectMappingProvider : NSObject {
    NSMutableDictionary* _mappings;
    NSMutableDictionary* _serializationMappings;
}

/**
 Set a mapping for a keypath that comes back in your payload
 */
- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath;

/**
 Returns the object mapping to use for mapping the specified keyPath into an object graph
 */
- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath;

/**
 Set a mapping to serialize objects of a specific class into a representation
 suitable for transport over HTTP. Used by the object manager during postObject: and putObject:
 */
- (void)setSerializationMapping:(RKObjectMapping *)mapping forClass:(Class)objectClass;

/**
 returns the serialization mapping for a specific object class
 which has been previously registered.
 */
- (RKObjectMapping*)serializationMappingForClass:(Class)objectClass;

/**
 Returns a dictionary where the keys are mappable keyPaths and the values are the object
 mapping to use for objects that appear at the keyPath.
 */
- (NSDictionary*)objectMappingsByKeyPath;

/**
 Registers an object mapping as being rooted at a specific keyPath. The keyPath will be registered
 and an inverse mapping for the object will be generated and used for serialization. 
 
 This is a shortcut for configuring a pair of object mappings that model a simple resource the same
 way when going to and from the server.
 
 For example, if we configure have a simple resource called 'person' that returns JSON in the following
 format:
 
    { "person": { "first_name": "Blake", "last_name": "Watters } }
 
 We might configure a mapping like so:
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[Person class]];
    [mapping mapAttributes:@"first_name", @"last_name", nil];
 
 If we want to parse the above JSON and serialize it such that using postObject: or putObject: use the same format,
 we can auto-generate the serialization mapping and set the whole thing up in one shot:
 
    [[RKObjectManager sharedManager].mappingProvider registerMapping:mapping withRootKeyPath:@"user"];
 
 This will call setMapping:forKeyPath: for you, then generate a serialization mapping and set the root
 keyPath as well.
 
 If you want to manipulate the serialization mapping yourself, you can work with the mapping directly:
 
    RKObjectMapping* serializationMappingForPerson = [personMapping inverseMapping];
    // NOTE: Serialization mapping default to a nil root keyPath and will serialize to a flat dictionary
    [[RKObjectManager sharedManager].mappingProvider setSerializationMapping:serializationMappingForPerson forClass:[Person class]];
 */
- (void)registerMapping:(RKObjectMapping*)objectMapping withRootKeyPath:(NSString*)keyPath;

@end
