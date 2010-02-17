//
//  main.m
//  RestKit
//
//  Created by Jeremy Ellison on 12/7/09.
//  Copyright Two Toasters 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UISpec.h"

int main(int argc, char *argv[]) {
    
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	char* specName = getenv("UISPEC_RUN_SPEC");
	NSString* specToRun = [NSString stringWithFormat:@"%s", specName];
	if (specName && NO == [specToRun isEqualToString:@""]) {
		NSLog(@"UISpec - Running individual spec '%@'", specToRun);
		[UISpec runSpec:specToRun afterDelay:1];
	} else {
		[UISpec runSpecs];
	}	
	
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
