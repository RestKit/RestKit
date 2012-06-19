//
//
// lcl_config_logger.h
//
//
// Copyright (c) 2008-2011 Arne Harren <ah@0xc0.de>
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
// lcl_config_logger.h template.
//


//
// The lcl_config_logger.h file is used to define the logging back-end which
// is used by the lcl_log() logging macro.
//
// For integration with the logging macro, a back-end simply defines the
// _lcl_logger macro which has the following signature:
//
//   #define _lcl_logger(_component, _level, _format, ...) <logging action>
//


//
// Example
//


// ARC/non-ARC autorelease pool
#define _lcl_logger_autoreleasepool_arc 0
#if defined(__has_feature)
#   if __has_feature(objc_arc)
#   undef  _lcl_logger_autoreleasepool_arc
#   define _lcl_logger_autoreleasepool_arc 1
#   endif
#endif
#if _lcl_logger_autoreleasepool_arc
#define _lcl_logger_autoreleasepool_begin                                      \
    @autoreleasepool {
#define _lcl_logger_autoreleasepool_end                                        \
    }
#else
#define _lcl_logger_autoreleasepool_begin                                      \
    NSAutoreleasePool *_lcl_logger_autoreleasepool = [[NSAutoreleasePool alloc] init];
#define _lcl_logger_autoreleasepool_end                                        \
    [_lcl_logger_autoreleasepool release];
#endif


// A very simple logger, which redirects to NSLog().
#define _lcl_logger(_component, _level, _format, ...) {                        \
    _lcl_logger_autoreleasepool_begin                                          \
    NSLog(@"%s %s:%@:%d:%s " _format,                                          \
          _lcl_level_header_1[_level],                                         \
          _lcl_component_header[_component],                                   \
          [@__FILE__ lastPathComponent],                                       \
          __LINE__,                                                            \
          __PRETTY_FUNCTION__,                                                 \
          ## __VA_ARGS__);                                                     \
    _lcl_logger_autoreleasepool_end                                            \
}

