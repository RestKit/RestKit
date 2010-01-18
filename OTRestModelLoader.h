//
//  OTRestModelLoader.h
//  OTRestFramework
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRestModelMapper.h"

@class OTRestRequest;
@class OTRestResponse;

@protocol OTRestModelLoaderDelegate

/**
 * Invoked when a request sent through the model manager encounters an error. The model will be nil if the request was
 * not dispatched with a model object instance
 */
- (void)modelLoaderRequest:(OTRestRequest*)request didFailWithError:(NSError*)error response:(OTRestResponse*)response model:(id<OTRestModelMappable>)model;

/**
 * Invoked when a request sent through the model manager returns an error message from the server. 
 */
- (void)modelLoaderRequest:(OTRestRequest*)request didReturnErrorMessage:(NSString*)errorMessage response:(OTRestResponse*)response model:(id<OTRestModelMappable>)model;

@end

@interface OTRestModelLoader : NSObject {
	OTRestModelMapper* _mapper;
	NSObject<OTRestModelLoaderDelegate>* _delegate;
	SEL _callback;
}

/**
 * The model mapper this loader is working with
 */
@property (nonatomic, readonly) OTRestModelMapper* mapper;

/**
 * The object to be invoked with the loaded models
 */
@property (nonatomic, retain) id delegate;

/**
 * The method to invoke after loading the models
 */
@property (nonatomic, assign) SEL callback;

/**
 * The method to invoke to trigger model mappings. Used as the callback for a restful model mapping request
 */
@property (nonatomic, readonly) SEL memberCallback;

/**
 * The method to invoke to trigger model mappings. Used as the callback for a restful model mapping request
 */
@property (nonatomic, readonly) SEL collectionCallback;


/**
 * Initialize a new model loader with a model mapper
 */
- (id)initWithMapper:(OTRestModelMapper*)mapper;

@end
