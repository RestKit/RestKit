//
//  RKDirectoryUtilities.h
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Returns the path to the Application Data directory for the executing application. On iOS,
 this is a sandboxed path specific for the executing application. On OS X, this is an application
 specific path under NSApplicationSupportDirectory (i.e. ~/Application Support).
 
 @return The full path to the application data directory.
 */
NSString * RKApplicationDataDirectory(void);

/**
 Returns a path to the root caches directory used by RestKit for storage. On iOS, this is
 a sanboxed path specific for the executing application. On OS X, this is an application
 specific path under NSCachesDirectory (i.e. ~/Library/Caches).
 
 @return The full path to the Caches directory.
 */
NSString * RKCachesDirectory(void);

/**
 Ensures that a directory exists at a given path by checking for the existence
 of the directory and creating it if it does not exist.
 
 @param path The path to ensure a directory exists at.
 @param error On input, a pointer to an error object.
 @returns A Boolean value indicating if the directory exists.
 */
BOOL RKEnsureDirectoryExistsAtPath(NSString *path, NSError **error);
