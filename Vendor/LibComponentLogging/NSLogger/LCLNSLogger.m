//
//
// LCLNSLogger.m
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

#import "lcl.h"
#import "LCLNSLogger.h"
#import "LoggerClient.h"


//
// Configuration checks.
//


#ifndef LCLNSLogger
#error  'LCLNSLogger' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_ShowFileNames
#error  '_LCLNSLogger_ShowFileNames' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_ShowLineNumbers
#error  '_LCLNSLogger_ShowLineNumbers' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_ShowFunctionNames
#error  '_LCLNSLogger_ShowFunctionNames' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_LogToConsole
#error  '_LCLNSLogger_LogToConsole' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_BufferLocallyUntilConnection
#error  '_LCLNSLogger_BufferLocallyUntilConnection' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_BrowseBonjour
#error  '_LCLNSLogger_BrowseBonjour' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_BrowseOnlyLocalDomains
#error  '_LCLNSLogger_BrowseOnlyLocalDomains' must be defined in LCLNSLoggerConfig.h
#endif

#ifndef _LCLNSLogger_UseSSL
#error  '_LCLNSLogger_UseSSL' must be defined in LCLNSLoggerConfig.h
#endif


//
// Fields.
//


// The logger instance we use.
static Logger *_LCLNSLogger_logger = nil;

// Log component identifiers, indexed by log component.
NSString *_LCLNSLogger_identifier[] = {
#   define  _lcl_component(_identifier, _header, _name)                        \
    @#_identifier,
#   include "lcl_config_components.h"
#   undef   _lcl_component
};

// YES, if the file name should be shown.
static BOOL _LCLNSLogger_showFileName = NO;

// YES, if the line number should be shown.
static BOOL _LCLNSLogger_showLineNumber = NO;

// YES, if the function name should be shown.
static BOOL _LCLNSLogger_showFunctionName = NO;


@implementation LCLNSLogger


//
// Initialization.
//


// No instances, please.
+(id)alloc {
    [LCLNSLogger doesNotRecognizeSelector:_cmd];
    return nil;
}

// Initializes the class.
+ (void)initialize {
    // perform initialization only once
    if (self != [LCLNSLogger class])
        return;
    
    // get whether we should show file names
    _LCLNSLogger_showFileName = (_LCLNSLogger_ShowFileNames);
    
    // get whether we should show line numbers
    _LCLNSLogger_showLineNumber = (_LCLNSLogger_ShowLineNumbers);
    
    // get whether we should show function names
    _LCLNSLogger_showFunctionName = (_LCLNSLogger_ShowFunctionNames);
    
    // create and remember the logger instance
    _LCLNSLogger_logger = LoggerInit();
    
    // get configuration options for the logger
    const BOOL logToConsole = (_LCLNSLogger_LogToConsole);
    const BOOL bufferLocallyUntilConnection = (_LCLNSLogger_BufferLocallyUntilConnection);
    const BOOL browseBonjour = (_LCLNSLogger_BrowseBonjour);
    const BOOL browseOnlyLocalDomains = (_LCLNSLogger_BrowseOnlyLocalDomains);
    const BOOL useSSL = (_LCLNSLogger_UseSSL);
    
    // configure the logger
    uint32_t options = 0;
    options |= logToConsole ? kLoggerOption_LogToConsole : 0;
    options |= bufferLocallyUntilConnection ? kLoggerOption_BufferLogsUntilConnection : 0;
    options |= browseBonjour ? kLoggerOption_BrowseBonjour : 0;
    options |= browseOnlyLocalDomains ? kLoggerOption_BrowseOnlyLocalDomain : 0;
    options |= useSSL ? kLoggerOption_UseSSL : 0;
    LoggerSetOptions(_LCLNSLogger_logger, options);
    
    // activate the logger
    LoggerStart(_LCLNSLogger_logger);
}


//
// Logging methods.
//


// Writes the given log message to the log.
+ (void)logWithComponent:(_lcl_component_t)component level:(uint32_t)level
                    path:(const char *)path_c line:(uint32_t)line
                function:(const char *)function_c
                  format:(NSString *)format, ... {
    // get settings
    const BOOL show_file = _LCLNSLogger_showFileName;
    const BOOL show_line = _LCLNSLogger_showLineNumber;
    const BOOL show_function = _LCLNSLogger_showFunctionName;
    
    // get file name from path
    const char *file_c = NULL;
    if (show_file) {
        file_c = (path_c != NULL) ? strrchr(path_c, '/') : NULL;
        file_c = (file_c != NULL) ? (file_c + 1) : (path_c);
    }

    // get domain
    NSString *domain = _LCLNSLogger_identifier[component];
    
    // write log message
    va_list args;
    va_start(args, format);
    LogMessageToF_va(_LCLNSLogger_logger,
                     file_c,
                     (int)(show_line ? line : 0),
                     show_function ? function_c : NULL,
                     domain,
                     (int)level,
                     format,
                     args);
    va_end(args);
}

@end

