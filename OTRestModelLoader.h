//
//  OTRestModelLoader.h
//  OTRestFramework
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRestModelMapper.h"

@interface OTRestModelLoader : NSObject {
	OTRestModelMapper* _mapper;
	id _delegate;
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
