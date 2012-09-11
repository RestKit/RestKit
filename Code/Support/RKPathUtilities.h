//
//  RKPathUtilities.h
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Returns the path to the Application Data directory for the executing application. On iOS, this is a sandboxed path specific for the executing application. On OS X, this is an application specific path under NSApplicationSupportDirectory (i.e. ~/Application Support).

 @return The full path to the application data directory.
 */
NSString * RKApplicationDataDirectory(void);

/**
 Returns a path to the root caches directory used by RestKit for storage. On iOS, this is a sanboxed path specific for the executing application. On OS X, this is an application specific path under NSCachesDirectory (i.e. ~/Library/Caches).

 @return The full path to the Caches directory.
 */
NSString * RKCachesDirectory(void);

/**
 Ensures that a directory exists at a given path by checking for the existence of the directory and creating it if it does not exist.

 @param path The path to ensure a directory exists at.
 @param error On input, a pointer to an error object.
 @returns A Boolean value indicating if the directory exists.
 */
BOOL RKEnsureDirectoryExistsAtPath(NSString *path, NSError **error);

/**
 Convenience method for generating a path against the properties of an object. Takes an `NSString` with property names prefixed with a colon and interpolates the values of the properties specified and returns the generated path.
 
 For example, given an `article` object with an `articleID` property whose value is `@12345`, `RKPathFromPatternWithObject(@"articles/:articleID", article)` would return `@"articles/12345"`.
 
 This functionality is the basis for path generation in the `RKRouter` class.
 
 @param pathPattern An `SOCPattern` string containing zero or more colon-prefixed property names.
 @param object The object to interpolate the properties against
 @return A new `NSString` object with the values of the given object interpolated for the colon-prefixed properties name in the given pattern string.
 @see RKPathMatcher
 @see SOCPattern
 */
NSString * RKPathFromPatternWithObject(NSString *pathPattern, id object);

/**
 Returns a MIME Type for a given path by using the Core Services framework.
 
 For example, given a string with the path `@"/Users/blake/Documents/monkey.json"` `@"application/json"` would be returned as the MIME Type.
 
 @return The expected MIME Type of the resource identified by the path or nil if unknown.
 */
NSString * RKMIMETypeFromPathExtension(NSString *path);
