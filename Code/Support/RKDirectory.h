//
//  RKDirectory.h
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

 @return The full path to the application data directory.
 */
+ (NSString *)applicationDataDirectory;

/**
 Returns a path to the root caches directory used by RestKit for storage. On iOS, this is
 a sanboxed path specific for the executing application. On OS X, this is an application
 specific path under NSCachesDirectory (i.e. ~/Library/Caches).

 @return The full path to the Caches directory.
 */
+ (NSString *)cachesDirectory;

/**
 Ensures that a directory exists at a given path by checking for the existence
 of the directory and creating it if it does not exist.

 @param path The path to ensure a directory exists at.
 @param error On input, a pointer to an error object.
 @returns A Boolean value indicating if the directory exists.
 */
+ (BOOL)ensureDirectoryExistsAtPath:(NSString *)path error:(NSError **)error;

@end
