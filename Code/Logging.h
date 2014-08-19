//
//  Logging.h
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

// *** Static Library ***
#if !defined(COCOAPODS)

    // LibComponentLogging
    #import "RKLog.h"

// *** CocoaPods ***
#else

    // LibComponentLogging
    #if defined(COCOAPODS_POD_AVAILABLE_RestKit_Logging_LibComponentLogging)
    #import "RKLog.h"

    // CocoaLumberJack
    #elif defined(COCOAPODS_POD_AVAILABLE_RestKit_Logging_CocoaLumberjack)
    #import "RKLumberjack.h"

    // NBULog
    #elif defined(COCOAPODS_POD_AVAILABLE_RestKit_Logging_NBULog)
    #import "NBULog+RestKit.h"

    // NSLog
    #elif defined(COCOAPODS_POD_AVAILABLE_RestKit_Logging_NSLog)
    #import "RKNSLog.h"

    // No RestKit Pod installed (RestKit installed as a static library)
    #else
    #import "RKLog.h"
    #endif

#endif
