//
//  lcl_config_logger_RK.h
//  RestKit
//
//  Created by Blake Watters on 6/8/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

//
// Integration with LibComponentLogging Core.
//

// ARC/non-ARC autorelease pool
#define _RKlcl_logger_autoreleasepool_arc 0
#if defined(__has_feature)
#   if __has_feature(objc_arc)
#   undef  _RKlcl_logger_autoreleasepool_arc
#   define _RKlcl_logger_autoreleasepool_arc 1
#   endif
#endif

#if _RKlcl_logger_autoreleasepool_arc
  #define _RKlcl_logger_autoreleasepool_begin  @autoreleasepool {
  #define _RKlcl_logger_autoreleasepool_end    }
#else
  #define _RKlcl_logger_autoreleasepool_begin  NSAutoreleasePool *_RKlcl_logpool = [[NSAutoreleasePool alloc] init];
  #define _RKlcl_logger_autoreleasepool_end    [_RKlcl_logpool release];
#endif


#define _RKlcl_logger(_component, _level, _format, ...) {                        \
    _RKlcl_logger_autoreleasepool_begin                                          \
    [RKGetLoggingClass() logWithComponent:_component                             \
                                    level:_level                                 \
                                     path:__FILE__                               \
                                     line:__LINE__                               \
                                 function:__PRETTY_FUNCTION__                    \
                                   format:_format, ## __VA_ARGS__];              \
    _RKlcl_logger_autoreleasepool_end                                            \
}

