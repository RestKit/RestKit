//
//  RKObjectMappingOperation.h
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
#import "RKObjectAttributeMapping.h"

@class RKObjectMappingOperation;
@class RKMappingOperationQueue;

/**
 Objects acting as the delegate for RKObjectMappingOperation objects must adopt the
 RKObjectMappingOperationDelegate protocol. These methods enable the delegate to be
 notified of events such as the application of attribute and relationship mappings
 during a mapping operation.
 */
@protocol RKObjectMappingOperationDelegate  <NSObject>

@optional

/**
 Tells the delegate that an attribute or relationship mapping was found for a given key
 path within the data being mapped.

 @param operation The object mapping operation being performed.
 @param mapping The RKObjectAttributeMapping or RKObjectRelationshipMapping found for the key path.
 @param keyPath The key path in the source object for which the mapping is to be applied.
 */
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectAttributeMapping *)mapping forKeyPath:(NSString *)keyPath;

/**
 Tells the delegate that no attribute or relationships mapping was found for a given key
 path within the data being mapped.

 @param operation The object mapping operation being performed.
 @param keyPath The key path in the source object for which no mapping was found.
 */
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath;

/**
 Tells the delegate that the mapping operation has set a value for a given key path with
 an attribute or relationship mapping.

 @param operation The object mapping operation being performed.
 @param value A new value that was set on the destination object.
 @param keyPath The key path in the destination object for which a new value has been set.
 @param mapping The RKObjectAttributeMapping or RKObjectRelationshipMapping found for the key path.
 */
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping *)mapping;

/**
 Tells the delegate that the mapping operation has declined to set a value for a given
 key path because the value has not changed.

 @param operation The object mapping operation being performed.
 @param value A unchanged value for the key path in the destination object.
 @param keyPath The key path in the destination object for which a unchanged value was not set.
 @param mapping The RKObjectAttributeMapping or RKObjectRelationshipMapping found for the key path.
 */
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotSetUnchangedValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping *)mapping;

/**
 Tells the delegate that the object mapping operation has failed due to an error.

 @param operation The object mapping operation that has failed.
 @param error An error object indicating the reason for the failure.
 */
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFailWithError:(NSError *)error;
@end

/**
 Instances of RKObjectMappingOperation perform transformation between object
 representations according to the rules express in RKObjectMapping objects. Mapping
 operations provide the foundation for the RestKit object mapping engine and
 perform the work of inspecting the attributes and relationships of a source object
 and determining how to map them into new representations on a destination object.

 */
@interface RKObjectMappingOperation : NSObject

/**
 A dictionary of mappable elements containing simple values or nested object structures.
 */
@property (nonatomic, readonly) id sourceObject;

/**
 The target object for this operation. Mappable values in elements will be applied to object
 using key-value coding.
 */
@property (nonatomic, readonly) id destinationObject;

/**
 The object mapping defining how values contained in the source object should be transformed to the destination object via key-value coding
 */
@property (nonatomic, readonly) RKObjectMapping *objectMapping;

/**
 The delegate to inform of interesting events during the mapping operation
 */
@property (nonatomic, assign) id<RKObjectMappingOperationDelegate> delegate;

/**
 An operation queue for deferring portions of the mapping process until later

 Defaults to nil. If this mapping operation was configured by an instance of RKObjectMapper, then
 an instance of the operation queue will be configured and assigned for use. If the queue is nil,
 the mapping operation will perform all its operations within the body of performMapping. If a queue
 is present, it may elect to defer portions of the mapping operation using the queue.
 */
@property (nonatomic, retain) RKMappingOperationQueue *queue;

/**
 Creates and returns a new mapping operation configured to transform the object representation
 in a source object to a new destination object according to an object mapping definition.

 Note that if Core Data support is available, an instance of RKManagedObjectMappingOperation may be returned.

 @param sourceObject The source object to be mapped. Cannot be nil.
 @param destinationObject The destination object the results are to be mapped onto. May be nil,
 in which case a new object will be constructed during the mapping.
 @param mapping An instance of RKObjectMapping or RKDynamicObjectMapping defining how the
 mapping is to be performed.
 @return An instance of RKObjectMappingOperation or RKManagedObjectMappingOperation for performing the mapping.
 */
+ (id)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withMapping:(RKObjectMappingDefinition *)mapping;

/**
 Initializes the receiver with a source and destination objects and an object mapping
 definition for performing a mapping.

 @param sourceObject The source object to be mapped. Cannot be nil.
 @param destinationObject The destination object the results are to be mapped onto. May be nil,
 in which case a new object will be constructed during the mapping.
 @param mapping An instance of RKObjectMapping or RKDynamicObjectMapping defining how the
 mapping is to be performed.
 @return The receiver, initialized with a source object, a destination object, and a mapping.
 */
- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKObjectMappingDefinition *)mapping;

/**
 Process all mappable values from the mappable dictionary and assign them to the target object
 according to the rules expressed in the object mapping definition

 @param error A pointer to an NSError reference to capture any error that occurs during the mapping. May be nil.
 @return A Boolean value indicating if the mapping operation was successful.
 */
- (BOOL)performMapping:(NSError **)error;

@end
