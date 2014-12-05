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
    return [self levelFromRKLevel:_RKlcl_component_level[RKlcl_cRestKit]];
}

+ (void)setRestKitLogLevel:(DDLogLevel)logLevel
{
    RKlcl_configure_by_name("RestKit*", [self rkLevelFromLevel:logLevel]);
}

+ (DDLogLevel)restKitLogLevelForModule:(int)RESTKIT_MODULE_XXX
{
    return [self levelFromRKLevel:_RKlcl_component_level[RESTKIT_MODULE_XXX]];
}

+ (void)setRestKitLogLevel:(DDLogLevel)logLevel
                 forModule:(int)RESTKIT_MODULE_XXX
{
    RKlcl_configure_by_component(RESTKIT_MODULE_XXX, [self rkLevelFromLevel:logLevel]);
}

#pragma mark - Conversions

+ (DDLogLevel)levelFromRKLevel:(_RKlcl_level_t)rkLevel
{
    switch (rkLevel)
    {
        case RKlcl_vCritical:   return DDLogLevelError;
        case RKlcl_vError:      return DDLogLevelError;
        case RKlcl_vWarning:    return DDLogLevelWarning;
        case RKlcl_vInfo:       return DDLogLevelInfo;
        case RKlcl_vDebug:      return DDLogLevelDebug;
        case RKlcl_vTrace:      return DDLogLevelVerbose;
        default:                return DDLogLevelOff;
    }
}

+ (_RKlcl_level_t)rkLevelFromLevel:(DDLogLevel)level
{
    switch (level)
    {
        case DDLogLevelError:   return RKlcl_vError;
        case DDLogLevelWarning: return RKlcl_vWarning;
        case DDLogLevelInfo:    return RKlcl_vInfo;
        case DDLogLevelDebug:   return RKlcl_vDebug;
        case DDLogLevelVerbose: return RKlcl_vTrace;
        default:                return RKlcl_vOff;
    }
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
    
    DDLogLevel level = [NBULog restKitLogLevelForModule:rkComponent];
    
    if (!(level & flag))
        return;
    
    BOOL async = !(flag & DDLogFlagError);
    
    va_list args;
    va_start(args, format);
    
    [DDLog log:async
         level:level
          flag:flag
       context:RESTKIT_LOG_CONTEXT + rkComponent
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

