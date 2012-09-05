//
//  RKNSJSONSerialization.h
//  RestKit
//
//  Created by Blake Watters on 8/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKSerialization.h"

/**
 An RKSerialization implementation providing serialization and 
 deserialization of the JSON format using the Apple provided
 NSJSONSerialization class. This is the default JSON implementation
 for RestKit.
 */
@interface RKNSJSONSerialization : NSObject <RKSerialization>
@end
