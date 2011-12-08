//
//  RKLog.m
//  RestKit
//
//  Created by Blake Watters on 6/10/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKLog.h"
#import "lcl.h"

static BOOL loggingInitialized = NO;

void RKLogInitialize(void) {
    if (loggingInitialized == NO) {
        lcl_configure_by_name("RestKit*", RKLogLevelDefault);
        lcl_configure_by_name("App", RKLogLevelDefault);
        RKLogInfo(@"RestKit initialized...");
        loggingInitialized = YES;
    }
}
