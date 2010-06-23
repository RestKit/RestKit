//
//  RKModelLoader.h
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKRequest.h"
#import "RKResponse.h"
#import "RKModelMapper.h"

@protocol RKModelLoaderDelegate <RKRequestDelegate>

/**
 * Invoked when a request sent through the model manager loads a collection of models. The model will be nil if the request was
 * not dispatched with a model object instance
 */
- (void)modelLoaderRequest:(RKRequest*)request didLoadModels:(NSArray*)models response:(RKResponse*)response modelObject:(id<RKModelMappable>)modelObject;

/**
 * Invoked when a request sent through the model manager encounters an error. The model will be nil if the request was
 * not dispatched with a model object instance
 */
- (void)modelLoaderRequest:(RKRequest*)request didFailWithError:(NSError*)error response:(RKResponse*)response modelObject:(id<RKModelMappable>)modelObject;

@end

@interface RKModelLoader : NSObject <RKRequestDelegate> {
	RKModelMapper* _mapper;
	NSObject<RKModelLoaderDelegate>* _delegate;
	SEL _callback;
}

/**
 * The model mapper this loader is working with
 */
@property (nonatomic, readonly) RKModelMapper* mapper;

/**
 * The object to be invoked with the loaded models
 *
 * If this object implements life-cycle methods from the RKRequestDelegate protocol, 
 * events from the request will be forwarded back.
 */
@property (nonatomic, retain) NSObject<RKModelLoaderDelegate>* delegate;

/**
 * The method to invoke to trigger model mappings. Used as the callback for a restful model mapping request
 */
@property (nonatomic, readonly) SEL callback;

+ (id)loaderWithMapper:(RKModelMapper*)mapper;

/**
 * Initialize a new model loader with a model mapper
 */
- (id)initWithMapper:(RKModelMapper*)mapper;

@end
