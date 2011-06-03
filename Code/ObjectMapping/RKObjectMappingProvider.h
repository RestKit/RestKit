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
 returns _mappings
 */
- (NSDictionary*)objectMappingsByKeyPath;

/**
 Registers an object mapping as being rooted at a specific keyPath. The keyPath will be registered
 and an inverse mapping for the object will be generated and used for serialization. 
 */
// TODO: Are we happy with this design/method signature?
- (void)registerMapping:(RKObjectMapping*)objectMapping withRootKeyPath:(NSString*)keyPath;

@end
