//
//
// LCLLogFile.m
//
//
// Copyright (c) 2008-2010 Arne Harren <ah@0xc0.de>
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

#import "LCLLogFile.h"

#include <unistd.h>
#include <mach/mach_init.h>
#include <sys/time.h>
#include <sys/stat.h>


//
// Configuration checks.
//


#ifndef LCLLogFile
#error  'LCLLogFile' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_LogFilePath
#error  '_LCLLogFile_LogFilePath' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_AppendToExistingLogFile
#error  '_LCLLogFile_AppendToExistingLogFile' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_MaxLogFileSizeInBytes
#error  '_LCLLogFile_MaxLogFileSizeInBytes' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_MirrorMessagesToStdErr
#error  '_LCLLogFile_MirrorMessagesToStdErr' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_EscapeLineFeeds
#error  '_LCLLogFile_EscapeLineFeeds' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_MaxMessageSizeInCharacters
#error  '_LCLLogFile_MaxMessageSizeInCharacters' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_ShowFileNames
#error  '_LCLLogFile_ShowFileNames' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_ShowLineNumbers
#error  '_LCLLogFile_ShowLineNumbers' must be defined in LCLLogFileConfig.h
#endif

#ifndef _LCLLogFile_ShowFunctionNames
#error  '_LCLLogFile_ShowFunctionNames' must be defined in LCLLogFileConfig.h
#endif


//
// Fields.
//


// A lock which is held when the log file is used, opened, etc.
static NSRecursiveLock *_LCLLogFile_lock = nil;

// A handle to the current log file, if opened.
static volatile FILE *_LCLLogFile_fileHandle = NULL;

// YES, if logging is active.
static volatile BOOL _LCLLogFile_isActive = NO;

// YES, if log messages should be appended to an existing log file.
static BOOL _LCLLogFile_appendToExistingLogFile = NO;

// YES, if log messages should be mirrored to stderr.
static BOOL _LCLLogFile_mirrorToStdErr = NO;

// YES, if '\\' and '\n' characters should be escaped in log messages.
static BOOL _LCLLogFile_escapeLineFeeds = NO;

// YES, if the file name should be shown.
static BOOL _LCLLogFile_showFileName = NO;

// YES, if the line number should be shown.
static BOOL _LCLLogFile_showLineNumber = NO;

// YES, if the function name should be shown.
static BOOL _LCLLogFile_showFunctionName = NO;

// Max size of a log message (without prefixes).
static NSUInteger _LCLLogFile_maxMessageSize = 0;

// Max size of log file.
static size_t _LCLLogFile_fileSizeMax = 0;

// Current size of log file.
static size_t _LCLLogFile_fileSize = 0;

// Paths of log files.
static NSString *_LCLLogFile_filePath = nil;
static const char *_LCLLogFile_filePath_c = NULL;
static NSString *_LCLLogFile_filePath0 = nil;
static const char *_LCLLogFile_filePath0_c = NULL;

// The process id.
static pid_t _LCLLogFile_processId = 0;

// The log level headers we use.
const char * const _LCLLogFile_levelHeader[] = {
    "-",
    "C",
    "E",
    "W",
    "I",
    "D",
    "T"
};


@implementation LCLLogFile


//
// Initialization.
//


// No instances, please.
+(id)alloc {
    [LCLLogFile doesNotRecognizeSelector:_cmd];
    return nil;
}

// Initializes the class.
+ (void)initialize {
    // perform initialization only once
    if (self != [LCLLogFile class])
        return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // create the lock
    _LCLLogFile_lock = [[NSRecursiveLock alloc] init];
    
    // get the process id
    _LCLLogFile_processId = getpid();
    
    // get the max file size, at least 4k
    _LCLLogFile_fileSizeMax = (_LCLLogFile_MaxLogFileSizeInBytes);
    if (_LCLLogFile_fileSizeMax < 4 * 1024) {
        _LCLLogFile_fileSizeMax = 4 * 1024;
    }
    
    // get whether we should append to an existing log file
    _LCLLogFile_appendToExistingLogFile = (_LCLLogFile_AppendToExistingLogFile);
    
    // get whether we should mirror log messages to stderr
    _LCLLogFile_mirrorToStdErr = (_LCLLogFile_MirrorMessagesToStdErr);
    
    // get whether we should escape '\\' and '\n' characters in log messages
    _LCLLogFile_escapeLineFeeds = (_LCLLogFile_EscapeLineFeeds);
    
    // get max size of a log message
    _LCLLogFile_maxMessageSize = (_LCLLogFile_MaxMessageSizeInCharacters);
    
    // get whether we should show file names
    _LCLLogFile_showFileName = (_LCLLogFile_ShowFileNames);
    
    // get whether we should show line numbers
    _LCLLogFile_showLineNumber = (_LCLLogFile_ShowLineNumbers);
    
    // get whether we should show function names
    _LCLLogFile_showFunctionName = (_LCLLogFile_ShowFunctionNames);
    
    // get the full path of the log file
    NSString *path = (_LCLLogFile_LogFilePath);
    
    // create log file paths
    _LCLLogFile_filePath = nil;
    _LCLLogFile_filePath_c = NULL;
    _LCLLogFile_filePath0 = nil;
    _LCLLogFile_filePath0_c = NULL;
    if (path != nil) {
        // standardize the given path
        path = [path stringByStandardizingPath];
        
        // create parent paths
        NSString *parentpath = [path stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:parentpath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
        
        // create the path of the backup file
        NSString *path0 = [path stringByAppendingString:@".0"];
        
        // create the paths' file system representations
        CFIndex path_c_max_len = CFStringGetMaximumSizeOfFileSystemRepresentation((CFStringRef)path);
        CFIndex path0_c_max_len = CFStringGetMaximumSizeOfFileSystemRepresentation((CFStringRef)path);
        
        char *path_c = malloc(path_c_max_len);
        char *path0_c = malloc(path0_c_max_len);
        
        Boolean path_fsr_created = CFStringGetFileSystemRepresentation((CFStringRef)path, path_c, path_c_max_len);
        Boolean path0_fsr_created = CFStringGetFileSystemRepresentation((CFStringRef)path0, path0_c, path0_c_max_len);
        
        // create local copies of the paths
        if (path_fsr_created && path0_fsr_created) {
            _LCLLogFile_filePath = [path copy];
            _LCLLogFile_filePath_c = strdup(path_c);
            _LCLLogFile_filePath0 = [path0 copy];
            _LCLLogFile_filePath0_c = strdup(path0_c);
        }
        
        free(path_c);
        free(path0_c);
    }
    
    // creation of paths failed? fall back to stderr
    if (_LCLLogFile_filePath_c == NULL) {
        NSLog(@"error: invalid log file path '%@'", path);
        _LCLLogFile_mirrorToStdErr = YES;
    }
    
    // log file size is zero
    _LCLLogFile_fileSize = 0;
    
    [pool release];
}


//
// Logging methods.
//


// Creates the log message prefix.
static NSString *_LCLLogFile_prefix(const char *identifier_c, uint32_t level,
                                    const char *path_c, uint32_t line,
                                    const char *function_c) {
    // get settings
    const int show_file = _LCLLogFile_showFileName;
    const int show_line = _LCLLogFile_showLineNumber;
    const int show_function = _LCLLogFile_showFunctionName;
    
    // get file name from path
    const char *file_c = NULL;
    if (show_file) {
        file_c = path_c != NULL ? strrchr(path_c, '/') : NULL;
        file_c = (file_c != NULL) ? (file_c + 1) : (path_c);
    }
    
    // get line
    char line_c[11];
    if (show_line) {
        snprintf(line_c, sizeof(line_c), "%u", line);
        line_c[sizeof(line_c) - 1] = '\0';
    }
    
    // get the level header
    char level_ca[11];
    const char *level_c;
    if (level < sizeof(_LCLLogFile_levelHeader)/sizeof(const char *)) {
        // a known level, e.g. E, W, I
        level_c = _LCLLogFile_levelHeader[level];
    } else {
        // unknown level, use the level number
        snprintf(level_ca, sizeof(level_ca), "%u", level);
        level_c = level_ca;
    }
    
    // create prefix
    NSString *prefix = [NSString stringWithFormat:@" %u:%x %s %s%s%s%s%s%s%s ",
                        /*    */
                        /* %u */ _LCLLogFile_processId,
                        /* %x */ mach_thread_self(),
                        /*    */
                        /* %s */ level_c,
                        /*    */
                        /* %s */ identifier_c,
                        /* %s */ show_file ? ":" : "",
                        /* %s */ show_file ? file_c : "",
                        /* %s */ show_line ? ":" : "",
                        /* %s */ show_line ? line_c : "",
                        /* %s */ show_function ? ":" : "",
                        /* %s */ show_function ? function_c : ""
                        /*    */
                        ];
    
    return prefix;
}

// Writes the given log message to the log file (internal).
static void _LCLLogFile_log(const char *identifier_c, uint32_t level,
                            const char *path_c, uint32_t line,
                            const char *function_c,
                            NSString *message) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // create the prefix
    NSString *prefix = _LCLLogFile_prefix(identifier_c, level, path_c, line, function_c);
    
    // restrict size of log message
    if (_LCLLogFile_maxMessageSize != 0) {
        NSUInteger message_len = [message length];
        if (message_len > _LCLLogFile_maxMessageSize) {
            message = [message substringToIndex:_LCLLogFile_maxMessageSize];
        }
    }
    
    // escape '\\' and '\n' characters
    if (_LCLLogFile_escapeLineFeeds) {
        NSMutableString *emessage = [[[NSMutableString alloc] initWithCapacity:[message length] * 2] autorelease];
        [emessage appendString:message];
        [emessage replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, [emessage length])];
        [emessage replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, [emessage length])];
        message = emessage;
    }
    
    // create C strings
    const char *prefix_c = [prefix UTF8String];
    const char *message_c = [message UTF8String];
    
    // get size of log entry
    const int time_c_len = 24;
    const int backslash_n_len = 1;
    size_t entry_len = time_c_len + strlen(prefix_c) + strlen(message_c) + backslash_n_len;
    
    // under lock protection ...
    [_LCLLogFile_lock lock];
    {
        FILE *filehandle = (FILE *)_LCLLogFile_fileHandle;
        
        // rotate the log file if required
        if (filehandle) {
            if (_LCLLogFile_fileSize + entry_len > _LCLLogFile_fileSizeMax) {
                [LCLLogFile rotate];
                [LCLLogFile open];
                filehandle = (FILE *)_LCLLogFile_fileHandle;
            }
        }
        
        // get current time
        struct timeval now;
        struct tm now_tm;
        char time_c[time_c_len];
        gettimeofday(&now, NULL);
        localtime_r(&now.tv_sec, &now_tm);
        snprintf(time_c, sizeof(time_c), "%04d-%02d-%02d %02d:%02d:%02d.%03d",
                 now_tm.tm_year + 1900,
                 now_tm.tm_mon + 1,
                 now_tm.tm_mday,
                 now_tm.tm_hour,
                 now_tm.tm_min,
                 now_tm.tm_sec,
                 now.tv_usec / 1000);
        
        // write the log message
        if (filehandle) {
            // increase file size
            _LCLLogFile_fileSize += entry_len;
            
            // write current time and log message
            fprintf(filehandle, "%s%s%s\n", time_c, prefix_c, message_c);
            
            // flush the file
            fflush(filehandle);
        }
        
        // mirror to stderr?
        if (_LCLLogFile_mirrorToStdErr) {
#           ifndef __LCLLogFile_stderr
#           define __LCLLogFile_stderr stderr
#           endif
            fprintf(__LCLLogFile_stderr, "%s%s%s\n", time_c, prefix_c, message_c);
        }
    }
    // ... done
    [_LCLLogFile_lock unlock];
    
    [pool release];
}

// Writes the given log message to the log file (message).
+ (void)logWithIdentifier:(const char *)identifier level:(uint32_t)level
                     path:(const char *)path line:(uint32_t)line
                 function:(const char *)function
                  message:(NSString *)message {
    // open the log file
    if (!_LCLLogFile_isActive) {
        [LCLLogFile open];
    }
    
    // write log message if the log file is opened or mirroring is enabled
    if (_LCLLogFile_fileHandle || _LCLLogFile_mirrorToStdErr) {
        // write log message
        _LCLLogFile_log(identifier, level, path, line, function, message);
    }
}

// Writes the given log message to the log file (format and va_list var args).
+ (void)logWithIdentifier:(const char *)identifier level:(uint32_t)level
                     path:(const char *)path line:(uint32_t)line
                 function:(const char *)function
                   format:(NSString *)format args:(va_list)args {
    // open the log file
    if (!_LCLLogFile_isActive) {
        [LCLLogFile open];
    }
    
    // write log message if the log file is opened or mirroring is enabled
    if (_LCLLogFile_fileHandle || _LCLLogFile_mirrorToStdErr) {
        // create log message
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        
        // write log message
        _LCLLogFile_log(identifier, level, path, line, function, message);
        
        // release local objects
        [message release];
    }
}

// Writes the given log message to the log file (format and ... var args).
+ (void)logWithIdentifier:(const char *)identifier level:(uint32_t)level
                     path:(const char *)path line:(uint32_t)line
                 function:(const char *)function
                   format:(NSString *)format, ... {
    // open the log file
    if (!_LCLLogFile_isActive) {
        [LCLLogFile open];
    }
    
    // write log message if the log file is opened or mirroring is enabled
    if (_LCLLogFile_fileHandle || _LCLLogFile_mirrorToStdErr) {
        // create log message
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        // write log message
        _LCLLogFile_log(identifier, level, path, line, function, message);
        
        // release local objects
        [message release];
    }
}


//
// Configuration.
//


// Returns the path of the log file.
+ (NSString *)path {
    return _LCLLogFile_filePath;
}

// Returns the path of the backup log file.
+ (NSString *)path0 {
    return _LCLLogFile_filePath0;
}

// Returns whether log messages get appended to an existing log file on startup.
+ (BOOL)appendsToExistingLogFile {
    return _LCLLogFile_appendToExistingLogFile;
}

// Returns/sets the maximum size of the log file (as defined by
// _LCLLogFile_MaxLogFileSizeInBytes).
+ (size_t)maxSize {
    return _LCLLogFile_fileSizeMax;
}
+ (void)setMaxSize:(size_t)value {
    [_LCLLogFile_lock lock];
    {
        _LCLLogFile_fileSizeMax = value;
        if (_LCLLogFile_fileSizeMax < 4 * 1024) {
            _LCLLogFile_fileSizeMax = 4 * 1024;
        }
    }
    [_LCLLogFile_lock unlock];
}

// Returns/sets whether log messages are mirrored to stderr.
+ (BOOL)mirrorsToStdErr {
    return _LCLLogFile_mirrorToStdErr;
}
+ (void)setMirrorsToStdErr:(BOOL)value {
    [_LCLLogFile_lock lock];
    {
        _LCLLogFile_mirrorToStdErr = value;
    }
    [_LCLLogFile_lock unlock];
}

// Returns/sets whether ('\\' and) '\n' line feed characters are escaped in
// log messages.
+ (BOOL)escapesLineFeeds {
    return _LCLLogFile_escapeLineFeeds;
}
+ (void)setEscapesLineFeeds:(BOOL)value {
    [_LCLLogFile_lock lock];
    {
        _LCLLogFile_escapeLineFeeds = value;
    }
    [_LCLLogFile_lock unlock];
}

// Returns/sets the maximum size of a log message in characters (without
// prefixes). The value 0 indicates that there is no maximum size for log
// messages.
+ (NSUInteger)maxMessageSize {
    return _LCLLogFile_maxMessageSize;
}
+ (void)setMaxMessageSize:(NSUInteger)value {
    [_LCLLogFile_lock lock];
    {
        _LCLLogFile_maxMessageSize = value;
    }
    [_LCLLogFile_lock unlock];
}

// Returns/sets whether file names are shown.
+ (BOOL)showsFileNames {
    return _LCLLogFile_showFileName;
}
+ (void)setShowsFileNames:(BOOL)value {
    [_LCLLogFile_lock lock];
    {
        _LCLLogFile_showFileName = value;
    }
    [_LCLLogFile_lock unlock];
}

// Returns/sets whether line numbers are shown.
+ (BOOL)showsLineNumbers {
    return _LCLLogFile_showLineNumber;
}
+ (void)setShowsLineNumbers:(BOOL)value {
    [_LCLLogFile_lock lock];
    {
        _LCLLogFile_showLineNumber = value;
    }
    [_LCLLogFile_lock unlock];
}

// Returns/sets whether function names are shown.
+ (BOOL)showsFunctionNames {
    return _LCLLogFile_showFunctionName;
}
+ (void)setShowsFunctionNames:(BOOL)value {
    [_LCLLogFile_lock lock];
    {
        _LCLLogFile_showFunctionName = value;
    }
    [_LCLLogFile_lock unlock];
}


//
// Status information and internals.
//


// Returns the current size of the log file.
+ (size_t)size {
    size_t sz = 0;
    [_LCLLogFile_lock lock];
    {
        // get the size
        sz = _LCLLogFile_fileSize;
    }
    [_LCLLogFile_lock unlock];
    return sz;
}

// Returns the version of LCLLogFile.
+ (NSString *)version {
#define __lcl_version_to_string( _text) __lcl_version_to_string0(_text)
#define __lcl_version_to_string0(_text) #_text
    return @__lcl_version_to_string(_LCLLOGFILE_VERSION_MAJOR)
    "."     __lcl_version_to_string(_LCLLOGFILE_VERSION_MINOR)
    "."     __lcl_version_to_string(_LCLLOGFILE_VERSION_BUILD)
    ""      _LCLLOGFILE_VERSION_SUFFIX;
}

// Opens the log file.
+ (void)open {
    [_LCLLogFile_lock lock];
    {
        if (_LCLLogFile_fileHandle == NULL) {
            // size of log file is 0
            _LCLLogFile_fileSize = 0;
            
            if (_LCLLogFile_isActive || !_LCLLogFile_appendToExistingLogFile) {
                // create a new log file
                _LCLLogFile_fileHandle = NULL;
                if (_LCLLogFile_filePath_c != NULL) {
                    _LCLLogFile_fileHandle = fopen(_LCLLogFile_filePath_c, "w");
                }
            } else {
                // append to existing log file, get size from file
                _LCLLogFile_fileHandle = NULL;
                if (_LCLLogFile_filePath_c != NULL) {
                    _LCLLogFile_fileHandle = fopen(_LCLLogFile_filePath_c, "a");
                }
                
                // try to get size of existing log file
                struct stat stat_c;
                if (_LCLLogFile_filePath_c != NULL && stat(_LCLLogFile_filePath_c, &stat_c) == 0) {
                    _LCLLogFile_fileSize = (size_t)stat_c.st_size;
                }
            }
            
            // logging is active
            _LCLLogFile_isActive = YES;
        }
    }
    [_LCLLogFile_lock unlock];
}

// Closes the log file.
+ (void)close {
    [_LCLLogFile_lock lock];
    {
        // close the log file
        FILE *filehandle = (FILE *)_LCLLogFile_fileHandle;
        if (filehandle != NULL) {
            fclose(filehandle);
            _LCLLogFile_fileHandle = NULL;
        }
        
        // log file size is zero
        _LCLLogFile_fileSize = 0;
    }
    [_LCLLogFile_lock unlock];
}

// Resets the log file.
+ (void)reset {
    [_LCLLogFile_lock lock];
    {
        // close the log file
        [LCLLogFile close];
        
        // unlink existing log files
        if (_LCLLogFile_filePath_c != NULL) {
            unlink(_LCLLogFile_filePath_c);
        }
        if (_LCLLogFile_filePath0_c != NULL) {
            unlink(_LCLLogFile_filePath0_c);
        }
        
        // logging is not active
        _LCLLogFile_isActive = NO;
        
    }
    [_LCLLogFile_lock unlock];
}

// Rotates the log file.
+ (void)rotate {
    [_LCLLogFile_lock lock];
    {
        // close the log file
        [LCLLogFile close];
        
        // keep a copy of the current log file
        if (_LCLLogFile_filePath_c != NULL && _LCLLogFile_filePath0_c != NULL) {
            rename(_LCLLogFile_filePath_c, _LCLLogFile_filePath0_c);
        }
    }
    [_LCLLogFile_lock unlock];
}


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
+ (NSString *)defaultPathInHomeLibraryLogsOrPath:(NSString *)path {
    return [LCLLogFile defaultPathWithPathPrefix:
            [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs"]
                                          orPath:path];
}

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
                                 orPath:(NSString *)path {
    // get the main bundle and the bundle which corresponds to this class
    NSBundle *pathBundle = [NSBundle mainBundle];
    NSBundle *fileBundle = [NSBundle bundleForClass:[LCLLogFile class]];
    
    NSString *pathComponent = [LCLLogFile defaultPathComponentFromPathBundle:pathBundle
                                                                  fileBundle:fileBundle
                                                             orPathComponent:nil];
    
    if (pathPrefix != nil && pathComponent != nil) {
        return [pathPrefix stringByAppendingPathComponent:pathComponent];
    } else {
        return path;
    }
}

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
                                 orPathComponent:(NSString *)pathComponent {
    NSString *pathName = [LCLLogFile nameOrIdentifierFromBundle:pathBundle
                                                       orString:nil];
    NSString *fileName = [LCLLogFile nameOrIdentifierFromBundle:fileBundle
                                                       orString:nil];
    
    if (pathName != nil && fileName != nil) {
        // we have a path name and a file name
        return [NSString stringWithFormat:@"%@/%@.log", pathName, fileName];
    } else if (pathName == nil && fileName != nil) {
        // we don't have a path name, but a file name, use the file name as
        // the path name and append the pid to the file name to avoid collisions
        return [NSString stringWithFormat:@"%@/%@.%u.log", fileName, fileName, getpid()];
    } else {
        // no information from the bundles, fail
        return pathComponent;
    }
}

// Returns the name from the given bundle's Info.plist file. If the name doesn't
// exist, the bundle's identifier is returned. If the identifier doesn't exist,
// the given fallback string is returned.
+ (NSString *)nameOrIdentifierFromBundle:(NSBundle *)bundle
                                orString:(NSString *)string {
    id bundleName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
    if (bundleName != nil && [bundleName isKindOfClass:[NSString class]]) {
        return (NSString *)bundleName;
    }
    NSString *bundleIdentifier = [bundle bundleIdentifier];
    if (bundleIdentifier != nil) {
        return bundleIdentifier;
    }
    return string;
}

@end

