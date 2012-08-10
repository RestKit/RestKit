//
//  RKObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
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

#import "Network.h"
#import "RKObjectMapping.h"
#import "RKObjectMappingResult.h"
#import "RKObjectMappingProvider.h"

@class RKObjectMappingProvider;
@class RKObjectLoader;

// Block Types
typedef void(^RKObjectLoaderBlock)(RKObjectLoader *loader);
typedef void(^RKObjectLoaderDidFailWithErrorBlock)(NSError *error);
typedef void(^RKObjectLoaderDidLoadObjectsBlock)(NSArray *objects);
typedef void(^RKObjectLoaderDidLoadObjectBlock)(id object);
typedef void(^RKObjectLoaderDidLoadObjectsDictionaryBlock)(NSDictionary *dictionary);

/**
 The delegate of an RKObjectLoader object must adopt the RKObjectLoaderDelegate protocol. Optional
 methods of the protocol allow the delegate to handle asynchronous object mapping operations performed
 by the object loader. Also note that the RKObjectLoaderDelegate protocol incorporates the
 RKRequestDelegate protocol and the delegate may provide implementations of methods from RKRequestDelegate
 as well.

 @see RKRequestDelegate
 */
@protocol RKObjectLoaderDelegate <RKRequestDelegate>

@required

/**
 * Sent when an object loaded failed to load the collection due to an error
 */
- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error;

@optional

/**
 When implemented, sent to the delegate when the object laoder has completed successfully
 and loaded a collection of objects. All objects mapped from the remote payload will be returned
 as a single array.
 */
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects;

/**
 When implemented, sent to the delegate when the object loader has completed succesfully.
 If the load resulted in a collection of objects being mapped, only the first object
 in the collection will be sent with this delegate method. This method simplifies things
 when you know you are working with a single object reference.
 */
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object;

/**
 When implemented, sent to the delegate when an object loader has completed successfully. The
 dictionary will be expressed as pairs of keyPaths and objects mapped from the payload. This
 method is useful when you have multiple root objects and want to differentiate them by keyPath.
 */
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjectDictionary:(NSDictionary *)dictionary;

/**
 Invoked when the object loader has finished loading
 */
- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader;

/**
 Informs the delegate that the object loader has serialized the source object into a serializable representation
 for sending to the remote system. The serialization can be modified to allow customization of the request payload independent of mapping.

 @param objectLoader The object loader performing the serialization.
 @param sourceObject The object that was serialized.
 @param serialization The serialization of sourceObject to be sent to the remote backend for processing.
 */
- (void)objectLoader:(RKObjectLoader *)objectLoader didSerializeSourceObject:(id)sourceObject toSerialization:(inout id<RKRequestSerializable> *)serialization;

/**
 Sent when an object loader encounters a response status code or MIME Type that RestKit does not know how to handle.

 Response codes in the 2xx, 4xx, and 5xx range are all handled as you would expect. 2xx (successful) response codes
 are considered a successful content load and object mapping will be attempted. 4xx and 5xx are interpretted as
 errors and RestKit will attempt to object map an error out of the payload (provided the MIME Type is mappable)
 and will invoke objectLoader:didFailWithError: after constructing an NSError. Any other status code is considered
 unexpected and will cause objectLoaderDidLoadUnexpectedResponse: to be invoked provided that you have provided
 an implementation in your delegate class.

 RestKit will also invoke objectLoaderDidLoadUnexpectedResponse: in the event that content is loaded, but there
 is not a parser registered to handle the MIME Type of the payload. This often happens when the remote backend
 system RestKit is talking to generates an HTML error page on failure. If your remote system returns content
 in a MIME Type other than application/json or application/xml, you must register the MIME Type and an appropriate
 parser with the [RKParserRegistry sharedParser] instance.

 Also note that in the event RestKit encounters an unexpected status code or MIME Type response an error will be
 constructed and sent to the delegate via objectLoader:didFailsWithError: unless your delegate provides an
 implementation of objectLoaderDidLoadUnexpectedResponse:. It is recommended that you provide an implementation
 and attempt to handle common unexpected MIME types (particularly text/html and text/plain).

 @optional
 */
- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader;

/**
 Invoked just after parsing has completed, but before object mapping begins. This can be helpful
 to extract data from the parsed payload that is not object mapped, but is interesting for one
 reason or another. The mappableData will be made mutable via mutableCopy before the delegate
 method is invoked.

 Note that the mappable data is a pointer to a pointer to allow you to replace the mappable data
 with a new object to be mapped. You must dereference it to access the value.
 */
- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData;

@end

/**
 * Wraps a request/response cycle and loads a remote object representation into local domain objects
 *
 * NOTE: When Core Data is linked into the application, the object manager will return instances of
 * RKManagedObjectLoader instead of RKObjectLoader. RKManagedObjectLoader is a descendent class that
 * includes Core Data specific mapping logic.
 */
@interface RKObjectLoader : RKRequest {
    NSObject* _targetObject;
}

/**
 The object that acts as the delegate of the receiving object loader.

 @see RKRequestDelegate
 */
@property (nonatomic, assign) id<RKObjectLoaderDelegate> delegate;

/**
 The block to invoke when the object loader fails due to an error.

 @see [RKObjectLoaderDelegate objectLoader:didFailWithError:]
 */
@property (nonatomic, copy) RKObjectLoaderDidFailWithErrorBlock onDidFailWithError;

/**
 The block to invoke when the object loader has completed object mapping and the consumer
 wishes to retrieve a single object from the mapping result.

 @see [RKObjectLoaderDelegate objectLoader:didLoadObject:]
 @see RKObjectMappingResult
 */
@property (nonatomic, copy) RKObjectLoaderDidLoadObjectBlock onDidLoadObject;

/**
 The block to invoke when the object loader has completed object mapping and the consumer
 wishes to retrieve an collections of objects from the mapping result.

 @see [RKObjectLoaderDelegate objectLoader:didLoadObjects:]
 @see RKObjectMappingResult
 */
@property (nonatomic, copy) RKObjectLoaderDidLoadObjectsBlock onDidLoadObjects;

/**
 The block to invoke when the object loader has completed object mapping and the consumer
 wishes to retrieve the entire mapping result as a dictionary. Each key within the
 dictionary will correspond to a mapped keyPath within the source JSON/XML and the value
 will be the object mapped result.

 @see [RKObjectLoaderDelegate objectLoader:didLoadObjects:]
 @see RKObjectMappingResult
 */
@property (nonatomic, copy) RKObjectLoaderDidLoadObjectsDictionaryBlock onDidLoadObjectsDictionary;

/**
 * The object mapping to use when processing the response. If this is nil,
 * then RestKit will search the parsed response body for mappable keyPaths and
 * perform mapping on all available content. For instances where your target JSON
 * is not returned under a uniquely identifiable keyPath, you must specify the object
 * mapping directly for RestKit to know how to map it.
 *
 * @default nil
 * @see RKObjectMappingProvider
 */
@property (nonatomic, retain) RKObjectMapping *objectMapping;

/**
 A mapping provider containing object mapping configurations for mapping remote
 object representations into local domain objects.

 @see RKObjectMappingProvider
 */
@property (nonatomic, retain) RKObjectMappingProvider *mappingProvider;

/**
 * The underlying response object for this loader
 */
@property (nonatomic, retain, readonly) RKResponse *response;

/**
 * The mapping result that was produced after the request finished loading and
 * object mapping has completed. Provides access to the final products of the
 * object mapper in a variety of formats.
 */
@property (nonatomic, readonly) RKObjectMappingResult *result;

///////////////////////////////////////////////////////////////////////////////////////////
// Serialization

/**
 * The object mapping to use when serializing a target object for transport
 * to the remote server.
 *
 * @see RKObjectMappingProvider
 */
@property (nonatomic, retain) RKObjectMapping *serializationMapping;

/**
 * The MIME Type to serialize the targetObject into according to the mapping
 * rules in the serializationMapping. Typical MIME Types for serialization are
 * JSON (RKMIMETypeJSON) and URL Form Encoded (RKMIMETypeFormURLEncoded).
 *
 * @see RKMIMEType
 */
@property (nonatomic, retain) NSString *serializationMIMEType;

/**
 The object being serialized for transport. This object will be transformed into a
 serialization in the serializationMIMEType using the serializationMapping.

 @see RKObjectSerializer
 */
@property (nonatomic, retain) NSObject *sourceObject;

/**
 * The target object to map results back onto. If nil, a new object instance
 * for the appropriate mapping will be created. If not nil, the results will
 * be used to update the targetObject's attributes and relationships.
 */
@property (nonatomic, retain) NSObject *targetObject;

/**
 The Grand Central Dispatch queue to perform our parsing and object mapping
 within. By default, object loaders will use the mappingQueue from the RKObjectManager
 that created the loader. You can override this on a per-loader basis as necessary.
 */
@property (nonatomic, assign) dispatch_queue_t mappingQueue;

///////////////////////////////////////////////////////////////////////////////////////////

/**
 Initialize and return an autoreleased object loader targeting a remote URL using a mapping provider

 @param URL A RestKit RKURL targetting a particular baseURL and resourcePath
 @param mappingProvider A mapping provider containing object mapping configurations for processing loaded payloads
 */
+ (id)loaderWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider;

/**
 Initialize and return an autoreleased object loader targeting a remote URL using a mapping provider

 @param URL A RestKit RKURL targetting a particular baseURL and resourcePath
 @param mappingProvider A mapping provider containing object mapping configurations for processing loaded payloads
 */
- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider;

/**
 * Handle an error in the response preventing it from being mapped, called from -isResponseMappable
 */
- (void)handleResponseError;

@end

@class RKObjectManager;
@interface RKObjectLoader (Deprecations)
+ (id)loaderWithResourcePath:(NSString *)resourcePath objectManager:(RKObjectManager *)objectManager delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;
- (id)initWithResourcePath:(NSString *)resourcePath objectManager:(RKObjectManager *)objectManager delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;
@end
