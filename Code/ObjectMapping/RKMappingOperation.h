//
//  RKMappingOperation.h
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
#import "RKAttributeMapping.h"

@class RKMappingOperation, RKDynamicMapping;
@protocol RKMappingOperationDataSource;

/**
 Objects acting as the delegate for RKMappingOperation objects must adopt the
 RKMappingOperationDelegate protocol. These methods enable the delegate to be
 notified of events such as the application of attribute and relationship mappings
 during a mapping operation.
 */
@protocol RKMappingOperationDelegate  <NSObject>

@optional

/**
 Tells the delegate that an attribute or relationship mapping was found for a given key
 path within the data being mapped.

 @param operation The object mapping operation being performed.
 @param mapping The RKObjectAttributeMapping or RKObjectRelationshipMapping found for the key path.
 @param keyPath The key path in the source object for which the mapping is to be applied.
 */
- (void)mappingOperation:(RKMappingOperation *)operation didFindMapping:(RKAttributeMapping *)mapping forKeyPath:(NSString *)keyPath;

/**
 Tells the delegate that no attribute or relationships mapping was found for a given key
 path within the data being mapped.

 @param operation The object mapping operation being performed.
 @param keyPath The key path in the source object for which no mapping was found.
 */
- (void)mappingOperation:(RKMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath;

/**
 Tells the delegate that the mapping operation has set a value for a given key path with
 an attribute or relationship mapping.

 @param operation The object mapping operation being performed.
 @param value A new value that was set on the destination object.
 @param keyPath The key path in the destination object for which a new value has been set.
 @param mapping The RKObjectAttributeMapping or RKObjectRelationshipMapping found for the key path.
 */
- (void)mappingOperation:(RKMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping;

/**
 Tells the delegate that the mapping operation has declined to set a value for a given
 key path because the value has not changed.

 @param operation The object mapping operation being performed.
 @param value A unchanged value for the key path in the destination object.
 @param keyPath The key path in the destination object for which a unchanged value was not set.
 @param mapping The RKObjectAttributeMapping or RKObjectRelationshipMapping found for the key path.
 */
- (void)mappingOperation:(RKMappingOperation *)operation didNotSetUnchangedValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping;

/**
 Tells the delegate that the mapping operation has failed due to an error.

 @param operation The object mapping operation that has failed.
 @param error An error object indicating the reason for the failure.
 */
- (void)mappingOperation:(RKMappingOperation *)operation didFailWithError:(NSError *)error;

/**
 Tells the delegate that the mapping operation has selected a concrete object mapping with which to map the source object.
 
 Only sent if the receiver was initialized with an instance of RKDynamicMapping as the mapping.
 
 @param operation The mapping operation.
 @param objectMapping The concrete object mapping with which to perform the mapping.
 @param dynamicMapping The dynamic source mapping from which the object mapping was determined.
 
 @since 0.11.0
 */
- (void)mappingOperation:(RKMappingOperation *)operation didSelectObjectMapping:(RKObjectMapping *)objectMapping forDynamicMapping:(RKDynamicMapping *)dynamicMapping;

@end

/**
 Instances of RKMappingOperation perform transformation between object
 representations according to the rules express in RKObjectMapping objects. Mapping
 operations provide the foundation for the RestKit object mapping engine and
 perform the work of inspecting the attributes and relationships of a source object
 and determining how to map them into new representations on a destination object.

 */
@interface RKMappingOperation : NSObject

/**
 A dictionary of mappable elements containing simple values or nested object structures.
 */
@property (nonatomic, retain, readonly) id sourceObject;

/**
 The target object for this operation. Mappable values in elements will be applied to object
 using key-value coding.
 */
@property (nonatomic, retain, readonly) id destinationObject;

/**
 The mapping defining how values contained in the source object should be transformed to the destination object via key-value coding.
 
 Will either be an instance of RKObjectMapping or RKDynamicMapping.
 */
@property (nonatomic, retain, readonly) RKMapping *mapping;

/**
 The delegate to inform of interesting events during the mapping operation
 */
@property (nonatomic, assign) id<RKMappingOperationDelegate> delegate;

/**
 The data source is responsible for providing the mapping operation with an appropriate target object for
 mapping when the destination is nil.

 @see RKMappingOperationDataSource
 */
@property (nonatomic, assign) id<RKMappingOperationDataSource> dataSource;

/**
 Creates and returns a new mapping operation configured to transform the object representation
 in a source object to a new destination object according to an object mapping definition.

 Note that if Core Data support is available, an instance of RKManagedObjectMappingOperation may be returned.

 @param sourceObject The source object to be mapped. Cannot be nil.
 @param destinationObject The destination object the results are to be mapped onto. May be nil,
 in which case a new object will be constructed during the mapping.
 @param objectOrDynamicMapping An instance of RKObjectMapping or RKDynamicMapping defining how the
 mapping is to be performed.
 @return An instance of RKObjectMappingOperation or RKManagedObjectMappingOperation for performing the mapping.
 */
+ (id)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withMapping:(RKMapping *)objectOrDynamicMapping;

/**
 Initializes the receiver with a source and destination objects and an object mapping
 definition for performing a mapping.

 @param sourceObject The source object to be mapped. Cannot be nil.
 @param destinationObject The destination object the results are to be mapped onto. May be nil,
 in which case a new object will be constructed during the mapping.
 @param objectOrDynamicMapping An instance of RKObjectMapping or RKDynamicMapping defining how the
 mapping is to be performed.
 @return The receiver, initialized with a source object, a destination object, and a mapping.
 */
- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKMapping *)objectOrDynamicMapping;

/**
 Process all mappable values from the mappable dictionary and assign them to the target object
 according to the rules expressed in the object mapping definition

 @param error A pointer to an NSError reference to capture any error that occurs during the mapping. May be nil.
 @return A Boolean value indicating if the mapping operation was successful.
 */
- (BOOL)performMapping:(NSError **)error;

@end
