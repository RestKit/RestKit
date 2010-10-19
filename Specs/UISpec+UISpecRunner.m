//
//  UISpec+UISpecRunner.m
//  UISpecRunner
//
//  Created by Blake Watters on 7/15/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <objc/runtime.h>
#import "UISpec+UISpecRunner.h"

@interface UISpec ()

/**
 * Returns YES when a class implement the UISpec protocol
 */
+(BOOL)isASpec:(Class)class;

@end

@implementation UISpec (UISpecRunner)

+(BOOL)class:(Class)class conformsToProtocol:(Protocol *)protocol {
	while (class) {
		if (class_conformsToProtocol(class, protocol)) {
			return YES;
		}
		class = class_getSuperclass(class);
	}
	return NO;
}

+(NSArray*)specClassesConformingToProtocol:(Protocol *)protocol {
	NSMutableArray *array = [NSMutableArray array];
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        Class *classes = malloc(sizeof(Class) * numClasses);
        (void) objc_getClassList (classes, numClasses);
        int i;
        for (i = 0; i < numClasses; i++) {
            Class c = classes[i];
			if ([self isASpec:c] && [self class:c conformsToProtocol:protocol]) {
				[array addObject:c];
			}
        }
        free(classes);
    }
	return array;
}

+(void)runSpecsConformingToProtocol:(Protocol *)protocol afterDelay:(NSTimeInterval)delay {
	NSArray* specClasses = [self specClassesConformingToProtocol:protocol];
	[self performSelector:@selector(runSpecClasses:) withObject:specClasses afterDelay:delay];
}

+(void)runSpecsFromEnvironmentAfterDelay:(int)seconds {
	char* protocolName = getenv("UISPEC_PROTOCOL");
	char* specName = getenv("UISPEC_SPEC");
	char* exampleName = getenv("UISPEC_EXAMPLE");
	if (protocolName) {
		Protocol* protocol = NSProtocolFromString([NSString stringWithUTF8String:protocolName]);
		NSLog(@"[UISpecRunner] Running Specs conforming to Protocol: %@", [NSString stringWithUTF8String:protocolName]);
		[UISpec runSpecsConformingToProtocol:protocol afterDelay:seconds];
	} else if (exampleName) {
		if (nil == specName) {
			[NSException raise:nil format:@"UISPEC_EXAMPLE cannot be specified without providing UISPEC_SPEC"];
		}
		NSLog(@"[UISpecRunner] Running Examples %s on Spec %s", exampleName, specName);
		[UISpec runSpec:[NSString stringWithUTF8String:specName] example:[NSString stringWithUTF8String:exampleName] afterDelay:seconds];
	} else if (specName) {
		NSLog(@"[UISpecRunner] Running Spec %s", specName);
		[UISpec runSpec:[NSString stringWithUTF8String:specName] afterDelay:seconds];
	} else {
		[UISpec runSpecsAfterDelay:seconds];
	}	
}

@end
