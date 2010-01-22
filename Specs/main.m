//
//  main.m
//  Cash Register
//
//  Created by Jeremy Ellison on 12/7/09.
//  Copyright Two Toasters 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UISpec.h"

int main(int argc, char *argv[]) {
    
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSString* specToRun = [NSString stringWithFormat:@"%s", getenv("UISPEC_RUN_SPEC")];
	NSLog(@"Running spec with name: %@", specToRun);
	if (NO == [specToRun isEqualToString:@""]) {
		[UISpec runSpec:specToRun afterDelay:1];
	} else {
		[UISpec runSpecs];
	}	
	
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
