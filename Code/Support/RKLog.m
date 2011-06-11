//
//  RKLog.m
//  RestKit
//
//  Created by Blake Watters on 6/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKLog.h"

static BOOL loggingInitialized = NO;

void RKLogInitialize() {
    if (loggingInitialized == NO) {
        RKLogConfigureByName("RestKit*", RKLogLevelDefault);
        RKLogInfo(@"RestKit initialized...");
        loggingInitialized = YES;
    }
}
