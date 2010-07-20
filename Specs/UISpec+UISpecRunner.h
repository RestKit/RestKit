//
//  UISpec+UISpecRunner.h
//  UISpecRunner
//
//  Created by Blake Watters on 7/15/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UISpec.h"

@interface UISpec (UISpecRunner)

/**
 * Run all UISpec classes conforming to a given protocol
 */
+(void)runSpecsConformingToProtocol:(Protocol *)protocol afterDelay:(NSTimeInterval)delay;

/**
 * Infers which set of UISpec classes to run from the following environment variables:
 * UISPEC_PROTOCOL - Specifies a protocol to run
 * UISPEC_SPEC - Specifies a spec class to run
 * UISPEC_METHOD - Specifies an example to run (requires UISPEC_SPEC to be set)
 */
+(void)runSpecsFromEnvironmentAfterDelay:(int)seconds;

@end
