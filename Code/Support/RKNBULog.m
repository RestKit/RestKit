//
//  RKNBULog.m
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

#if __has_include("NBULog.h")

#define DDLEGACY 0
#import "RKNBULog.h"
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
    DDLogLevel logLevel = _restKitModulesLogLevel[RESTKIT_MODULE_XXX];
    
    // Fallback to the default log level if necessary
    return logLevel == LOG_LEVEL_DEFAULT ? _restKitLogLevel : logLevel;
}

+ (void)setRestKitLogLevel:(DDLogLevel)logLevel
                 forModule:(int)RESTKIT_MODULE_XXX
{
    _restKitModulesLogLevel[RESTKIT_MODULE_XXX] = logLevel;
}

@end


@implementation RKNBULogger

+ (void)logWithComponent:(_RKlcl_component_t)rkComponent
                   level:(_RKlcl_level_t)rkLevel
                    path:(const char *)path
                    line:(uint32_t)line
                function:(const char *)function
                  format:(NSString *)format, ...
{
    int module;
    switch (rkComponent)
    {
        case RKlcl_cRestKit:                module = RESTKIT_MODULE_DEFAULT;         break;
        case RKlcl_cRestKitObjectMapping:   module = RESTKIT_MODULE_OBJECTMAPPING;   break;
        case RKlcl_cRestKitCoreData:        module = RESTKIT_MODULE_COREDATA;        break;
        case RKlcl_cRestKitCoreDataCache:   module = RESTKIT_MODULE_COREDATACACHE;   break;
        case RKlcl_cRestKitNetwork:         module = RESTKIT_MODULE_NETWORK;         break;
        case RKlcl_cRestKitNetworkCoreData: module = RESTKIT_MODULE_NETWORKCOREDATA; break;
        case RKlcl_cRestKitSearch:          module = RESTKIT_MODULE_SEARCH;          break;
        case RKlcl_cRestKitTesting:         module = RESTKIT_MODULE_TESTING;         break;
        case RKlcl_cRestKitUI:              module = RESTKIT_MODULE_UI;              break;
        case RKlcl_cRestKitSupport:         module = RESTKIT_MODULE_SUPPORT;         break;
    }

    DDLogFlag flag;
    switch (rkLevel)
    {
        case RKlcl_vCritical:   flag = DDLogFlagError;      break;
        case RKlcl_vError:      flag = DDLogFlagError;      break;
        case RKlcl_vWarning:    flag = DDLogFlagWarning;    break;
        case RKlcl_vInfo:       flag = DDLogFlagInfo;       break;
        case RKlcl_vDebug:      flag = DDLogFlagDebug;      break;
        case RKlcl_vTrace:      flag = DDLogFlagVerbose;    break;
    }
    
    DDLogLevel level = [NBULog restKitLogLevelForModule:module];
    
    if (!(level & flag))
        return;
    
    BOOL async = !(flag & DDLogFlagError);
    
    va_list args;
    va_start(args, format);
    
    [DDLog log:async
         level:level
          flag:flag
       context:RESTKIT_LOG_CONTEXT + module
          file:path
      function:function
          line:line
           tag:nil
        format:format
          args:args];
    
    va_end(args);
}

@end

#endif

