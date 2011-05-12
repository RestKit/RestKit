//
//  RKObjectMappingOperation.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"
#import "RKObjectAttributeMapping.h"
#import "RKObjectFactory.h"

@class RKObjectMappingOperation;

@protocol RKObjectMappingOperationDelegate  <NSObject>

@required
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectAttributeMapping *)mapping forKeyPath:(NSString *)keyPath;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping*)mapping;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFailWithError:(NSError*)error;

@end

/*!
 Performs an object mapping operation by mapping values from a dictinary of elements
 and setting the mapped values onto a target object.
 */
@interface RKObjectMappingOperation : NSObject {
    id _sourceObject;
    id _destinationObject;
    RKObjectMapping* _objectMapping;    
    id<RKObjectMappingOperationDelegate> _delegate;
    id<RKObjectFactory> _objectFactory;
}

/*!
 A dictionary of mappable elements containing simple values or nested object structures.
 */
@property (nonatomic, readonly) id sourceObject;

/*!
 The target object for this operation. Mappable values in elements will be applied to object
 using key-value coding.
 */
@property (nonatomic, readonly) id destinationObject;

/*!
 The object mapping defining how values contained in the source object should be transformed to the destination object via key-value coding
 */
@property (nonatomic, readonly) RKObjectMapping* objectMapping;

/*!
 The delegate to inform of interesting events during the mapping operation
 */
@property (nonatomic, assign) id<RKObjectMappingOperationDelegate> delegate;

/*!
 An object factory responsible for creating new instances of mappable objects
 necessary for the processing of relationship mappings
 */
@property (nonatomic, assign) id<RKObjectFactory> objectFactory;

/*!
 Create a new mapping operation configured to transform the object representation
 in a source object to a new destination object according to an object mapping definition
 */
+ (RKObjectMappingOperation*)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withObjectMapping:(RKObjectMapping*)objectMapping;

/*!
 Initialize a mapping operation for an object and set of data at a particular key path with an object mapping definition
 */
- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject objectMapping:(RKObjectMapping*)objectMapping;

/*!
 Process all mappable values from the mappable dictionary and assign them to the target object
 according to the rules expressed in the object mapping definition
 */
- (BOOL)performMapping:(NSError**)error;

@end
