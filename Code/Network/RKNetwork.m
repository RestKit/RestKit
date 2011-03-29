//
//  MyClass.m
//  RestKit
//
//  Created by Blake Watters on 3/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKNetwork.h"

// Global credential persistence value.
static NSURLCredentialPersistence gCredentialPersistence = NSURLCredentialPersistenceForSession;

NSURLCredentialPersistence RKNetworkGetGlobalCredentialPersistence() {
    return gCredentialPersistence;
}

void RKNetworkSetGlobalCredentialPersistence(NSURLCredentialPersistence persistence) {
    gCredentialPersistence = persistence;
}
