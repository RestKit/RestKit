//
//  RKResponseSerialization.h
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFURLResponseSerialization.h"
#import "RKResponseDescriptor.h"

@class RKObjectResponseSerializer;

/**
 The `RKResponseSerializationManager` class is responsible for constructing AFNetworking response serializer instances that perform object mapping on object representations loaded via HTTP.
 */
@interface RKResponseSerializationManager : NSObject <NSCoding, NSCopying>

///------------------------------------------------
/// @name Creating a Response Serialization Manager
///------------------------------------------------

// NOTE: The response data serializer should be configured to accept any status codes that you wish to map...
/**
 Creates and returns a response serialization manager with the given response data serializer.

 @param dataSerializer An `AFHTTPResponseSerializer` object to use for deserializing the response data into an object mappable representation. Cannot be `nil`.
 @return A newly created response serialization manager.
 */
+ (instancetype)managerWithTransportSerializer:(AFHTTPResponseSerializer *)transportSerializer;

/**
 The serializer responsible for deserializing the response data from the transport format into a Foundation representation that is suitable for object mapping.

 The transport serializer is typically tightly coupled to the Content-Type of the response. For example, when handling JSON responses with the `application/json` Content-Type the data serializer would be an instance of `AFJSONResponseSerializer`.
 */
@property (nonatomic, strong, readonly) AFHTTPResponseSerializer *transportSerializer;

///------------------------------------------------
/// @name Managing Response Descriptors
///------------------------------------------------

/**
 Returns an array containing the `RKResponseDescriptor` objects added to the manager.

 @return An array containing the request descriptors of the receiver. The elements of the array are instances of `RKRequestDescriptor`.

 @see RKResponseDescriptor
 */
@property (nonatomic, readonly) NSArray *responseDescriptors;

/**
 Adds a response descriptor to the manager.

 Adding a response descriptor to the manager sets the `baseURL` of the descriptor to the `baseURL` of the manager, causing it to evaluate URL objects relatively.

 @param responseDescriptor The response descriptor object to the be added to the manager.
 */
- (void)addResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

/**
 Adds the `RKResponseDescriptor` objects contained in a given array to the manager.

 @param responseDescriptors An array of `RKResponseDescriptor` objects to be added to the manager.
 @exception NSInvalidArgumentException Raised if any element of the given array is not an `RKResponseDescriptor` object.
 */
- (void)addResponseDescriptors:(NSArray *)responseDescriptors;

/**
 Removes a given response descriptor from the manager.

 @param responseDescriptor An `RKResponseDescriptor` object to be removed from the manager.
 */
- (void)removeResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

// Creates and returns a response serializer to be used to process the given request and object
// object can be `nil`
- (RKObjectResponseSerializer *)serializerWithRequest:(NSURLRequest *)request object:(id)object;

@end

/**
 The `RKObjectResponseSerializer` is a subclass of `AFHTTPResponseSerializer` that performs object mapping on object representations loaded over HTTP by AFNetworking.
 */
@interface RKObjectResponseSerializer : AFHTTPResponseSerializer

- (id)initWithRequest:(NSURLRequest *)request transportSerializer:(AFHTTPResponseSerializer *)transportSerializer responseDescriptors:(NSArray *)responseDescriptors;

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong, readonly) NSURLRequest *request;
@property (nonatomic, strong, readonly) AFHTTPResponseSerializer *transportSerializer;
@property (nonatomic, copy, readonly) NSArray *responseDescriptors;

/**
 The target object for the object mapping operation.

 @see `[RKObjectResponseMapperOperation targetObject]`
 */
@property (nonatomic, strong) id targetObject;

/**
 An optional dictionary of metadata to make available to mapping operations executed while processing the HTTP response loaded by the receiver.
 */
@property (nonatomic, copy) NSDictionary *mappingMetadata;

@end

// TODO: Conditional compilation based on Core Data???
@interface RKManagedObjectResponseSerializer : RKObjectResponseSerializer

// TODO: managed object context, etc.

@end
