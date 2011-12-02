//
//
// LCLLogFile.h
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

#define _LCLLOGFILE_VERSION_MAJOR  1
#define _LCLLOGFILE_VERSION_MINOR  1
#define _LCLLOGFILE_VERSION_BUILD  5
#define _LCLLOGFILE_VERSION_SUFFIX ""

//
// LCLLogFile
//
// LCLLogFile is a logging back-end implementation which writes log messages to
// an application-specific log file. LCLLogFile can be used as a logging
// back-end for LibComponentLogging, but it is also useable as a standalone
// logging class without the Core files of LibComponentLogging.
//
// The log file is opened automatically when the first log message needs to be
// written to the log file. There is no need to call open, close, reset, etc.
// manually.
//
// The log file gets rotated if a given maximum file size is reached.
//
// LCLLogFile is configured via the following #defines in LCLLogFileConfig.h
// (see #import below):
//
// - Full path of the log file (type NSString *)
//   #define _LCLLogFile_LogFilePath <definition>
//
// - Append to an existing log file on startup? (type BOOL)
//   #define _LCLLogFile_AppendToExistingLogFile
//
// - Maximum size of the log file in bytes (type size_t)
//   #define _LCLLogFile_MaxLogFileSizeInBytes <definition>
//
// - Mirror log messages to stderr? (type BOOL)
//   #define _LCLLogFile_MirrorMessagesToStdErr <definition>
//
// - Escape ('\\' and) '\n' line feed characters in log messages (type BOOL)
//   #define _LCLLogFile_EscapeLineFeeds <definition>
//
// - Maximum size of a log message in characters (type NSUInteger)
//   #define _LCLLogFile_MaxMessageSizeInCharacters <definition or 0>
//
// - Show file names in the log messages? (type BOOL)
//   #define _LCLLogFile_ShowFileNames <definition>
//
// - Show line numbers in the log messages? (type BOOL)
//   #define _LCLLogFile_ShowLineNumbers <definition>
//
// - Show function names in the log messages? (type BOOL)
//   #define _LCLLogFile_ShowFunctionNames <definition>
//
//
// When using LCLLogFile as a back-end for LibComponentLogging, simply add an
//   #import "LCLLogFile.h"
// statement to your lcl_config_logger.h file and use the LCLLogFileConfig.h
// file for detailed configuration of the LCLLogFile class.
//


#import <Foundation/Foundation.h>
#import "LCLLogFileConfig.h"


@interface LCLLogFile : NSObject {
    
}


//
// Logging methods.
//


// Writes the given log message to the log file.
+ (void)logWithIdentifier:(const char *)identifier level:(uint32_t)level
                     path:(const char *)path line:(uint32_t)line
                 function:(const char *)function
                  message:(NSString *)message;

// Writes the given log message to the log file (format and va_list var args).
+ (void)logWithIdentifier:(const char *)identifier level:(uint32_t)level
                     path:(const char *)path line:(uint32_t)line
                 function:(const char *)function
                   format:(NSString *)format args:(va_list)args;

// Writes the given log message to the log file (format and ... var args).
+ (void)logWithIdentifier:(const char *)identifier level:(uint32_t)level
                     path:(const char *)path line:(uint32_t)line
                 function:(const char *)function
                   format:(NSString *)format, ... __attribute__((format(__NSString__, 6, 7)));


//
// Configuration.
//


// Returns/sets the path of the log file. Setting the path implies a reset.
+ (NSString *)path;
+ (void)setPath:(NSString *)path;

// Returns the path of the backup log file.
+ (NSString *)path0;

// Returns/sets whether log messages get appended to an existing log file on
// startup.
+ (BOOL)appendsToExistingLogFile;
+ (void)setAppendsToExistingLogFile:(BOOL)value;

// Returns/sets the maximum size of the log file (as defined by
// _LCLLogFile_MaxLogFileSizeInBytes).
+ (size_t)maxSize;
+ (void)setMaxSize:(size_t)value;

// Returns/sets whether log messages are mirrored to stderr.
+ (BOOL)mirrorsToStdErr;
+ (void)setMirrorsToStdErr:(BOOL)value;

// Returns/sets whether ('\\' and) '\n' line feed characters are escaped in
// log messages.
+ (BOOL)escapesLineFeeds;
+ (void)setEscapesLineFeeds:(BOOL)value;

// Returns/sets the maximum size of a log message in characters (without
// prefixes). The value 0 indicates that there is no maximum size for log
// messages.
+ (NSUInteger)maxMessageSize;
+ (void)setMaxMessageSize:(NSUInteger)value;

// Returns/sets whether file names are shown.
+ (BOOL)showsFileNames;
+ (void)setShowsFileNames:(BOOL)value;

// Returns/sets whether line numbers are shown.
+ (BOOL)showsLineNumbers;
+ (void)setShowsLineNumbers:(BOOL)value;

// Returns/sets whether function names are shown.
+ (BOOL)showsFunctionNames;
+ (void)setShowsFunctionNames:(BOOL)value;


//
// Status information and internals.
//


// Returns the current size of the log file.
+ (size_t)size;

// Returns the version of LCLLogFile.
+ (NSString *)version;

// Opens the log file.
+ (void)open;

// Closes the log file.
+ (void)close;

// Resets the log file. This also deletes the existing log file.
+ (void)reset;

// Rotates the log file.
+ (void)rotate;


//
// Methods for creating log file paths.
//


// Returns a default path for a log file which is based on the Info.plist
// files which are associated with this class. The returned path has the form
//   ~/Library/Logs/<main>/<this>.log
// where
//   <main> is the name (or identifier) of the application's main bundle, and
//   <this> is the name (or identifier) of the bundle to which this LCLLogFile
//          class belongs.
// This method is a convenience method which calls defaultPathWithPathPrefix
// with the prefix ~/Library/Logs and the given fallback path.
+ (NSString *)defaultPathInHomeLibraryLogsOrPath:(NSString *)path;

// Returns a default path for a log file which is based on the Info.plist
// files which are associated with this class. The returned path has the form
//   <path>/<main>/<this>.log
// where
//   <path> is the given path prefix,
//   <main> is the name (or identifier) of the application's main bundle, and
//   <this> is the name (or identifier) of the bundle to which this LCLLogFile
//          class belongs.
// If the name or identifier cannot be retrieved from the main bundle, the
// returned default path has the form
//   <path>/<this>/<this>.<pid>.log
// where
//   <pid> is the current process id.
// If the name or identifier cannot be retrieved from the bundle which
// corresponds to this LCLLogFile class, or if the given path prefix <path> is
// nil, the given fallback path is returned.
+ (NSString *)defaultPathWithPathPrefix:(NSString *)pathPrefix
                                 orPath:(NSString *)path;

// Returns a default path component for a log file which is based on the given
// bundles' Info.plist files. The returned path has the form
//   <path>/<file>.log
// where
//   <path> is the name (or identifier) of the given path bundle, and
//   <file> is the name (or identifier) of the given file bundle.
// If the name or identifier cannot be retrieved from the path bundle, the
// returned default path has the form
//   <file>/<file>.<pid>.log
// where
//   <pid> is the current process id.
// If the name or identifier cannot be retrieved from the file bundle, the
// given fallback path component is returned.
+ (NSString *)defaultPathComponentFromPathBundle:(NSBundle *)pathBundle
                                      fileBundle:(NSBundle *)fileBundle
                                 orPathComponent:(NSString *)pathComponent;

// Returns the name from the given bundle's Info.plist file. If the name doesn't
// exist, the bundle's identifier is returned. If the identifier doesn't exist,
// the given fallback string is returned.
+ (NSString *)nameOrIdentifierFromBundle:(NSBundle *)bundle
                                orString:(NSString *)string;


@end


//
// Integration with LibComponentLogging Core.
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


// Define the _lcl_logger macro which integrates LCLLogFile as a logging
// back-end for LibComponentLogging and pass the header of a log component as
// the identifier to LCLLogFile's log method.
#define _lcl_logger(_component, _level, _format, ...) {                        \
    _lcl_logger_autoreleasepool_begin                                          \
    [LCLLogFile logWithIdentifier:_lcl_component_header[_component]            \
                            level:_level                                       \
                             path:__FILE__                                     \
                             line:__LINE__                                     \
                         function:__PRETTY_FUNCTION__                          \
                           format:_format,                                     \
                               ## __VA_ARGS__];                                \
    _lcl_logger_autoreleasepool_end                                            \
}

