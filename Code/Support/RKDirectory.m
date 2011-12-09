//
//  RKDirectory.m
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKDirectory.h"
#import "RKLog.h"

@implementation RKDirectory

+ (NSString *)executableName {
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    if (nil == executableName) {
        RKLogWarning(@"Unable to determine CFBundleExecutable: storing data under RestKit directory name.");
        executableName = @"RestKit";
    }
    
    return executableName;
}

+ (NSString *)applicationDataDirectory {
#if TARGET_OS_IPHONE
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if (basePath) {
        // In unit tests the Documents/ path may not exist
        if(! [[NSFileManager defaultManager] fileExistsAtPath:basePath]) {
            NSError* error = nil;
            
            if(! [[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:NO attributes:nil error:&error]) {
                NSLog(@"%@", error);
            }
        }
        
        return basePath;
    }
    
    return nil;
    
#else
    
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL* appSupportDir = nil;
    NSURL* appDirectory = nil;
    
    if ([possibleURLs count] >= 1) {
        appSupportDir = [possibleURLs objectAtIndex:0];
    }
    
    if (appSupportDir) {
        NSString *executableName = [RKDirectory executableName];
        appDirectory = [appSupportDir URLByAppendingPathComponent:executableName];
        
        
        if(![sharedFM fileExistsAtPath:[appDirectory path]]) {
            NSError* error = nil;
            
            if(![sharedFM createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
                NSLog(@"%@", error);
            }
        }
        return [appDirectory path];
    }
    
    return nil;
#endif
}

+ (NSString *)cachesDirectory {
#if TARGET_OS_IPHONE    
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
#else
    NSString *path = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count]) {
        path = [[paths objectAtIndex:0] stringByAppendingPathComponent:[RKDirectory executableName]];
    }
            
    return path;
#endif
}

@end
