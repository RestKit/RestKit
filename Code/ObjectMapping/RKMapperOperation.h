//
//  RKMapperOperation.h
//  RestKit
//
//  Created by Blake Watters on 5/6/11.
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

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "RKObjectMapping.h"
#import "RKMappingOperation.h"
#import "RKMappingResult.h"
#import "RKMappingOperationDataSource.h"
#import "RKErrors.h"

@protocol RKMapperOperationDelegate;

/**
 `RKMapperOperation` is an `NSOperation` subclass that implements object mapping for opaque object representations. Given a dictionary or an array of dictionaries that represent objects and a dictionary describing how to map the representations, the mapper will transform the source representations into `NSObject` or `NSManagedObject` instances. Mapper operations are used to map object representations from Foundation object representations, such as those deserialized from a JSON or XML document or loaded from a file. Not all the mappings specified in the mappings dictionary are required to match content in the source object for the operation to succeed. However, if none of the mappable key paths in the mappings dictionary match the source object then the operation will fail and the `error` property will be set to an `NSError` object in the `RKErrorDomain` domain with an error code value of `RKMappingErrorNotFound`.

 `RKMapperOperation` does not actually perform any mapping work. Instead, it instantiates and starts `RKMappingOperation` objects to process the mappable object representations it encounters.

 `RKMapperOperation` is a non-concurrent operation. Execution will occur synchronously on the calling thread unless the operation is enqueued onto an `NSOperationQueue`.

 ## Mappings Dictionary

 The mappings dictionary describes how to object map the source object. The keys of the dictionary are key paths into the `representation` and the values are `RKMapping` objects describing how to map the representations at the corresponding key path. This dictionary based approach enables a single document to contain an arbitrary number of object representations that can be mapped independently. Consider the following example JSON structure:

    { "tags": [ "hacking", "phreaking" ], "authors": [ "Captain Crunch", "Emmanuel Goldstein" ], "magazine": { "title": "2600 The Hacker Quarterly" } }

 Each key in the document could be mapped independently by providing a mapping for the key paths:

    RKObjectMapping *tagMapping = [RKObjectMapping mappingForClass:[Tag class]];
    RKObjectMapping *authorMapping = [RKObjectMapping mappingForClass:[Author class]];
    RKObjectMapping *magazineMapping = [RKObjectMapping mappingForClass:[Magazine class]];
    NSDictionary *mappingsDictionary = @{ @"tag": tagMapping, @"author": authorMapping, @"magazine": magazine };

 Note that the keys of the dictionary are **key paths**. Deeply nested content can be mapped by specifying the full key path as the key of the mappings dictionary.

 ### Mapping the Root Object Representation

 A mapping set for the key `[NSNull null]` value has special significance to the mapper operation. When a mapping is encountered with the a null key, the entire `representation` is processed using the given mapping. This provides support for mapping content that does not have an outer nesting attribute.
 
 Note that it is possible to map the same representation with multiple mappings, including a combination of a root key mapping and nested keypaths.

 ## Data Source

 The data source is used to instantiate new objects or find existing objects to be updated during the mapping process. The object set as the `mappingOperationDataSource` will be set as the `dataSource` for the `RKMappingOperation` objects created by the mapper.

 ## Target Object

 If a `targetObject` is configured on the mapper operation, all mapping work on the `representation` will target the specified object. For transient `NSObject` mappings, this ensures that the properties of an existing object are updated rather than an new object being created for the mapped representation. If an array of representations is being processed and a `targetObject` is provided, it must be a mutable collection object else an exception will be raised.

 ## Core Data

 `RKMapperOperation` supports mapping to Core Data target entities. To do so, it must be configured with an `RKManagedObjectMappingOperationDataSource` object as the data source.
 */
@interface RKMapperOperation : NSOperation

///--------------------------------------
/// @name Initializing a Mapper Operation
///--------------------------------------

/**
 Initializes the operation with a source object and a mappings dictionary.

 @param representation An `NSDictionary` or `NSArray` of `NSDictionary` object representations to be mapped into local domain objects.
 @param mappingsDictionary An `NSDictionary` wherein the keys are mappable key paths in `object` and the values are `RKMapping` objects specifying how the representations at its key path are to be mapped.
 @return The receiver, initialized with the given object and and dictionary of key paths to mappings.
 */
- (id)initWithRepresentation:(id)representation mappingsDictionary:(NSDictionary *)mappingsDictionary;

///------------------------------------------
/// @name Accessing Mapping Result and Errors
///------------------------------------------

/**
 The error, if any, that occurred during the mapping process.
 */
@property (nonatomic, strong, readonly) NSError *error;

/**
 The result of the mapping process. A `nil` value indicates that no mappable object representations were found and no mapping was performed.
 */
@property (nonatomic, strong, readonly) RKMappingResult *mappingResult;

///-------------------------------------
/// @name Managing Mapping Configuration
///-------------------------------------

/**
 The representation of one or more objects against which the mapping is performed.

 Either an `NSDictionary` or an `NSArray` of `NSDictionary` objects.
 */
@property (nonatomic, strong, readonly) id representation;

/**
 A dictionary of key paths to `RKMapping` objects specifying how object representations in the `representation` are to be mapped.

 Please see the above discussion for in-depth details about the mappings dictionary.
 */
@property (nonatomic, strong, readonly) NSDictionary *mappingsDictionary;

/**
 The target object of the mapper. When configured, all object mapping will target the specified object.

 Please see the above discussion for details about target objects.
 */
@property (nonatomic, weak) id targetObject;

/**
 The data source for the underlying `RKMappingOperation` objects that perform the mapping work configured by the mapper.
 */
@property (nonatomic, strong) id<RKMappingOperationDataSource> mappingOperationDataSource;

/**
 The delegate for the mapper operation.
 */
@property (nonatomic, weak) id<RKMapperOperationDelegate> delegate;

- (BOOL)execute:(NSError **)error;

@end

///--------------------------------------
/// @name Mapper Operation Delegate
///--------------------------------------

/**
 Objects wishing to act as the delegate for `RKMapperOperation` objects must adopt the `RKMapperOperationDelegate` protocol. The protocol provides a rich set of optional callback methods that provides insight into the lifecycle of a mapper operation.
 */
@protocol RKMapperOperationDelegate <NSObject>

@optional

///-----------------------------
/// @name Tracking Mapper Status
///-----------------------------

/**
 Tells the delegate that the mapper operation is about to start mapping.

 @param mapper The mapper operation that is about to start mapping.
 */
- (void)mapperWillStartMapping:(RKMapperOperation *)mapper;

/**
 Tells the delegate that the mapper has finished.

 @param mapper The mapper operation that has finished mapping.
 */
- (void)mapperDidFinishMapping:(RKMapperOperation *)mapper;

/**
 Tells the delegate that the mapper has been cancelled.
 
 @param mapper The mapper operation that was cancelled.
 */
- (void)mapperDidCancelMapping:(RKMapperOperation *)mapper;

///-------------------------------
/// @name Key Path Search Messages
///-------------------------------

/**
 Tells the delegate that the mapper has found one or more mappable object representations at a key path specified in the `mappingsDictionary`.

 @param mapper The mapper operation performing the mapping.
 @param dictionaryOrArrayOfDictionaries The `NSDictictionary` or `NSArray` of `NSDictionary` object representations that was found at the `keyPath`.
 @param keyPath The key path that the representation was read from in the `representation`. If the `keyPath` was `[NSNull null]` in the `mappingsDictionary`, it will be given as `nil` to the delegate.
 */
- (void)mapper:(RKMapperOperation *)mapper didFindRepresentationOrArrayOfRepresentations:(id)dictionaryOrArrayOfDictionaries atKeyPath:(NSString *)keyPath;

/**
 Tells the delegate that the mapper failed to find any mappable object representations at a key path specified in the `mappingsDictionary`.

 @param mapper The mapper operation performing the mapping.
 @param keyPath The key path that was searched for a mappable object representation. 
 */
- (void)mapper:(RKMapperOperation *)mapper didNotFindRepresentationOrArrayOfRepresentationsAtKeyPath:(NSString *)keyPath;

///----------------------------------------------
/// @name Tracking Child Mapping Operation Status
///----------------------------------------------

/**
 Tells the delegate that the mapper is about to start a mapping operation to map a representation found in the `representation`.

 @param mapper The mapper operation performing the mapping.
 @param mappingOperation The mapping operation that is about to be started.
 @param keyPath The key path that was mapped. A `nil` key path indicates that the mapping matched the entire `representation`.
 */
- (void)mapper:(RKMapperOperation *)mapper willStartMappingOperation:(RKMappingOperation *)mappingOperation forKeyPath:(NSString *)keyPath;

/**
 Tells the delegate that a mapping operation that was started by the mapper has finished executing.

 @param mapper The mapper operation performing the mapping.
 @param mappingOperation The mapping operation that has finished.
 @param keyPath The key path that was mapped. A `nil` key path indicates that the mapping matched the entire `representation`.
 */
- (void)mapper:(RKMapperOperation *)mapper didFinishMappingOperation:(RKMappingOperation *)mappingOperation forKeyPath:(NSString *)keyPath;

/**
 Tells the delegate that a mapping operation that was started by the mapper has failed with an error.

 @param mapper The mapper operation performing the mapping.
 @param mappingOperation The mapping operation that has failed.
 @param keyPath The key path that was mapped. A `nil` key path indicates that the mapping matched the entire `representation`.
 @param error The error that occurred during the execution of the mapping operation.
 */
- (void)mapper:(RKMapperOperation *)mapper didFailMappingOperation:(RKMappingOperation *)mappingOperation forKeyPath:(NSString *)keyPath withError:(NSError *)error;

@end
