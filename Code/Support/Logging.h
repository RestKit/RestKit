//
//  Logging.h
//  RestKit
//
//  Created by Blake Watters on 5/3/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

// Import the logger
#import "LoggerClient.h"

// Logging levels for use with the logger
enum RKLogLevels {
    RKLogLevelError = 0,
    RKLogLevelWarning,    
    RKLogLevelInfo,
    RKLogLevelDebug
};

//#ifdef DEBUG
    #define RKLOG_START_BLOCK(name) LogStartBlock(name)
    #define RKLOG_END_BLOCK()            LogEndBlock()
    #define RKLOG_NETWORK(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"Network",level,__VA_ARGS__)
    #define RKLOG_MAPPING(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"Object Mapping",level,__VA_ARGS__)
    #define RKLOG_GENERAL(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"General",level,__VA_ARGS__)
//#else
//    #define RKLOG_NETWORK(...)    do{}while(0)
//    #define RKLOG_MAPPING(...)    do{}while(0)
//    #define RKLOG_GRAPHICS(...)   do{}while(0)
//#endif

#if defined(DEBUG) && !defined(NDEBUG)
    #undef assert
    #if __DARWIN_UNIX03
        #define assert(e) \
            (__builtin_expect(!(e), 0) ? (CFShow(CFSTR("assert going to fail, connect NSLogger NOW\n")), LoggerFlush(NULL,YES), __assert_rtn(__func__, __FILE__, __LINE__, #e)) : (void)0)
    #else
        #define assert(e)  \
            (__builtin_expect(!(e), 0) ? (CFShow(CFSTR("assert going to fail, connect NSLogger NOW\n")), LoggerFlush(NULL,YES), __assert(#e, __FILE__, __LINE__)) : (void)0)
    #endif
#endif