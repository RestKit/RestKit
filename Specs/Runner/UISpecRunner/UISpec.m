#import "UISpec.h"
#import "objc/runtime.h"
#import "UIConsoleLog.h"

@implementation UISpec

static UILog *logger = nil;

+(void)initialize {
	logger = [[UIConsoleLog alloc] init];
}

+(void)setLog:(UILog *)log{
	[logger release];
	logger = [log retain];
}

+(void)runSpecsAfterDelay:(int)seconds {
	[NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(runSpecs) userInfo:nil repeats:NO];
}

+(void)runSpec:(NSString *)specName afterDelay:(int)seconds {
	[NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(runSpec:) userInfo:specName repeats:NO];
}

+(void)runSpec:(NSString *)specName example:(NSString *)exampleName afterDelay:(int)seconds {
	[NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(runSpecExample:) userInfo:[NSArray arrayWithObjects:specName, exampleName, nil] repeats:NO];
}

+(void)runSpecs {
	NSArray *specClasses = [self specClasses];
	[self runSpecClasses:specClasses];
}

+(void)runSpec:(NSTimer *)timer {
	Class *class = NSClassFromString(timer.userInfo);
	[self runSpecClasses:[NSArray arrayWithObject:class]];
}

+(void)runSpecExample:(NSTimer *)timer {
	Class *class = NSClassFromString([timer.userInfo objectAtIndex:0]);
	NSString *exampleName = [timer.userInfo objectAtIndex:1];
	[logger onStart];
	[self runExamples:[NSArray arrayWithObject:exampleName] onSpec:class];
	[logger onFinish:1];
}

+(void)runSpecClasses:(NSArray *)specClasses {
	if (specClasses.count == 0) return;
	int examplesCount = 0;
	[logger onStart];
	for (Class class in specClasses) {
		NSArray *examples = [self examplesForSpecClass:class];
		if (examples.count == 0) continue;
		examplesCount = examplesCount + examples.count;
		[self runExamples:examples onSpec:class];
	}
	[logger onFinish:examplesCount];
}

+(void)runExamples:(NSArray *)examples onSpec:(Class *)class {
	UISpec *spec = [[[class alloc] init] autorelease];
	[logger onSpec:spec];
	if ([spec respondsToSelector:@selector(beforeAll)]) {
		@try {
			[logger onBeforeAll];
			[spec beforeAll];
		} @catch (NSException *exception) {
			[logger onBeforeAllException:exception];
		}
	}
	for (NSString *exampleName in [examples reverseObjectEnumerator]) {
		if ([spec respondsToSelector:@selector(before)]) {
			@try {
				[logger onBefore:exampleName];
				[spec before];
			} @catch (NSException *exception) {
				[logger onBeforeException:exception];
			}
		}
		@try {
			[logger onExample:exampleName];
			[spec performSelector:NSSelectorFromString(exampleName)];
		} @catch (NSException *exception) {
			[logger onExampleException:exception];
		}
		if ([spec respondsToSelector:@selector(after)]) {
			@try {
				[logger onAfter:exampleName];
				[spec after];
			} @catch (NSException *exception) {
				[logger onAfterException:exception];
			}
		}
	}
	if ([spec respondsToSelector:@selector(afterAll)]) {
		@try {
			[logger onAfterAll];
			[spec afterAll];
		} @catch (NSException *exception) {
			[logger onAfterAllException:exception];
		}
	}
	[logger afterSpec:spec];
}

+(NSDictionary *)specsAndExamples {
	NSArray *specClasses = [self specClasses];
	NSMutableDictionary *specsAndExamples = [NSMutableDictionary dictionaryWithCapacity:[specClasses count]];
	for (Class specClass in specClasses) {
		NSArray *examples = [self examplesForSpecClass:specClass];
		if ([examples count]) {
			[specsAndExamples addObject:examples forKey:NSStringFromClass(specClass)];
		}
	}
	return specsAndExamples;
}

+(NSArray *)examplesForSpecClass:(Class *)specClass {
	NSMutableArray *array = [NSMutableArray array];
	unsigned int methodCount;
	Method *methods = class_copyMethodList(specClass, &methodCount);
	for (size_t i = 0; i < methodCount; ++i) {
		Method method = methods[i];
		SEL selector = method_getName(method);
		NSString *selectorName = NSStringFromSelector(selector);
		if ([selectorName hasPrefix:@"it"]) {
			[array addObject:selectorName];
		}
	}
	return array;
}

+(BOOL)isASpec:(Class)class {
	//Class spec = NSClassFromString(@"UISpec");
	while (class) {
		if (class_conformsToProtocol(class, NSProtocolFromString(@"UISpec"))) {
			return YES;
		}
		class = class_getSuperclass(class);
	}
	return NO;
}

+(NSArray*)specClasses {
	NSMutableArray *array = [NSMutableArray array];
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        Class *classes = malloc(sizeof(Class) * numClasses);
        (void) objc_getClassList (classes, numClasses);
        int i;
        for (i = 0; i < numClasses; i++) {
            Class *c = classes[i];
			if ([self isASpec:c]) {
				[array addObject:c];
			}
        }
        free(classes);
    }
	return array;
}

+(void)swizzleMethodOnClass:(Class)targetClass originalSelector:(SEL)originalSelector fromClass:(Class)fromClass alternateSelector:(SEL)alternateSelector {
    Method originalMethod = nil, alternateMethod = nil;
	
    // First, look for the methods
    originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    alternateMethod = class_getInstanceMethod(fromClass, alternateSelector);
    
    // If both are found, swizzle them
    if (originalMethod != nil && alternateMethod != nil) {
		IMP originalImplementation = method_getImplementation(originalMethod);
		IMP alternateImplementation = method_getImplementation(alternateMethod);
		method_setImplementation(originalMethod, alternateImplementation);
		method_setImplementation(alternateMethod, originalImplementation);
	}
}

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
    
    UIConsoleLog* log = [[UIConsoleLog alloc] init];
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