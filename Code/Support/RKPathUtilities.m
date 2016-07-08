//
//  RKPathUtilities.m
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#import <UIKit/UIDevice.h>
#else
#import <CoreServices/CoreServices.h>
#endif
#import <Availability.h>
#import <sys/xattr.h>
#import "RKPathUtilities.h"
#import "RKLog.h"

NSString *RKExecutableName(void);

NSString *RKApplicationDataDirectory(void)
{
#if TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return ([paths count] > 0) ? paths[0] : nil;
#else
    NSFileManager *sharedFM = [NSFileManager defaultManager];

    NSArray *possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL *appSupportDir = nil;
    NSURL *appDirectory = nil;

    if ([possibleURLs count] >= 1) {
        appSupportDir = possibleURLs[0];
    }

    if (appSupportDir) {
        appDirectory = [appSupportDir URLByAppendingPathComponent:RKExecutableName()];
        return [appDirectory path];
    }

    return nil;
#endif
}

NSString *RKExecutableName(void)
{
    NSString *executableName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
    if (nil == executableName) {
        RKLogWarning(@"Unable to determine CFBundleExecutable: storing data under RestKit directory name.");
        executableName = @"RestKit";
    }

    return executableName;
}

NSString *RKCachesDirectory(void)
{
#if TARGET_OS_IPHONE
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
#else
    NSString *path = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count]) {
        path = [paths[0] stringByAppendingPathComponent:RKExecutableName()];
    }

    return path;
#endif
}

BOOL RKEnsureDirectoryExistsAtPath(NSString *path, NSError **error)
{
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (isDirectory) {
            // Exists at a path and is a directory, we're good
            if (error) *error = nil;
            return YES;
        }
    }

    // Create the directory and any intermediates
    NSError *errorReference = (error == nil) ? nil : *error;
    if (! [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&errorReference]) {
        RKLogError(@"Failed to create requested directory at path '%@': %@", path, errorReference);
        return NO;
    }

    return YES;
}

static NSDictionary *RKDictionaryOfFileExtensionsToMIMETypes()
{
    return @{ @"json": @"application/json" };
}

NSString *RKMIMETypeFromPathExtension(NSString *path)
{
    NSString *pathExtension = [path pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
    if (uti != NULL) {
        CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        CFRelease(uti);
        if (mime != NULL) {
            NSString *type = [NSString stringWithString:(__bridge NSString *)mime];
            CFRelease(mime);
            return type;
        }
    }

    // Consult our internal dictionary of mappings if not found
    return [RKDictionaryOfFileExtensionsToMIMETypes() valueForKey:pathExtension];
}

void RKSetExcludeFromBackupAttributeForItemAtPath(NSString *path)
{
    NSCParameterAssert(path);
    NSCAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"Cannot set Exclude from Backup attribute for non-existant item at path: '%@'", path);

#if __IPHONE_OS_VERSION_MIN_REQUIRED
    NSError *error = nil;
    NSURL *URL = [NSURL fileURLWithPath:path];
    
    BOOL success = [URL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (!success) {
        RKLogError(@"Failed to exclude item at path '%@' from Backup: %@", path, error);
    }
#else
    RKLogDebug(@"Not built for iOS -- excluding path from Backup is not possible.");
#endif
}
