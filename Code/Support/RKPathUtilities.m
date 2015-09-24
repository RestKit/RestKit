//
//  RKPathUtilities.m
//  RestKit
//
//  Created by Blake Watters on 12/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#import <UIKit/UIDevice.h>
#else
#import <CoreServices/CoreServices.h>
#endif
#import <Availability.h>
#import <RestKit/Support/RKLog.h>
#import <RestKit/Support/RKPathUtilities.h>
#import <sys/xattr.h>

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
    
    NSComparisonResult order = [[UIDevice currentDevice].systemVersion compare:@"5.1" options:NSNumericSearch];
    if (order == NSOrderedSame || order == NSOrderedDescending) {
        // On iOS >= 5.1, we can use the resource value API's. Note that we probe the iOS version number directly because the `setResourceValue:forKey:` symbol is defined in iOS 4.0 and greater, but performs no operation when invoked until iOS 5.1
        BOOL success = [URL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
        if (!success) {
            RKLogError(@"Failed to exclude item at path '%@' from Backup: %@", path, error);
        }
    } else {
        order = [[UIDevice currentDevice].systemVersion compare:@"5.0.1" options: NSNumericSearch];
        if (order == NSOrderedSame || order == NSOrderedDescending) {
            // On iOS 5.0.1 we must use the extended attribute API's directly
            const char* filePath = [[URL path] fileSystemRepresentation];
            const char* attrName = "com.apple.MobileBackup";
            u_int8_t attrValue = 1;
            
            int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
            if (result != 0) {
                RKLogError(@"Failed to exclude item at path '%@' from Backup. setxattr returned result code %d", path, result);
            }
        } else {
            RKLogWarning(@"Unable to exclude item from backup: resource value and extended attribute APIs are only available on iOS 5.0.1 and up");
        }
    }
#else
    RKLogDebug(@"Not built for iOS -- excluding path from Backup is not possible.");
#endif
}
