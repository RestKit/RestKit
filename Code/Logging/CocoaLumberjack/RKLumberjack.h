//
//  RKLumberjack.h
//  RestKit
//
//  Created by Ernesto Rivera on 5/19/14.
//  Copyright (c) 2009-2013 RestKit. All rights reserved.
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
 RestKit logging based on CocoaLumberjack
 
 https://github.com/CocoaLumberjack/CocoaLumberjack
 */

#import <CocoaLumberjack/DDLog.h>

// Adjust log levels globally here
#ifdef DEBUG
    #define RKLogLevelDefault   LOG_LEVEL_INFO
#else
    #define RKLogLevelDefault   LOG_LEVEL_WARN
#endif

// Or per component here
#define LogLevel_RKlcl_cRestKit                 RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitObjectMapping    RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitCoreData         RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitCoreDataCache    RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitNetwork          RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitNetworkCoreData  RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitSearch           RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitTesting          RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitUI               RKLogLevelDefault
#define LogLevel_RKlcl_cRestKitSupport          RKLogLevelDefault


// Macros used internally by RestKit

#define RKLogLevelOff       LOG_LEVEL_OFF
#define RKLogLevelCritical  LOG_LEVEL_ERROR
#define RKLogLevelError     LOG_LEVEL_ERROR
#define RKLogLevelWarning   LOG_LEVEL_WARN
#define RKLogLevelInfo      LOG_LEVEL_INFO
#define RKLogLevelDebug     LOG_LEVEL_DEBUG
#define RKLogLevelTrace     LOG_LEVEL_VERBOSE

#define RKLogComponent RKlcl_cRestKit

#define PPCAT_NX(A, B) A ## B
#define RKLogLevelForComponent(_cmp) PPCAT_NX(LogLevel_, _cmp)

#undef  LOG_LEVEL_DEF
#define LOG_LEVEL_DEF RKLogLevelForComponent(RKLogComponent)

#define RKLogCritical(frmt, ...) LOG_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogError(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogWarning(frmt, ...)  LOG_MAYBE(LOG_ASYNC_WARN,    LOG_LEVEL_DEF, LOG_FLAG_WARN,    0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogInfo(frmt, ...)     LOG_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_FLAG_INFO,    0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogDebug(frmt, ...)    LOG_MAYBE(LOG_ASYNC_DEBUG,   LOG_LEVEL_DEF, LOG_FLAG_DEBUG,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define RKLogTrace(frmt, ...)    LOG_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, 0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define RKLogValidationError(_error) RKLogError(@"%@", _error)
#define RKLogCoreDataError(_error)   RKLogError(@"%@", _error)

#define RKLogLevelForComponentIsEqualOrGreaterThan(_component, _level) LOG_LEVEL_DEF >= _level

