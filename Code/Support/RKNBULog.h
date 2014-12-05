//
//  RKNBULog.h
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

#if __has_include("NBULog.h")

#import <NBULog/NBULog.h>

/// RestKit log context
#ifndef RESTKIT_LOG_CONTEXT
    #define RESTKIT_LOG_CONTEXT         22000
#endif

/// RestKit modules
#define RESTKIT_MODULE_DEFAULT          RKlcl_cRestKit
#define RESTKIT_MODULE_NETWORK          RKlcl_cRestKitNetwork
#define RESTKIT_MODULE_NETWORKCOREDATA  RKlcl_cRestKitNetworkCoreData
#define RESTKIT_MODULE_OBJECTMAPPING    RKlcl_cRestKitObjectMapping
#define RESTKIT_MODULE_COREDATA         RKlcl_cRestKitCoreData
#define RESTKIT_MODULE_COREDATACACHE    RKlcl_cRestKitCoreDataCache
#define RESTKIT_MODULE_SEARCH           RKlcl_cRestKitSearch
#define RESTKIT_MODULE_SUPPORT          RKlcl_cRestKitSupport
#define RESTKIT_MODULE_TESTING          RKlcl_cRestKitTesting
#define RESTKIT_MODULE_UI               RKlcl_cRestKitUI

#import "RKLog.h"

/**
 NBULog category used to set/get RestKit log levels.
 
 Default configuration (can be dynamically changed):
 
 - Log level: `LOG_LEVEL_INFO` for `DEBUG`, `LOG_LEVEL_WARN` otherwise.
 
 */
@interface NBULog (RestKit)

/// @name Adjusting RestKit Log Levels

/// The current RestKit log level.
+ (DDLogLevel)restKitLogLevel;

/// Dynamically set the RestKit log level for all modules at once.
/// @param logLevel The desired log level.
/// @note Setting this value clears all modules' levels.
+ (void)setRestKitLogLevel:(DDLogLevel)logLevel;

/// Get the current RestKit log level for a given module.
/// @param RESTKIT_MODULE_XXX The target module.
+ (DDLogLevel)restKitLogLevelForModule:(int)RESTKIT_MODULE_XXX;

/// Dynamically set the RestKit log level for a given module.
/// @param logLevel The desired log level.
/// @param RESTKIT_MODULE_XXX The target module.
+ (void)setRestKitLogLevel:(DDLogLevel)logLevel
                 forModule:(int)RESTKIT_MODULE_XXX;

@end


@interface RKNBULogger : NSObject <RKLogging>

@end

#endif

