//
//  RKConfigurationDelegate.h
//  RestKit
//
//  Created by Blake Watters on 1/7/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

@class RKRequest, RKObjectLoader;

/**
 The RKConfigurationDelegate formal protocol defines
 methods enabling the centralization of RKRequest and
 RKObjectLoader configuration. An object conforming to
 the protocol can be used to set headers, authentication
 credentials, etc.

 RKClient and RKObjectManager conform to RKConfigurationDelegate
 to configure request and object loader instances they build.
 */
@protocol RKConfigurationDelegate <NSObject>

@optional

/**
 Configure a request before it is utilized

 @param request A request object being configured for dispatch
 */
- (void)configureRequest:(RKRequest *)request;

/**
 Configure an object loader before it is utilized

 @param request An object loader being configured for dispatch
 */
- (void)configureObjectLoader:(RKObjectLoader *)objectLoader;

@end
