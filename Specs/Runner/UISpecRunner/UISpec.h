//
//  UISpec.h
//  UISpec
//
//  Created by Brian Knorr <btknorr@gmail.com>
//  Copyright(c) 2009 StarterStep, Inc., Some rights reserved.
//

@class UILog;

@interface UISpec : NSObject {

}

+(void)initialize;
+(void)runSpecsAfterDelay:(int)seconds;
+(void)runSpec:(NSString *)specName afterDelay:(int)seconds;
+(void)runSpec:(NSString *)specName example:(NSString *)exampleName afterDelay:(int)seconds;
+(void)runSpecs;
+(void)runSpec:(NSTimer *)timer;
+(void)runSpecExample:(NSTimer *)timer;
+(void)runSpecClasses:(NSArray *)specClasses;
+(void)runExamples:(NSArray *)examples onSpec:(Class *)class;
+(void)setLog:(UILog *)log;
+(NSDictionary *)specsAndExamples;

/**
 * Run all UISpec classes conforming to a given protocol
 */
+(void)runSpecsConformingToProtocol:(Protocol *)protocol afterDelay:(NSTimeInterval)delay;

/**
 * Run all UISpec classes inheriting from a given base class
 */
+(void)runSpecsInheritingFromClass:(Class)class afterDelay:(NSTimeInterval)delay;

/**
 * Infers which set of UISpec classes to run from the following environment variables:
 * UISPEC_PROTOCOL - Specifies a protocol to run
 * UISPEC_SPEC - Specifies a spec class to run
 * UISPEC_METHOD - Specifies an example to run (requires UISPEC_SPEC to be set)
 * UISPEC_EXIT_ON_FINISH - When YES, instructs UISpecRunner to terminate the application when specs run is complete
 */
+(void)runSpecsFromEnvironmentAfterDelay:(int)seconds;

@end

@protocol UISpec
@end

