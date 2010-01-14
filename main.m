//
//  main.m
//  Cash Register
//
//  Created by Jeremy Ellison on 12/7/09.
//  Copyright Objective3 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UISpec.h"

int main(int argc, char *argv[]) {
    
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	[UISpec runSpecs];
	
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
