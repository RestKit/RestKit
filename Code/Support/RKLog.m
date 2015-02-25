//
//  RKLog.m
//  RestKit
//
//  Created by Blake Watters on 6/10/11.
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

#import "RKLog.h"

@interface RKNSLogLogger : NSObject <RKLogging>
@end

#if RKLOG_USE_NSLOGGER && __has_include("LCLNSLogger_RK.h")
  #import "LCLNSLogger_RK.h"
  #define RKLOG_CLASS LCLNSLogger_RK

#elif __has_include("DDLog.h")
  #import "RKLumberjackLogger.h"
  #define RKLOG_CLASS RKLumberjackLogger

#else
  #define RKLOG_CLASS RKNSLogLogger
#endif

// Hook into Objective-C runtime to configure logging when we are loaded
@interface RKLogInitializer : NSObject
@end

@implementation RKLogInitializer

+ (void)load
{
    RKlcl_configure_by_name("RestKit*", RKLogLevelDefault);
    RKlcl_configure_by_name("App", RKLogLevelDefault);
    if (RKGetLoggingClass() == Nil) RKSetLoggingClass([RKLOG_CLASS class]);
    RKLogInfo(@"RestKit logging initialized...");
}

@end

static Class <RKLogging> RKLoggingClass;

Class <RKLogging> RKGetLoggingClass(void)
{
    return RKLoggingClass;
}

void RKSetLoggingClass(Class <RKLogging> loggingClass)
{
    RKLoggingClass = loggingClass;
}

@implementation RKNSLogLogger

+ (void)logWithComponent:(_RKlcl_component_t)component
                   level:(_RKlcl_level_t)level
                    path:(const char *)file
                    line:(uint32_t)line
                function:(const char *)function
                  format:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    const char *fileName = (fileName = strrchr(file, '/')) ? fileName + 1 : file;
    NSLog(@"%s %s:%s:%d %@", _RKlcl_level_header_1[level], _RKlcl_component_header[component], fileName, line, message);
}

@end

int RKLogLevelForString(NSString *, NSString *);

void RKLogConfigureFromEnvironment(void)
{
    static NSString *logComponentPrefix = @"RKLogLevel.";

    NSDictionary *envVars = [[NSProcessInfo processInfo] environment];

    for (NSString *envVarName in [envVars allKeys]) {
        if ([envVarName hasPrefix:logComponentPrefix]) {
            NSString *logLevel = [envVars valueForKey:envVarName];
            NSString *logComponent = [envVarName stringByReplacingOccurrencesOfString:logComponentPrefix withString:@""];
            logComponent = [logComponent stringByReplacingOccurrencesOfString:@"." withString:@"/"];

            const char *log_component_c_str = [logComponent cStringUsingEncoding:NSUTF8StringEncoding];
            int log_level_int = RKLogLevelForString(logLevel, envVarName);
            RKLogConfigureByName(log_component_c_str, log_level_int);
        }
    }
}


int RKLogLevelForString(NSString *logLevel, NSString *envVarName)
{
    // Forgive the user if they specify the full name for the value i.e. "RKLogLevelDebug" instead of "Debug"
    logLevel = [logLevel stringByReplacingOccurrencesOfString:@"RKLogLevel" withString:@""];

    if ([logLevel isEqualToString:@"Off"] ||
        [logLevel isEqualToString:@"0"]) {
        return RKLogLevelOff;
    }
    else if ([logLevel isEqualToString:@"Critical"] ||
             [logLevel isEqualToString:@"1"]) {
        return RKLogLevelCritical;
    }
    else if ([logLevel isEqualToString:@"Error"] ||
             [logLevel isEqualToString:@"2"]) {
        return RKLogLevelError;
    }
    else if ([logLevel isEqualToString:@"Warning"] ||
             [logLevel isEqualToString:@"3"]) {
        return RKLogLevelWarning;
    }
    else if ([logLevel isEqualToString:@"Info"] ||
             [logLevel isEqualToString:@"4"]) {
        return RKLogLevelInfo;
    }
    else if ([logLevel isEqualToString:@"Debug"] ||
             [logLevel isEqualToString:@"5"]) {
        return RKLogLevelDebug;
    }
    else if ([logLevel isEqualToString:@"Trace"] ||
             [logLevel isEqualToString:@"6"]) {
        return RKLogLevelTrace;
    }
    else if ([logLevel isEqualToString:@"Default"]) {
        return RKLogLevelDefault;
    }
    else {
        NSString *errorMessage = [NSString stringWithFormat:@"The value: \"%@\" for the environment variable: \"%@\" is invalid. \
                                  \nThe log level must be set to one of the following values \
                                  \n    Default  or 0 \
                                  \n    Critical or 1 \
                                  \n    Error    or 2 \
                                  \n    Warning  or 3 \
                                  \n    Info     or 4 \
                                  \n    Debug    or 5 \
                                  \n    Trace    or 6\n", logLevel, envVarName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:errorMessage userInfo:nil];

        return -1;
    }
}

void RKLogIntegerAsBinary(NSUInteger bitMask)
{
    NSUInteger bit = ~(NSUIntegerMax >> 1);
    NSMutableString *string = [NSMutableString string];
    do {
        [string appendString:(((NSUInteger)bitMask & bit) ? @"1" : @"0")];
    } while (bit >>= 1);
    
    NSLog(@"Value of %ld in binary: %@", (long)bitMask, string);
}

void RKLogValidationError(NSError *error)
{
#ifdef _COREDATADEFINES_H    
    if ([[error domain] isEqualToString:NSCocoaErrorDomain]) {
        NSDictionary *userInfo = [error userInfo];
        NSArray *errors = [userInfo valueForKey:@"NSDetailedErrors"];
        if (errors) {
            for (NSError *detailedError in errors) {
                NSDictionary *subUserInfo = [detailedError userInfo];
                RKLogError(@"Detailed Error\n \
                           NSLocalizedDescriptionKey:\t\t%@\n \
                           NSValidationKeyErrorKey:\t\t\t%@\n \
                           NSValidationPredicateErrorKey:\t%@\n \
                           NSValidationObjectErrorKey:\n%@\n",
                           [subUserInfo valueForKey:NSLocalizedDescriptionKey],
                           [subUserInfo valueForKey:NSValidationKeyErrorKey],
                           [subUserInfo valueForKey:NSValidationPredicateErrorKey],
                           [subUserInfo valueForKey:NSValidationObjectErrorKey]);
            }
        } else {
            RKLogError(@"Validation Error\n \
                       NSLocalizedDescriptionKey:\t\t%@\n \
                       NSValidationKeyErrorKey:\t\t\t%@\n \
                       NSValidationPredicateErrorKey:\t%@\n \
                       NSValidationObjectErrorKey:\n%@\n",
                       [userInfo valueForKey:NSLocalizedDescriptionKey],
                       [userInfo valueForKey:NSValidationKeyErrorKey],
                       [userInfo valueForKey:NSValidationPredicateErrorKey],
                       [userInfo valueForKey:NSValidationObjectErrorKey]);
        }
        return;
    }
#endif
    RKLogError(@"Validation Error: %@ (userInfo: %@)", error, [error userInfo]);
}

#ifdef _COREDATADEFINES_H
void RKLogCoreDataError(NSError *error)
{
    RKLogToComponentWithLevelWhileExecutingBlock(RKlcl_cRestKitCoreData, RKLogLevelError, ^{
        RKLogValidationError(error);
    });
}
#endif
