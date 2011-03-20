//
//  main.m
//  UISpecRunner
//
//  Created by Blake Watters on 4/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UISpec+UISpecRunner.h"

int main(int argc, char *argv[]) {
    
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// Run the specs
	[UISpec runSpecsFromEnvironmentAfterDelay:0.5];
	
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
