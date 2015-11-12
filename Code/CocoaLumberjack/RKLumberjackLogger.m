//
//  RKLumberjackLogger.m
//  Pods
//
//  Created by C_Lindberg,Carl on 10/31/14.
//
//

#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <RestKit/CocoaLumberjack/RKLumberjackLogger.h>

@implementation RKLumberjackLogger

+ (DDLogLevel)ddLogLevelFromRKLogLevel:(_RKlcl_level_t)rkLevel
{
    switch (rkLevel)
    {
        case RKLogLevelOff:      return DDLogLevelOff;
        case RKLogLevelCritical: return DDLogLevelError;
        case RKLogLevelError:    return DDLogLevelError;
        case RKLogLevelWarning:  return DDLogLevelWarning;
        case RKLogLevelInfo:     return DDLogLevelInfo;
        case RKLogLevelDebug:    return DDLogLevelDebug;
        case RKLogLevelTrace:    return DDLogLevelVerbose;
    }

    return DDLogLevelDebug;
}

+ (DDLogFlag)ddLogFlagFromRKLogLevel:(_RKlcl_level_t)rkLevel
{
    switch (rkLevel)
    {
        case RKLogLevelOff:      return 0;
        case RKLogLevelCritical: return DDLogFlagError;
        case RKLogLevelError:    return DDLogFlagError;
        case RKLogLevelWarning:  return DDLogFlagWarning;
        case RKLogLevelInfo:     return DDLogFlagInfo;
        case RKLogLevelDebug:    return DDLogFlagDebug;
        case RKLogLevelTrace:    return DDLogFlagVerbose;
    }

    return DDLogFlagDebug;
}

+ (_RKlcl_level_t)rkLogLevelFromDDLogLevel:(DDLogLevel)ddLogLevel
{
    if (ddLogLevel & DDLogFlagVerbose) return RKLogLevelTrace;
    if (ddLogLevel & DDLogFlagDebug)   return RKLogLevelDebug;
    if (ddLogLevel & DDLogFlagInfo)    return RKLogLevelInfo;
    if (ddLogLevel & DDLogFlagWarning) return RKLogLevelWarning;
    if (ddLogLevel & DDLogFlagError)   return RKLogLevelError;

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

    DDLogFlag flag = [self ddLogFlagFromRKLogLevel:level];
    DDLogLevel componentLevel = [self ddLogLevelFromRKLogLevel:_RKlcl_component_level[component]];
    BOOL async = LOG_ASYNC_ENABLED && ((flag & DDLogFlagError) == 0);

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

#import <RestKit/Support/lcl_config_components_RK.h>

#undef   _RKlcl_component
#define  _RKlcl_component(_identifier, _header, _name)                                       \
    @interface RKLumberjackLog##_identifier : NSObject <DDRegisteredDynamicLogging>          \
    @end                                                                                     \
    @implementation RKLumberjackLog##_identifier                                             \
    + (DDLogLevel)ddLogLevel {                                                                      \
        _RKlcl_level_t level = _RKlcl_component_level[RKlcl_c##_identifier];                 \
        return [RKLumberjackLogger ddLogLevelFromRKLogLevel:level];                          \
    }                                                                                        \
    + (void)ddSetLogLevel:(DDLogLevel)logLevel {                                                    \
        RKLogConfigureByName(_name, [RKLumberjackLogger rkLogLevelFromDDLogLevel:logLevel]); \
    }                                                                                        \
    @end

RKLCLComponentDefinitions

#undef   _RKlcl_component


#endif
