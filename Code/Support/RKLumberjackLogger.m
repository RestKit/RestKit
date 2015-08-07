//
//  RKLumberjackLogger.m
//  Pods
//
//  Created by C_Lindberg,Carl on 10/31/14.
//
//

#if __has_include("DDLog.h")
#import "RKLumberjackLogger.h"
#import "DDLog.h"

@implementation RKLumberjackLogger

+ (int)ddLogLevelFromRKLogLevel:(_RKlcl_level_t)rkLevel
{
    switch (rkLevel)
    {
        case RKLogLevelOff:      return LOG_LEVEL_OFF;
        case RKLogLevelCritical: return LOG_LEVEL_ERROR;
        case RKLogLevelError:    return LOG_LEVEL_ERROR;
        case RKLogLevelWarning:  return LOG_LEVEL_WARN;
        case RKLogLevelInfo:     return LOG_LEVEL_INFO;
        case RKLogLevelDebug:    return LOG_LEVEL_DEBUG;
        case RKLogLevelTrace:    return LOG_LEVEL_VERBOSE;
    }
    
    return LOG_LEVEL_DEBUG;
}

+ (int)ddLogFlagFromRKLogLevel:(_RKlcl_level_t)rkLevel
{
    switch (rkLevel)
    {
        case RKLogLevelOff:      return 0;
        case RKLogLevelCritical: return LOG_FLAG_ERROR;
        case RKLogLevelError:    return LOG_FLAG_ERROR;
        case RKLogLevelWarning:  return LOG_FLAG_WARN;
        case RKLogLevelInfo:     return LOG_FLAG_INFO;
        case RKLogLevelDebug:    return LOG_FLAG_DEBUG;
        case RKLogLevelTrace:    return LOG_FLAG_VERBOSE;
    }
    
    return LOG_FLAG_DEBUG;
}

+ (_RKlcl_level_t)rkLogLevelFromDDLogLevel:(int)ddLogLevel
{
    if (ddLogLevel & LOG_FLAG_VERBOSE) return RKLogLevelTrace;
    if (ddLogLevel & LOG_FLAG_DEBUG)   return RKLogLevelDebug;
    if (ddLogLevel & LOG_FLAG_INFO)    return RKLogLevelInfo;
    if (ddLogLevel & LOG_FLAG_WARN)    return RKLogLevelWarning;
    if (ddLogLevel & LOG_FLAG_ERROR)   return RKLogLevelError;
    
    return RKLogLevelOff;
}


#pragma mark RKLogging

+ (void)logWithComponent:(_RKlcl_component_t)component
                   level:(_RKlcl_level_t)level
                    path:(const char *)path
                    line:(uint32_t)line
                function:(const char *)function
                  format:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);

    int flag = [self ddLogFlagFromRKLogLevel:level];
    int componentLevel = [self ddLogLevelFromRKLogLevel:_RKlcl_component_level[component]];
    BOOL async = LOG_ASYNC_ENABLED && ((flag & LOG_FLAG_ERROR) == 0);

    [DDLog log:async
         level:componentLevel
          flag:flag
       context:0x524B5F00 + component
          file:path function:function line:line
           tag:nil
        format:format args:args];
    va_end(args);
}

@end

/* Create a DDRegisteredDynamicLogging class for each RestKit component */

#import "lcl_config_components_RK.h"

#undef   _RKlcl_component
#define  _RKlcl_component(_identifier, _header, _name)                                       \
    @interface RKLumberjackLog##_identifier : NSObject <DDRegisteredDynamicLogging>          \
    @end                                                                                     \
    @implementation RKLumberjackLog##_identifier                                             \
    + (int)ddLogLevel {                                                                      \
        _RKlcl_level_t level = _RKlcl_component_level[RKlcl_c##_identifier];                 \
        return [RKLumberjackLogger ddLogLevelFromRKLogLevel:level];                          \
    }                                                                                        \
    + (void)ddSetLogLevel:(int)logLevel {                                                    \
        RKLogConfigureByName(_name, [RKLumberjackLogger rkLogLevelFromDDLogLevel:logLevel]); \
    }                                                                                        \
    @end

RKLCLComponentDefinitions

#undef   _RKlcl_component


#endif
