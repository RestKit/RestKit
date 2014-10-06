//
//  RKNSLog.h
//  RestKit
//
//  Created by Ernesto Rivera on 5/16/14.
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
 RestKit logging based on NSLog
 */

#define RKLogLevelOff       0
#define RKLogLevelCritical  1
#define RKLogLevelError     2
#define RKLogLevelWarning   3
#define RKLogLevelInfo      4
#define RKLogLevelDebug     5
#define RKLogLevelTrace     6

// Adjust log levels globally here
#ifdef DEBUG
    #define RKLogLevelDefault   RKLogLevelInfo
#else
    #define RKLogLevelDefault   RKLogLevelWarning
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

#define RKLogComponent RKlcl_cRestKit

#define PPCAT_NX(A, B) A ## B
#define RKLogLevelForComponent(_cmp) PPCAT_NX(LogLevel_, _cmp)

#define RKLogCritical(frmt, ...)    do{ if(RKLogLevelForComponent(RKLogComponent) >= RKLogLevelCritical)    NSLog((frmt), ##__VA_ARGS__); } while(0)
#define RKLogError(frmt, ...)       do{ if(RKLogLevelForComponent(RKLogComponent) >= RKLogLevelError)       NSLog((frmt), ##__VA_ARGS__); } while(0)
#define RKLogWarning(frmt, ...)     do{ if(RKLogLevelForComponent(RKLogComponent) >= RKLogLevelWarning)     NSLog((frmt), ##__VA_ARGS__); } while(0)
#define RKLogInfo(frmt, ...)        do{ if(RKLogLevelForComponent(RKLogComponent) >= RKLogLevelInfo)        NSLog((frmt), ##__VA_ARGS__); } while(0)
#define RKLogDebug(frmt, ...)       do{ if(RKLogLevelForComponent(RKLogComponent) >= RKLogLevelDebug)       NSLog((frmt), ##__VA_ARGS__); } while(0)
#define RKLogTrace(frmt, ...)       do{ if(RKLogLevelForComponent(RKLogComponent) >= RKLogLevelTrace)       NSLog((frmt), ##__VA_ARGS__); } while(0)

#define RKLogValidationError(_error)    RKLogError(@"%@", _error)
#define RKLogCoreDataError(_error)      RKLogError(@"%@", _error)

#define RKLogLevelForComponentIsEqualOrGreaterThan(_component, _level) _level >= _level

