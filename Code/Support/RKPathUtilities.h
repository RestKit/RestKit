//
//  RKPathUtilities.h
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 Returns the path to the Application Data directory for the executing application. On iOS, this is a sandboxed path specific for the executing application. On OS X, this is an application specific path under `NSApplicationSupportDirectory` (i.e. ~/Application Support).

 @return The full path to the application data directory.
 */
NSString *RKApplicationDataDirectory(void);

/**
 Returns a path to the root caches directory used by RestKit for storage. On iOS, this is a sanboxed path specific for the executing application. On OS X, this is an application specific path under NSCachesDirectory (i.e. ~/Library/Caches).

 @return The full path to the Caches directory.
 */
NSString *RKCachesDirectory(void);

/**
 Ensures that a directory exists at a given path by checking for the existence of the directory and creating it if it does not exist.

 @param path The path to ensure a directory exists at.
 @param error On input, a pointer to an error object.
 @returns A Boolean value indicating if the directory exists.
 */
BOOL RKEnsureDirectoryExistsAtPath(NSString *path, NSError **error);

/**
 Returns a MIME Type for a given path by using the Core Services framework.
 
 For example, given a string with the path `@"/Users/blake/Documents/monkey.json"` `@"application/json"` would be returned as the MIME Type.
 
 @param path The path to return the MIME Type for.
 @return The expected MIME Type of the resource identified by the path or nil if unknown.
 */
NSString *RKMIMETypeFromPathExtension(NSString *path);

/**
 Excludes the item at a given path from backup via iTunes and/or iCloud using the approaches detailed in "Apple Technical Q&A QA1719".
 
 Excluding a path from backup can be necessary in order to conform to the iCloud Data Storage Guidelines. Please refer to the following links for more details:
 
 1. [iCloud Data Storage Guidelines](https://developer.apple.com/icloud/documentation/data-storage/)
 1. [Technical Q&A QA1719](http://developer.apple.com/library/ios/#qa/qa1719/_index.html)
 
 @param path The path to the item that is to be excluded from backup.
 */
void RKSetExcludeFromBackupAttributeForItemAtPath(NSString *path);

#ifdef __cplusplus
}
#endif
