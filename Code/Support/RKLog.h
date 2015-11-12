//
//  RKLog.h
//  RestKit
//
//  Created by Blake Watters on 5/3/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

/**
 RestKit Logging is based on the LibComponentLogging framework

 @see lcl_config_components_RK.h
 @see lcl_config_logger_RK.h
 */
#import <RestKit/Support/lcl_RK.h>

/**
 * Protocol which classes can implement to determine how RestKit log messages actually get handled.
 * There is a single "current" logging class installed, which all log messages will flow
 * through.
 */
@protocol RKLogging

+ (void)logWithComponent:(_RKlcl_component_t)component
                   level:(_RKlcl_level_t)level
                    path:(const char *)file
                    line:(uint32_t)line
                function:(const char *)function
                  format:(NSString *)format, ... NS_FORMAT_FUNCTION(6, 7);

@end

/**
 * Functions to get and set the current RKLogging class.
 */
Class <RKLogging> RKGetLoggingClass(void);
void RKSetLoggingClass(Class <RKLogging> loggingClass);



/**
 RKLogComponent defines the active component within any given portion of RestKit

 By default, messages will log to the base 'RestKit' log component. All other components
 used by RestKit are nested under this parent, so this effectively sets the default log
 level for the entire library.

 The component can be undef'd and redefined to change the active logging component.
 */
#define RKLogComponent RKlcl_cRestKit

/**
 The logging macros. These macros will log to the currently active logging component
 at the log level identified in the name of the macro.

 For example, in the `RKMappingOperation` class we would redefine the RKLogComponent:

    #undef RKLogComponent
    #define RKLogComponent RKlcl_cRestKitObjectMapping

 The RKlcl_c prefix is the LibComponentLogging data structure identifying the logging component
 we want to target within this portion of the codebase. See lcl_config_component_RK.h for reference.

 Having defined the logging component, invoking the logger via:

    RKLogInfo(@"This is my log message!");

 Would result in a log message similar to:

    I RestKit.ObjectMapping:RKLog.h:42 This is my log message!

 The message will only be logged if the log level for the active component is equal to or higher
 than the level the message was logged at (in this case, Info).
 */
#define RKLogCritical(...)                                                              \
RKlcl_log(RKLogComponent, RKlcl_vCritical, @"" __VA_ARGS__)

#define RKLogError(...)                                                                 \
RKlcl_log(RKLogComponent, RKlcl_vError, @"" __VA_ARGS__)

#define RKLogWarning(...)                                                               \
RKlcl_log(RKLogComponent, RKlcl_vWarning, @"" __VA_ARGS__)

#define RKLogInfo(...)                                                                  \
RKlcl_log(RKLogComponent, RKlcl_vInfo, @"" __VA_ARGS__)

#define RKLogDebug(...)                                                                 \
RKlcl_log(RKLogComponent, RKlcl_vDebug, @"" __VA_ARGS__)

#define RKLogTrace(...)                                                                 \
RKlcl_log(RKLogComponent, RKlcl_vTrace, @"" __VA_ARGS__)

/**
 Log Level Aliases

 These aliases simply map the log levels defined within LibComponentLogger to something more friendly
 */
#define RKLogLevelOff       RKlcl_vOff
#define RKLogLevelCritical  RKlcl_vCritical
#define RKLogLevelError     RKlcl_vError
#define RKLogLevelWarning   RKlcl_vWarning
#define RKLogLevelInfo      RKlcl_vInfo
#define RKLogLevelDebug     RKlcl_vDebug
#define RKLogLevelTrace     RKlcl_vTrace

/**
 Alias the LibComponentLogger logging configuration method. Also ensures logging
 is initialized for the framework.

 Expects the name of the component and a log level.

 Examples:

    // Log debugging messages from the Network component
    RKLogConfigureByName("RestKit/Network", RKLogLevelDebug);

    // Log only critical messages from the Object Mapping component
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelCritical);
 */
#define RKLogConfigureByName(name, level)                                               \
RKlcl_configure_by_name(name, level);

/**
 Alias for configuring the LibComponentLogger logging component for the App. This
 enables the end-user of RestKit to leverage RKLog() to log messages inside of
 their apps.
 */
#define RKLogSetAppLoggingLevel(level)                                                  \
RKlcl_configure_by_name("App", level);

/**
 Temporarily changes the logging level for the specified component and executes the block. Any logging
 statements executed within the body of the block against the specified component will log at the new
 logging level. After the block has executed, the logging level is restored to its previous state.
 */
#define RKLogToComponentWithLevelWhileExecutingBlock(_component, _level, _block)        \
    do {                                                                                \
        int _currentLevel = _RKlcl_component_level[_component];                           \
        RKlcl_configure_by_component(_component, _level);                                 \
        @try {                                                                          \
            _block();                                                                   \
        }                                                                               \
        @catch (NSException *exception) {                                               \
            @throw;                                                                     \
        }                                                                               \
        @finally {                                                                      \
            RKlcl_configure_by_component(_component, _currentLevel);                      \
        }                                                                               \
    } while (false);

/**
 Temporarily turns off logging for the given logging component during execution of the block.
 After the block has finished execution, the logging level is restored to its previous state.
 */
#define RKLogSilenceComponentWhileExecutingBlock(component, _block)                      \
    RKLogToComponentWithLevelWhileExecutingBlock(component, RKLogLevelOff, _block)

/**
 Temporarily changes the logging level for the configured RKLogComponent and executes the block. Any logging
 statements executed within the body of the block for the current logging component will log at the new
 logging level. After the block has finished execution, the logging level is restored to its previous state.
 */
#define RKLogWithLevelWhileExecutingBlock(_level, _block)                               \
    RKLogToComponentWithLevelWhileExecutingBlock(RKLogComponent, _level, _block)


/**
 Temporarily turns off logging for current logging component during execution of the block.
 After the block has finished execution, the logging level is restored to its previous state.
 */
#define RKLogSilenceWhileExecutingBlock(_block)                                        \
    RKLogToComponentWithLevelWhileExecutingBlock(RKLogComponent, RKLogLevelOff, _block)


/**
 Set the Default Log Level

 Based on the presence of the DEBUG flag, we default the logging for the RestKit parent component
 to Info or Warning.

 You can override this setting by defining RKLogLevelDefault as a pre-processor macro.
 */
#ifndef RKLogLevelDefault
    #ifdef DEBUG
        #define RKLogLevelDefault RKLogLevelInfo
    #else
        #define RKLogLevelDefault RKLogLevelWarning
    #endif
#endif

/**
 Configure RestKit logging from environment variables.
 (Use Option + Command + R to set Environment Variables prior to run.)

 For example to configure the equivalent of setting the following in code:
 RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);

 Define an environment variable named 'RKLogLevel.RestKit.Network' and set its value to "Trace"

 See lcl_config_components_RK.h for configurable RestKit logging components.

 Valid values are the following:
    Default  or 0
    Critical or 1
    Error    or 2
    Warning  or 3
    Info     or 4
    Debug    or 5
    Trace    or 6
 */
void RKLogConfigureFromEnvironment(void);

/**
 Logs extensive information about an NSError generated as the results
 of a failed key-value validation error.
 */
void RKLogValidationError(NSError *error);

#ifdef _COREDATADEFINES_H
/**
 Logs extensive information an NSError generated as the result of a
 failed Core Data interaction, such as the execution of a fetch request
 or the saving of a managed object context.

 The error will be logged to the RestKit/CoreData component with an
 error level of RKLogLevelError regardless of the current logging context
 at invocation time.
 */
void RKLogCoreDataError(NSError *error);
#endif

/**
 Logs the value of an NSUInteger as a binary string. Useful when
 examining integers containing bitmasked values.
 */
void RKLogIntegerAsBinary(NSUInteger);
