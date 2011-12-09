//
//  RKDirectory.h
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 iOS and OS X agnostic accessors for safely returning directory paths for use 
 by the framework and applications.
 */
@interface RKDirectory : NSObject

/**
 Returns the path to the Application Data directory for the executing application. On iOS,
 this is a sandboxed path specific for the executing application. On OS X, this is an application
 specific path under NSApplicationSupportDirectory (i.e. ~/Application Support).
 */
+ (NSString *)applicationDataDirectory;

/**
 Returns a path to the root caches directory used by RestKit for storage. On iOS, this is
 
 */
+ (NSString *)cachesDirectory;

@end
