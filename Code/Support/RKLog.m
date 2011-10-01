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

void RKLogWithComponentAtLevelWhileExecutingBlock(_lcl_component_t component, _lcl_level_t level, void (^block)(void)) {
//    _lcl_level_narrow_t currentLevel = _lcl_component_level[(__lcl_log_symbol(_component))];
    // Get the current log level for the component
    // Set the log level to the new level
    // execute the block
    // restore the log level
}
