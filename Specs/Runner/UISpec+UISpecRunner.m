//
//  UISpec+UISpecRunner.m
//  UISpecRunner
//
//  Created by Blake Watters on 7/15/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "UISpec+UISpecRunner.h"
#import <objc/runtime.h>
#import "UIConsoleLog.h"
#import "UISpec.h"

@interface UISpecRunnerLog : UIConsoleLog {
    BOOL _exitOnFinish;
}

// When YES, the application will terminate after specs finish running
@property (nonatomic, assign) BOOL exitOnFinish;

@end

@implementation UISpecRunnerLog

@synthesize exitOnFinish = _exitOnFinish;

- (id)init {
    self = [super init];
    if (self) {
        _exitOnFinish = NO;
    }
    
    return self;
}

-(void)onFinish:(int)count {
    [super onFinish:count];
    
    if (self.exitOnFinish) {
        exit(errors.count);
    }
}

@end

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

+(NSArray*)specClassesInheritingFromClass:(Class)parentClass {
	int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
	
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray arrayWithObject:parentClass];
    for (NSInteger i = 0; i < numClasses; i++)
    {
        Class superClass = classes[i];
        do
        {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
        
        if (superClass == nil)
        {
            continue;
        }
        
		if ([self isASpec:classes[i]]) {
			[result addObject:classes[i]];
		}
    }
	
    free(classes);
    
    return result;
}

+(void)runSpecsInheritingFromClass:(Class)class afterDelay:(NSTimeInterval)delay {
	NSArray* specClasses = [self specClassesInheritingFromClass:class];
	NSLog(@"Executing Specs: %@", specClasses);
	[self performSelector:@selector(runSpecClasses:) withObject:specClasses afterDelay:delay];
}

+(void)runSpecsFromEnvironmentAfterDelay:(int)seconds {
	char* protocolName = getenv("UISPEC_PROTOCOL");
	char* specName = getenv("UISPEC_SPEC");
	char* exampleName = getenv("UISPEC_EXAMPLE");
    char* exitOnFinish = getenv("UISPEC_EXIT_ON_FINISH");
    
    UISpecRunnerLog* log = [[UISpecRunnerLog alloc] init];
    [UISpec setLog:(UILog*)log];
    
    if (NULL == exitOnFinish || [[NSString stringWithUTF8String:exitOnFinish] isEqualToString:@"YES"]) {
        log.exitOnFinish = YES;
    }
    
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
		NSLog(@"[UISpecRunner] Running Spec classes inheriting from %s", specName);
		Class class = NSClassFromString([NSString stringWithUTF8String:specName]);
		[UISpec runSpecsInheritingFromClass:class afterDelay:seconds];
	} else {
		[UISpec runSpecsAfterDelay:seconds];
	}
}

@end
