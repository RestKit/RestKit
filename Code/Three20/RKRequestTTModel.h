//
//  RKRequestTTModel.h
//  RestKit
//
//  Created by Blake Watters on 2/9/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "RKRequestModel.h"

/**
 * Generic class for loading a remote model using a RestKit request and supplying the model to a 
 * TTListDataSource subclass
 */
@interface RKRequestTTModel : TTModel <RKRequestModelDelegate> {
	RKRequestModel* _model;
}

@property (nonatomic, readonly) RKRequestModel* model;

- (id)initWithResourcePath:(NSString*)resourcePath;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass keyPath:(NSString*)keyPath;

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params method:(RKRequestMethod)method;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params method:(RKRequestMethod)method objectClass:(Class)klass;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params method:(RKRequestMethod)method objectClass:(Class)klass keyPath:(NSString*)keyPath;

- (NSArray*)objects;

@end
