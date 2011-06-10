//
//
// LCLNSLogger.h
//
//
// Copyright (c) 2010-2011 Arne Harren <ah@0xc0.de>
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

#define _LCLNSLOGGER_VERSION_MAJOR  1
#define _LCLNSLOGGER_VERSION_MINOR  0
#define _LCLNSLOGGER_VERSION_BUILD  1
#define _LCLNSLOGGER_VERSION_SUFFIX ""

//
// LCLNSLogger
//
// LCLNSLogger is a logging back-end for LibComponentLogging which integrates
// the logging client from Florent Pillet's NSLogger project.
//
// See http://github.com/fpillet/NSLogger for more details about NSLogger.
//
// LCLNSLogger is configured via the following #defines in LCLNSLoggerConfig.h
// (see #import below):
//
// - Show file names in the log messages? (type BOOL)
//   #define _LCLNSLogger_ShowFileNames <definition>
//
// - Show line numbers in the log messages? (type BOOL)
//   #define _LCLNSLogger_ShowLineNumbers <definition>
//
// - Show function names in the log messages? (type BOOL)
//   #define _LCLNSLogger_ShowFunctionNames <definition>
//
// - Set the NSLogger option LogToConsole? (type BOOL)
//   #define _LCLNSLogger_LogToConolse <definition>
//
// - Set the NSLogger option BufferLocallyUntilConnection? (type BOOL)
//   #define _LCLNSLogger_BufferLocallyUntilConnection <definition>
//
// - Set the NSLogger option BrowseBonjour? (type BOOL)
//   #define _LCLNSLogger_BrowseBonjour <definition>
//
// - Set the NSLogger option BrowseOnlyLocalDomains? (type BOOL)
//   #define _LCLNSLogger_BrowseOnlyLocalDomains <definition>
//
// - Set the NSLogger option UseSSL? (type BOOL)
//   #define _LCLNSLogger_UseSSL <definition>
//
// For using LCLNSLogger with LibComponentLogging, simply add an
//   #import "LCLNSLogger.h"
// statement to your lcl_config_logger.h file and use the LCLNSLoggerConfig.h
// file for detailed configuration of the LCLNSLogger class.
//
// In addition to the LCLNSLogger files, you need the following files from
// the Client Logger folder from the NSLogger project:
//
//   LoggerClient.h
//   LoggerClient.m
//   LoggerCommon.h
//
// You can download them from here: http://github.com/fpillet/NSLogger
//
// In your project, you must link the following frameworks:
//
//   SystemConfiguration.framework
//   CFNetwork.framework / CoreServices.framework
//


#import <Foundation/Foundation.h>
#import "LCLNSLoggerConfig.h"


@interface LCLNSLogger : NSObject {
    
}


//
// Logging methods.
//


// Writes the given log message to the log.
+ (void)logWithComponent:(_lcl_component_t)component level:(uint32_t)level
                    path:(const char *)path line:(uint32_t)line
                function:(const char *)function
                  format:(NSString *)format, ... __attribute__((format(__NSString__, 6, 7)));


@end


// Define the _lcl_logger macro which integrates LCLNSLogger as a logging
// back-end for LibComponentLogging.
#define _lcl_logger(_component, _level, _format, ...) {                        \
    NSAutoreleasePool *_lcl_logger_pool = [[NSAutoreleasePool alloc] init];    \
    [LCLNSLogger logWithComponent:_component                                   \
                            level:_level                                       \
                             path:__FILE__                                     \
                             line:__LINE__                                     \
                         function:__PRETTY_FUNCTION__                          \
                           format:_format,                                     \
                               ## __VA_ARGS__];                                \
    [_lcl_logger_pool release];                                                \
}

