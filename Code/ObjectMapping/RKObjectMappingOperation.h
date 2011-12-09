//
//  RKObjectMappingOperation.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters
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

@protocol RKObjectMappingOperationDelegate  <NSObject>

@optional
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectAttributeMapping *)mapping forKeyPath:(NSString *)keyPath;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping*)mapping;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFailWithError:(NSError*)error;

@end

/**
 Performs an object mapping operation by mapping values from a dictinary of elements
 and setting the mapped values onto a target object.
 */
@interface RKObjectMappingOperation : NSObject {
    id _sourceObject;
    id _destinationObject;
    RKObjectMapping* _objectMapping;    
    id<RKObjectMappingOperationDelegate> _delegate;
    NSDictionary* _nestedAttributeSubstitution;
    NSError* _validationError;
    RKMappingOperationQueue *_queue;
}

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
@property (nonatomic, readonly) RKObjectMapping* objectMapping;

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
 Create a new mapping operation configured to transform the object representation
 in a source object to a new destination object according to an object mapping definition.
 
 Note that if Core Data support is available, an instance of RKManagedObjectMappingOperation may be returned
 
 @return An instance of RKObjectMappingOperation or RKManagedObjectMappingOperation for performing the mapping
 */
+ (id)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withMapping:(id<RKObjectMappingDefinition>)mapping;

/**
 Initialize a mapping operation for an object and set of data at a particular key path with an object mapping definition
 */
- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(id<RKObjectMappingDefinition>)mapping;

/**
 Process all mappable values from the mappable dictionary and assign them to the target object
 according to the rules expressed in the object mapping definition
 */
- (BOOL)performMapping:(NSError**)error;

@end
