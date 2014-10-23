//
//  NBULog+RestKit.m
//  RestKit
//
//  Created by Ernesto Rivera on 5/19/14.
//  Copyright (c) 2009-2014 RestKit. All rights reserved.
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

#ifdef COCOAPODS_POD_AVAILABLE_NBULog

#import "NBULog+RestKit.h"
#import <NBULog/NBULogContextDescription.h>

#define MAX_MODULES 10

static DDLogLevel _restKitLogLevel;
static DDLogLevel _restKitModulesLogLevel[MAX_MODULES];

@implementation NBULog (RestKit)

+ (void)load
{
    // Default levels
    [self setRestKitLogLevel:LOG_LEVEL_DEFAULT];
    
    // Register the RestKit log context
    [NBULog registerContextDescription:[NBULogContextDescription descriptionWithName:@"RestKit"
                                                                             context:RESTKIT_LOG_CONTEXT
                                                                     modulesAndNames:@{@(RESTKIT_MODULE_NETWORK)            : @"Network",
                                                                                       @(RESTKIT_MODULE_NETWORKCOREDATA)    : @"Network CoreData",
                                                                                       @(RESTKIT_MODULE_OBJECTMAPPING)      : @"Object Mapping",
                                                                                       @(RESTKIT_MODULE_COREDATA)           : @"CoreData",
                                                                                       @(RESTKIT_MODULE_COREDATACACHE)      : @"CoreData Cache",
                                                                                       @(RESTKIT_MODULE_SEARCH)             : @"Search",
                                                                                       @(RESTKIT_MODULE_SUPPORT)            : @"Support",
                                                                                       @(RESTKIT_MODULE_TESTING)            : @"Testing",
                                                                                       @(RESTKIT_MODULE_UI)                 : @"UI"}
                                                                   contextLevelBlock:^{ return [NBULog restKitLogLevel]; }
                                                                setContextLevelBlock:^(DDLogLevel level) { [NBULog setRestKitLogLevel:level]; }
                                                          contextLevelForModuleBlock:^(int module) { return [NBULog restKitLogLevelForModule:module]; }
                                                       setContextLevelForModuleBlock:^(int module, DDLogLevel level) { [NBULog setRestKitLogLevel:level
                                                                                                                                 forModule:module]; }]];
}

+ (DDLogLevel)restKitLogLevel
{
    return _restKitLogLevel;
}

+ (void)setRestKitLogLevel:(DDLogLevel)logLevel
{
#ifdef DEBUG
    _restKitLogLevel = logLevel == LOG_LEVEL_DEFAULT ? DDLogLevelInfo : logLevel;
#else
    _restKitLogLevel = logLevel == LOG_LEVEL_DEFAULT ? DDLogLevelWarning : logLevel;
#endif
    
    // Reset all modules' levels
    for (int i = 0; i < MAX_MODULES; i++)
    {
        [self setRestKitLogLevel:LOG_LEVEL_DEFAULT
                       forModule:i];
    }
}

+ (DDLogLevel)restKitLogLevelForModule:(int)RESTKIT_MODULE_XXX
{
    int logLevel = _restKitModulesLogLevel[RESTKIT_MODULE_XXX];
    
    // Fallback to the default log level if necessary
    return logLevel == LOG_LEVEL_DEFAULT ? _restKitLogLevel : logLevel;
}

+ (void)setRestKitLogLevel:(DDLogLevel)logLevel
                 forModule:(int)RESTKIT_MODULE_XXX
{
    _restKitModulesLogLevel[RESTKIT_MODULE_XXX] = logLevel;
}

@end

#endif

