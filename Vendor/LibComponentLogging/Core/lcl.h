//
//
// lcl.h -- LibComponentLogging
//
//
// Copyright (c) 2008-2012 Arne Harren <ah@0xc0.de>
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

#ifndef __LCL_H__
#define __LCL_H__

#define _LCL_VERSION_MAJOR  1
#define _LCL_VERSION_MINOR  3
#define _LCL_VERSION_BUILD  1
#define _LCL_VERSION_SUFFIX ""

//
// lcl -- LibComponentLogging
//
// LibComponentLogging is a logging library for Objective-C applications
// with the following characteristics:
//
// - Log levels
//   The library provides log levels for distinguishing between error messages,
//   informational messages, and fine-grained trace messages for debugging.
//
// - Log components
//   The library provides log components for identifying different parts of an
//   application. A log component contains a unique identifier, a short name
//   which is used as a header in a log message, and a full name which can be
//   used in a user interface.
//
// - Active log level per log component
//   At runtime, the library provides an active log level for each log
//   component in order to enable/disable logging for certain parts of an
//   application.
//
// - Grouping of log components
//   Log components which have the same name prefix form a group of log
//   components and logging can be enabled/disabled for the whole group with
//   a single command.
//
// - Low runtime-overhead when logging is disabled
//   Logging is based on a log macro which checks the active log level before
//   constructing the log message and before evaluating log message arguments.
//
// - Code completion support
//   The library provides symbols for log components and log levels which work
//   with Xcode's code completion. All symbols, e.g. values or functions, which
//   are relevant when using the logging library in an application, are prefixed
//   with 'lcl_'. Internal symbols, which are needed when working with meta
//   data, when defining log components, or when writing a logging back-end, are
//   prefixed with '_lcl_'. Internal symbols, which are only used by the logging
//   library itself, are prefixed with '__lcl_'.
//
// - Meta data
//   The library provides public data structures which contain information about
//   log levels and log components, e.g. headers and names.
//
// - Pluggable loggers
//   The library does not contain a concrete logger, but provides a simple
//   delegation mechanism for plugging-in a concrete logger based on the
//   application's requirements, e.g. a logger which writes to the system log,
//   or a logger which writes to a log file. The concrete logger is configured
//   at build-time.
//
// Note: If the preprocessor symbol _LCL_NO_LOGGING is defined, the log macro
// will be defined to an empty effect.
//


#import <Foundation/Foundation.h>


// Use C linkage.
#ifdef __cplusplus
extern "C" {
#endif


//
// Log levels.
//


// Log levels, prefixed with 'lcl_v'.
enum _lcl_enum_level_t {
    lcl_vOff = 0,

    lcl_vCritical,              // critical situation
    lcl_vError,                 // error situation
    lcl_vWarning,               // warning
    lcl_vInfo,                  // informational message
    lcl_vDebug,                 // coarse-grained debugging information
    lcl_vTrace,                 // fine-grained debugging information
    
   _lcl_level_t_count,
   _lcl_level_t_first = 0,
   _lcl_level_t_last  = _lcl_level_t_count-1
};

// Log level type.
typedef uint32_t _lcl_level_t;
typedef uint8_t  _lcl_level_narrow_t;


//
// Log components.
//


// Log components, prefixed with 'lcl_c'.
enum _lcl_enum_component_t {
#   define  _lcl_component(_identifier, _header, _name)                        \
    lcl_c##_identifier,                                                        \
  __lcl_log_symbol_lcl_c##_identifier = lcl_c##_identifier,
#   include "lcl_config_components.h"
#   undef   _lcl_component

   _lcl_component_t_count,
   _lcl_component_t_first = 0,
   _lcl_component_t_last  = _lcl_component_t_count-1
};

// Log component type.
typedef uint32_t _lcl_component_t;


//
// Functions and macros.
//

#ifndef _LCL_NO_IGNORE_WARNINGS
#   ifdef __clang__
    // Ignore some warnings about variadic macros when using '-Weverything'.
#   pragma clang diagnostic push
#   pragma clang diagnostic ignored "-Wunknown-pragmas"
#   pragma clang diagnostic ignored "-Wvariadic-macros"
#   pragma clang diagnostic ignored "-Wpedantic"
#   endif
#endif

// lcl_log(<component>, <level>, <format>[, <arg1>[, <arg2>[, ...]]])
//
// <component>: a log component with prefix 'lcl_c'
// <level>    : a log level with prefix 'lcl_v'
// <format>   : a format string of type NSString (may include %@)
// <arg..>    : optional arguments required by the format string
//
// Logs a message for the given log component at the given log level if the
// log level is active for the log component.
//
// The actual logging is done by _lcl_logger which must be defined by a concrete
// logging back-end. _lcl_logger has the same signature as lcl_log.
//
#ifdef _LCL_NO_LOGGING
#   define lcl_log(_component, _level, _format, ...)                           \
        do {                                                                   \
        } while (0)
#else
#   define lcl_log(_component, _level, _format, ...)                           \
        do {                                                                   \
            if (((_lcl_component_level[(__lcl_log_symbol(_component))]) >=     \
                  (__lcl_log_symbol(_level)))                                  \
               ) {                                                             \
                    _lcl_logger(_component,                                    \
                                _level,                                        \
                                _format,                                       \
                                ##__VA_ARGS__);                                \
            }                                                                  \
        } while (0)
#endif

// lcl_log_if(<component>, <level>, <predicate>, <format>[, <arg1>[, ...]])
//
// <component>: a log component with prefix 'lcl_c'
// <level>    : a log level with prefix 'lcl_v'
// <predicate>: a predicate for conditional logging
// <format>   : a format string of type NSString (may include %@)
// <arg..>    : optional arguments required by the format string
//
// Logs a message for the given log component at the given log level if the
// log level is active for the log component and if the predicate evaluates
// to true.
//
// The predicate is only evaluated if the given log level is active.
//
// The actual logging is done by _lcl_logger which must be defined by a concrete
// logging back-end. _lcl_logger has the same signature as lcl_log.
//
#ifdef _LCL_NO_LOGGING
#   define lcl_log_if(_component, _level, _predicate, _format, ...)            \
        do {                                                                   \
        } while (0)
#else
#   define lcl_log_if(_component, _level, _predicate, _format, ...)            \
        do {                                                                   \
            if (((_lcl_component_level[(__lcl_log_symbol(_component))]) >=     \
                  (__lcl_log_symbol(_level)))                                  \
                &&                                                             \
                (_predicate)                                                   \
               ) {                                                             \
                    _lcl_logger(_component,                                    \
                                _level,                                        \
                                _format,                                       \
                                ##__VA_ARGS__);                                \
            }                                                                  \
        } while (0)
#endif

#ifndef _LCL_NO_IGNORE_WARNINGS
#   ifdef __clang__
#   pragma clang diagnostic pop
#   endif
#endif

// lcl_configure_by_component(<component>, <level>)
//
// <component>: a log component with prefix 'lcl_c'
// <level>    : a log level with prefix 'lcl_v'
//
// Configures the given log level for the given log component.
// Returns the number of configured log components, or 0 on failure.
//
uint32_t lcl_configure_by_component(_lcl_component_t component, _lcl_level_t level);

// lcl_configure_by_identifier(<identifier>, <level>)
//
// <identifier>: a log component's identifier with optional '*' wildcard suffix
// <level>     : a log level with prefix 'lcl_v'
//
// Configures the given log level for the given log component(s).
// Returns the number of configured log components, or 0 on failure.
//
uint32_t lcl_configure_by_identifier(const char *identifier, _lcl_level_t level);

// lcl_configure_by_header(<header>, <level>)
//
// <header>    : a log component's header with optional '*' wildcard suffix
// <level>     : a log level with prefix 'lcl_v'
//
// Configures the given log level for the given log component(s).
// Returns the number of configured log components, or 0 on failure.
//
uint32_t lcl_configure_by_header(const char *header, _lcl_level_t level);

// lcl_configure_by_name(<name>, <level>)
//
// <name>     : a log component's name with optional '*' wildcard suffix
// <level>    : a log level with prefix 'lcl_v'
//
// Configures the given log level for the given log component(s).
// Returns the number of configured log components, or 0 on failure.
//
uint32_t lcl_configure_by_name(const char *name, _lcl_level_t level);


//
// Internals.
//


// Active log levels, indexed by log component.
extern _lcl_level_narrow_t _lcl_component_level[_lcl_component_t_count];

// Log component identifiers, indexed by log component.
extern const char * const _lcl_component_identifier[_lcl_component_t_count];

// Log component headers, indexed by log component.
extern const char * const _lcl_component_header[_lcl_component_t_count];

// Log component names, indexed by log component.
extern const char * const _lcl_component_name[_lcl_component_t_count];

// Log level headers, indexed by log level.
extern const char * const _lcl_level_header[_lcl_level_t_count];   // full header
extern const char * const _lcl_level_header_1[_lcl_level_t_count]; // header with 1 character
extern const char * const _lcl_level_header_3[_lcl_level_t_count]; // header with 3 characters

// Log level names, indexed by log level.
extern const char * const _lcl_level_name[_lcl_level_t_count];

// Version.
extern const char * const _lcl_version;

// Log level symbols used by lcl_log, prefixed with '__lcl_log_symbol_lcl_v'.
enum {
  __lcl_log_symbol_lcl_vCritical = lcl_vCritical,
  __lcl_log_symbol_lcl_vError    = lcl_vError,
  __lcl_log_symbol_lcl_vWarning  = lcl_vWarning,
  __lcl_log_symbol_lcl_vInfo     = lcl_vInfo,
  __lcl_log_symbol_lcl_vDebug    = lcl_vDebug,
  __lcl_log_symbol_lcl_vTrace    = lcl_vTrace
};

// Macro for appending the '__lcl_log_symbol_' prefix to a given symbol.
#define __lcl_log_symbol(_symbol)                                              \
    __lcl_log_symbol_##_symbol


// End C linkage.
#ifdef __cplusplus
}
#endif


// Include logging back-end and definition of _lcl_logger.
#import "lcl_config_logger.h"


// For simple configurations where 'lcl_config_logger.h' is empty, define a
// default NSLog()-based _lcl_logger here.
#ifndef _lcl_logger

// ARC/non-ARC autorelease pool
#define _lcl_logger_autoreleasepool_arc 0
#if defined(__has_feature)
#   if __has_feature(objc_arc)
#   undef  _lcl_logger_autoreleasepool_arc
#   define _lcl_logger_autoreleasepool_arc 1
#   endif
#endif
#if _lcl_logger_autoreleasepool_arc
#   define _lcl_logger_autoreleasepool_begin                                   \
        @autoreleasepool {
#   define _lcl_logger_autoreleasepool_end                                     \
        }
#else
#   define _lcl_logger_autoreleasepool_begin                                   \
        NSAutoreleasePool *_lcl_logger_autoreleasepool = [[NSAutoreleasePool alloc] init];
#   define _lcl_logger_autoreleasepool_end                                     \
        [_lcl_logger_autoreleasepool release];
#endif

#ifndef _LCL_NO_IGNORE_WARNINGS
#   ifdef __clang__
    // Ignore some warnings about variadic macros when using '-Weverything'.
#   pragma clang diagnostic push
#   pragma clang diagnostic ignored "-Wunknown-pragmas"
#   pragma clang diagnostic ignored "-Wvariadic-macros"
#   pragma clang diagnostic ignored "-Wpedantic"
#   endif
#endif

// A simple default logger, which redirects to NSLog().
#define _lcl_logger(_component, _level, _format, ...) {                        \
    _lcl_logger_autoreleasepool_begin                                          \
    NSLog(@"%s %s:%@:%d " _format,                                             \
          _lcl_level_header_1[_level],                                         \
          _lcl_component_header[_component],                                   \
          [@__FILE__ lastPathComponent],                                       \
          __LINE__,                                                            \
          ## __VA_ARGS__);                                                     \
    _lcl_logger_autoreleasepool_end                                            \
}

#ifndef _LCL_NO_IGNORE_WARNINGS
#   ifdef __clang__
#   pragma clang diagnostic pop
#   endif
#endif

#endif


// Include extensions.
#import "lcl_config_extensions.h"


#endif // __LCL_H__

