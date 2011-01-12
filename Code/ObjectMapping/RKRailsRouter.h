//
//  RKRailsRouter.h
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKDynamicRouter.h"

/**
 * An implementation of the RKRouter protocol suitable for interacting
 * with a Ruby on Rails backend service. This router implementation extends
 * the normal dynamic router and provides support for encoding properties in
 * such a way that Rails controllers expect (i.e. model_name[attribute])
 */
@interface RKRailsRouter : RKDynamicRouter {
	NSMutableDictionary* _classToModelMappings;
}

/**
 * Registers the remote model name for a local domain class. This model name will
 * be used when serializing parameters before dispatching the request
 */
- (void)setModelName:(NSString*)modelName forClass:(Class<RKObjectMappable>)class;

@end
