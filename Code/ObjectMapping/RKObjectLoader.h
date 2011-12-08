//
//  RKObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters
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

@class RKObjectManager;
@class RKObjectLoader;

@protocol RKObjectLoaderDelegate <RKRequestDelegate>

@required

/**
 * Sent when an object loaded failed to load the collection due to an error
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error;

@optional

/**
 When implemented, sent to the delegate when the object laoder has completed successfully
 and loaded a collection of objects. All objects mapped from the remote payload will be returned
 as a single array.
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects;

/**
 When implemented, sent to the delegate when the object loader has completed succesfully. 
 If the load resulted in a collection of objects being mapped, only the first object
 in the collection will be sent with this delegate method. This method simplifies things
 when you know you are working with a single object reference.
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object;

/**
 When implemented, sent to the delegate when an object loader has completed successfully. The
 dictionary will be expressed as pairs of keyPaths and objects mapped from the payload. This
 method is useful when you have multiple root objects and want to differentiate them by keyPath.
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjectDictionary:(NSDictionary*)dictionary;

/**
 Invoked when the object loader has finished loading
 */
- (void)objectLoaderDidFinishLoading:(RKObjectLoader*)objectLoader;

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
- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader;

/**
 Invoked just after parsing has completed, but before object mapping begins. This can be helpful
 to extract data from the parsed payload that is not object mapped, but is interesting for one
 reason or another. The mappableData will be made mutable via mutableCopy before the delegate
 method is invoked.
 
 Note that the mappable data is a pointer to a pointer to allow you to replace the mappable data
 with a new object to be mapped. You must dereference it to access the value.
 */
- (void)objectLoader:(RKObjectLoader*)loader willMapData:(inout id *)mappableData;

@end

/**
 * Wraps a request/response cycle and loads a remote object representation into local domain objects
 *
 * NOTE: When Core Data is linked into the application, the object manager will return instances of
 * RKManagedObjectLoader instead of RKObjectLoader. RKManagedObjectLoader is a descendent class that 
 * includes Core Data specific mapping logic.
 */
@interface RKObjectLoader : RKRequest {	
    RKObjectManager* _objectManager;
    RKResponse* _response;
    RKObjectMapping* _objectMapping;
    RKObjectMappingResult* _result;
    RKObjectMapping* _serializationMapping;
    NSString* _serializationMIMEType;
    NSObject* _sourceObject;
	NSObject* _targetObject;
}

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
// TODO: Rename to responseMapping
@property (nonatomic, retain) RKObjectMapping* objectMapping;

/**
 * The object manager that initialized this loader. The object manager is responsible
 * for supplying the mapper and object store used after HTTP transport is completed
 */
@property (nonatomic, readonly) RKObjectManager* objectManager;

/**
 * The underlying response object for this loader
 */
@property (nonatomic, readonly) RKResponse* response;

/**
 * The mapping result that was produced after the request finished loading and
 * object mapping has completed. Provides access to the final products of the
 * object mapper in a variety of formats.
 */
@property (nonatomic, readonly) RKObjectMappingResult* result;

///////////////////////////////////////////////////////////////////////////////////////////
// Serialization

/**
 * The object mapping to use when serializing a target object for transport
 * to the remote server.
 *
 * @see RKObjectMappingProvider
 */
// TODO: Rename to requestMapping?
@property (nonatomic, retain) RKObjectMapping* serializationMapping;

/**
 * The MIME Type to serialize the targetObject into according to the mapping
 * rules in the serializationMapping. Typical MIME Types for serialization are
 * JSON (RKMIMETypeJSON) and URL Form Encoded (RKMIMETypeFormURLEncoded).
 *
 * @see RKMIMEType
 */
@property (nonatomic, retain) NSString* serializationMIMEType;

/**
 The object being serialized for transport. This object will be transformed into a
 serialization in the serializationMIMEType using the serializationMapping.
 
 @see RKObjectSerializer
 */
@property (nonatomic, retain) NSObject* sourceObject;

/**
 * The target object to map results back onto. If nil, a new object instance
 * for the appropriate mapping will be created. If not nil, the results will
 * be used to update the targetObject's attributes and relationships.
 */
@property (nonatomic, retain) NSObject* targetObject;

///////////////////////////////////////////////////////////////////////////////////////////

/**
 * Initialize and return an object loader for a resource path against an object manager. The resource path
 * specifies the remote location to load data from, while the object manager is responsible for supplying
 * mapping and persistence details.
 */
+ (id)loaderWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 * Initialize a new object loader with an object manager, a request, and a delegate
 */
- (id)initWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(id<RKObjectLoaderDelegate>)delegate;				

/**
 * Handle an error in the response preventing it from being mapped, called from -isResponseMappable
 */
- (void)handleResponseError;

@end
