//
//  RKLog.m
//  RestKit
//
//  Created by Blake Watters on 6/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKLog.h"

static BOOL loggingInitialized = NO;

void RKLogInitialize(void) {
    if (loggingInitialized == NO) {
        lcl_configure_by_name("RestKit*", RKLogLevelDefault);
        lcl_configure_by_name("App", RKLogLevelDefault);
        RKLogInfo(@"RestKit initialized...");
        loggingInitialized = YES;
    }
}
