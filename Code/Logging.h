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


// LibComponentLogging
#if __has_include("RKLog.h")
#import "RKLog.h"

// CocoaLumberJack
#elif __has_include("RKLumberjack.h")
#import "RKLumberjack.h"

// NBULog
#elif __has_include("NBULog+RestKit.h")
#import "NBULog+RestKit.h"

// NSLog
#else
#import "RKNSLog.h"
#endif

