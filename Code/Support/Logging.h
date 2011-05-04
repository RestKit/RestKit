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

#ifdef DEBUG
    #define RKLOG_NETWORK(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"Network",level,__VA_ARGS__)
    #define RKLOG_MAPPING(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"Object Mapping",level,__VA_ARGS__)
    #define RKLOG_GENERAL(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"General",level,__VA_ARGS__)
#else
    #define RKLOG_NETWORK(...)    do{}while(0)
    #define RKLOG_MAPPING(...)    do{}while(0)
    #define RKLOG_GRAPHICS(...)   do{}while(0)
#endif
