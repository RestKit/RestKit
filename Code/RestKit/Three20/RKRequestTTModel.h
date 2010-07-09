//
//  RKRequestTTModel.h
//  RestKit
//
//  Created by Blake Watters on 2/9/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import <RestKit/RestKit.h>
#import "RKRequestModel.h"

/**
 * Generic class for loading a remote model using a RestKit request and supplying the model to a 
 * TTListDataSource subclass
 */
@interface RKRequestTTModel : TTModel <RKRequestModelDelegate> {
	RKRequestModel* _model;
}

@property (nonatomic, readonly) RKRequestModel* model;

+ (id)modelWithResourcePath:(NSString*)resourcePath;
+ (id)modelWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params;
- (id)initWithResourcePath:(NSString*)resourcePath;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params;

- (NSArray*)objects;

@end
