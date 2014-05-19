//
//  NBULog+RestKit.h
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

/**
 RestKit logging based on NBULog
 
 https://github.com/CyberAgent/iOS-NBULog
 */

#ifdef COCOAPODS_POD_AVAILABLE_NBULog

#import <NBULog/NBULog.h>

/// RestKit log context
#ifndef RESTKIT_LOG_CONTEXT
    #define RESTKIT_LOG_CONTEXT         22000
#endif

/// RestKit modules
#define RESTKIT_MODULE_DEFAULT          0
#define RESTKIT_MODULE_NETWORK          1
#define RESTKIT_MODULE_NETWORKCOREDATA  2
#define RESTKIT_MODULE_OBJECTMAPPING    3
#define RESTKIT_MODULE_COREDATA         4
#define RESTKIT_MODULE_COREDATACACHE    5
#define RESTKIT_MODULE_SEARCH           6
#define RESTKIT_MODULE_SUPPORT          7
#define RESTKIT_MODULE_TESTING          8
#define RESTKIT_MODULE_UI               9

/**
 NBULog category used to set/get RestKit log levels.
 
 Default configuration (can be dynamically changed):
 
 - Log level: `LOG_LEVEL_INFO` for `DEBUG`, `LOG_LEVEL_WARN` otherwise.
 
 */
@interface NBULog (RestKit)

/// @name Adjusting RestKit Log Levels

/// The current RestKit log level.
+ (int)restKitLogLevel;

/// Dynamically set the RestKit log level for all modules at once.
/// @param LOG_LEVEL_XXX The desired log level.
/// @note Setting this value clears all modules' levels.
+ (void)setRestKitLogLevel:(int)LOG_LEVEL_XXX;

/// Get the current RestKit log level for a given module.
/// @param RESTKIT_MODULE_XXX The target module.
+ (int)restKitLogLevelForModule:(int)RESTKIT_MODULE_XXX;

/// Dynamically set the RestKit log level for a given module.
/// @param LOG_LEVEL_XXX The desired log level.
/// @param RESTKIT_MODULE_XXX The target module.
+ (void)setRestKitLogLevel:(int)LOG_LEVEL_XXX
                 forModule:(int)RESTKIT_MODULE_XXX;

@end


// Macros used internally by RestKit

#define RKLogLevelOff                   LOG_LEVEL_OFF
#define RKLogLevelCritical              LOG_LEVEL_ERROR
#define RKLogLevelError                 LOG_LEVEL_ERROR
#define RKLogLevelWarning               LOG_LEVEL_WARN
#define RKLogLevelInfo                  LOG_LEVEL_INFO
#define RKLogLevelDebug                 LOG_LEVEL_DEBUG
#define RKLogLevelTrace                 LOG_LEVEL_VERBOSE

#define RKlcl_cRestKit                  RESTKIT_MODULE_DEFAULT
#define RKlcl_cRestKitObjectMapping     RESTKIT_MODULE_OBJECTMAPPING
#define RKlcl_cRestKitCoreData          RESTKIT_MODULE_COREDATA
#define RKlcl_cRestKitCoreDataCache     RESTKIT_MODULE_COREDATACACHE
#define RKlcl_cRestKitNetwork           RESTKIT_MODULE_NETWORK
#define RKlcl_cRestKitNetworkCoreData   RESTKIT_MODULE_NETWORKCOREDATA
#define RKlcl_cRestKitSearch            RESTKIT_MODULE_SEARCH
#define RKlcl_cRestKitTesting           RESTKIT_MODULE_TESTING
#define RKlcl_cRestKitUI                RESTKIT_MODULE_UI
#define RKlcl_cRestKitSupport           RESTKIT_MODULE_SUPPORT

#define RKLogComponent                  RESTKIT_MODULE_DEFAULT

#define RKLogCritical(frmt, ...)        LOG_MAYBE(LOG_ASYNC_ERROR,   [NBULog restKitLogLevelForModule:RKLogComponent], LOG_FLAG_ERROR,   RESTKIT_LOG_CONTEXT + RKLogComponent, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogError(frmt, ...)           LOG_MAYBE(LOG_ASYNC_ERROR,   [NBULog restKitLogLevelForModule:RKLogComponent], LOG_FLAG_ERROR,   RESTKIT_LOG_CONTEXT + RKLogComponent, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogWarning(frmt, ...)         LOG_MAYBE(LOG_ASYNC_WARN,    [NBULog restKitLogLevelForModule:RKLogComponent], LOG_FLAG_WARN,    RESTKIT_LOG_CONTEXT + RKLogComponent, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogInfo(frmt, ...)            LOG_MAYBE(LOG_ASYNC_INFO,    [NBULog restKitLogLevelForModule:RKLogComponent], LOG_FLAG_INFO,    RESTKIT_LOG_CONTEXT + RKLogComponent, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogDebug(frmt, ...)           LOG_MAYBE(LOG_ASYNC_DEBUG,   [NBULog restKitLogLevelForModule:RKLogComponent], LOG_FLAG_DEBUG,   RESTKIT_LOG_CONTEXT + RKLogComponent, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogTrace(frmt, ...)           LOG_MAYBE(LOG_ASYNC_VERBOSE, [NBULog restKitLogLevelForModule:RKLogComponent], LOG_FLAG_VERBOSE, RESTKIT_LOG_CONTEXT + RKLogComponent, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define RKLogValidationError(_error)    RKLogError(@"%@", _error)
#define RKLogCoreDataError(_error)      RKLogError(@"%@", _error)

#define RKLogLevelForComponentIsEqualOrGreaterThan(_component, _level) [NBULog restKitLogLevelForModule:_component] >= _level

#endif

