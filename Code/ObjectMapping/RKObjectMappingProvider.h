//
//  RKObjectMappingProvider.h
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"

/*!
 Responsible for providing object mappings to an instance of the object mapper
 by evaluating the current keyPath being operated on
 */
@interface RKObjectMappingProvider : NSObject {
    NSMutableDictionary* _mappings;
    NSMutableDictionary* _serializationMappings;
}

/**
 * Set a mapping for a keypath that comes back in your payload
 */
- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath;

/**
 * returns _mappings
 */
- (NSDictionary*)objectMappingsByKeyPath;

/**
 * Set a mapping to serialize objects of a specific class
 * for posting/putting back to the server
 */
- (void)setMapping:(RKObjectMapping *)mapping forObjectClass:(Class)objectClass;

/**
 * returns the serialization mapping for a specific object class
 * which has been previously registered.
 */
- (RKObjectMapping*)objectMappingForClass:(Class)objectClass;

@end
