//
//
// LCLNSLog.h
//
//
// Copyright (c) 2008-2009 Arne Harren <ah@0xc0.de>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


//
// LCLNSLog
//
// This file provides a simple LibComponentLogging logger implementation which
// redirects logging to NSLog.
//
// The logger uses the following format
//
//   <NSLog Prefix> <Level> <Component>:<File>:<Line> <Message>
//
// where <NSLog Prefix> is
//
//   <Date> <Time> <Application>[<PID>:<TID>]
//
// Examples:
//
//   2009-02-01 12:38:32.796 Example[4964:10b] D F1:main.m:28 F1(10)
//   2009-02-01 12:38:32.798 Example[4964:10b] D F1:main.m:32 F2(20)
//   2009-02-01 12:38:32.799 Example[4964:10b] D F1:main.m:36 F3(30)
//


//
// Integration with LibComponentLogging Core.
//

#if __has_feature(objc_arc)
#define LCLNSLogAutoReleasePoolBegin()                                         \
@autoreleasepool {
#else
#define LCLNSLogAutoReleasePoolBegin()                                         \
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#endif

#if __has_feature(objc_arc)
#define LCLNSLogAutoReleasePoolEnd()                                           \
}
#else
#define LCLNSLogAutoReleasePoolEnd()                                           \
[pool release];
#endif

// Definition of _lcl_logger.
#define _lcl_logger(log_component, log_level, log_format, ...) {               \
    LCLNSLogAutoReleasePoolBegin();                \
    NSLog(@"%s %s:%@:%d " log_format,                                          \
          _lcl_level_header_1[log_level],                                      \
          _lcl_component_header[log_component],                                \
          [@__FILE__ lastPathComponent],                                       \
          __LINE__,                                                            \
          ## __VA_ARGS__);                                                     \
    LCLNSLogAutoReleasePoolEnd();                                              \
}

