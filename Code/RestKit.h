//
//  RestKit.h
//  RestKit
//
//  Created by Blake Watters on 2/19/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "Network/Network.h"
#import "Support/Support.h"
#import "ObjectMapping/ObjectMapping.h"

/**
 Set the App logging component. This header
 file is generally only imported by apps that
 are pulling in all of RestKit. By setting the 
 log component to App here, we allow the app developer
 to use RKLog() in their own app.
 */
#undef RKLogComponent
#define RKLogComponent lcl_cApp
