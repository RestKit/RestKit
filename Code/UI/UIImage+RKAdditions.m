//
//  UIImage+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 2/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "UIImage+RKAdditions.h"

#if TARGET_OS_IPHONE

@implementation UIImage (RKAdditions)

- (id)initWithContentsOfResolutionIndependentFile:(NSString *)path
{
    if ([[[UIDevice currentDevice] systemVersion] intValue] >= 4 && [[UIScreen mainScreen] scale] == 2.0) {
        NSString *path2x = [[path stringByDeletingLastPathComponent]
                            stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.%@",
                                                            [[path lastPathComponent] stringByDeletingPathExtension],
                                                            [path pathExtension]]];

        if ([[NSFileManager defaultManager] fileExistsAtPath:path2x]) {
            return [self initWithCGImage:[[UIImage imageWithData:[NSData dataWithContentsOfFile:path2x]] CGImage] scale:2.0 orientation:UIImageOrientationUp];
        }
    }

    return [self initWithData:[NSData dataWithContentsOfFile:path]];
}

+ (UIImage *)imageWithContentsOfResolutionIndependentFile:(NSString *)path
{
    return [[[UIImage alloc] initWithContentsOfResolutionIndependentFile:path] autorelease];
}

@end

#endif
