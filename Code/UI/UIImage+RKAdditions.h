//
//  UIImage+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 2/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

/**
 Provides useful extensions to the UIImage interface.

 Resolution indepdence helpers borrowed from:
 http://atastypixel.com/blog/uiimage-resolution-independence-and-the-iphone-4s-retina-display/
 */
@interface UIImage (RKAdditions)

/**
 Creates and returns an image object by loading the image data from the file at the specified path
 appropriate for the resolution of the device.

 @param path The full or partial path to the file, possibly including an @2x retina image.
 @return A new image object for the specified file, or an image for the @2x version of the specified file,
 or nil if the method could not initialize the image from the specified file.
 */
+ (UIImage *)imageWithContentsOfResolutionIndependentFile:(NSString *)path;

/**
 Initializes an image object by loading the image data from the file at the specified path
 appropriate for the resolution of the device.

 @param path The full or partial path to the file, possibly including an @2x retina image.
 @return The initialized image object for the specified file, or for the @2x version of the specified file,
 or nil if the method could not initialize the image from the specified file.
 */
- (id)initWithContentsOfResolutionIndependentFile:(NSString *)path;

@end

#endif
