//
//  RKObjectResponseSerializer.h
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFURLResponseSerialization.h"
#import "RKResponseDescriptor.h"

@interface RKObjectResponseSerializer : AFHTTPResponseSerializer

@property (nonatomic, strong) NSURL *baseURL;

// Used to deserialize the response content
// TODO: Should this just be against the RKMIMETypeSerialization???
@property (nonatomic, strong) id<AFURLResponseSerialization> contentResponseSerializer;

/**
 The target object for the object mapping operation.

 @see `[RKObjectResponseMapperOperation targetObject]`
 */
@property (nonatomic, strong) id targetObject;

/**
 An optional dictionary of metadata to make available to mapping operations executed while processing the HTTP response loaded by the receiver.
 */
@property (nonatomic, copy) NSDictionary *mappingMetadata;

/**
 Returns an array containing the `RKResponseDescriptor` objects added to the serializer.

 @return An array containing the request descriptors of the receiver. The elements of the array are instances of `RKRequestDescriptor`.

 @see RKResponseDescriptor
 */
@property (nonatomic, readonly) NSArray *responseDescriptors;

/**
 Adds a response descriptor to the serializer.

 Adding a response descriptor to the manager sets the `baseURL` of the descriptor to the `baseURL` of the manager, causing it to evaluate URL objects relatively.

 @param responseDescriptor The response descriptor object to the be added to the serializer.
 */
- (void)addResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

/**
 Adds the `RKResponseDescriptor` objects contained in a given array to the manager.

 @param responseDescriptors An array of `RKResponseDescriptor` objects to be added to the manager.
 @exception NSInvalidArgumentException Raised if any element of the given array is not an `RKResponseDescriptor` object.
 */
- (void)addResponseDescriptorsFromArray:(NSArray *)responseDescriptors;

/**
 Removes a given response descriptor from the manager.

 @param responseDescriptor An `RKResponseDescriptor` object to be removed from the serializer.
 */
- (void)removeResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

@end
