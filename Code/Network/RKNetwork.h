//
//  RKNetwork.h
//  RestKit
//
//  Created by Blake Watters on 3/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Returns the global value for credential persistence to use during HTTP AUTH
 * Defaults to NSURLCredentialPersistenceForSession
 */
NSURLCredentialPersistence RKNetworkGetGlobalCredentialPersistence();

/**
 * Set the global value for credential persistence to use during HTTP AUTH
 */
void RKNetworkSetGlobalCredentialPersistence(NSURLCredentialPersistence persistence);