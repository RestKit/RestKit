//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/**
 * Three20 Debugging tools.
 *
 * Provided in this header are a set of debugging tools. This is meant quite literally, in that
 * all of the macros below will only function when the DEBUG preprocessor macro is specified.
 *
 * TTDASSERT(<statement>);
 * If <statement> is false, the statement will be written to the log and if you are running in
 * the simulator with a debugger attached, the app will break on the assertion line.
 *
 * TTDPRINT(@"formatted log text %d", param1);
 * Print the given formatted text to the log.
 *
 * TTDPRINTMETHODNAME();
 * Print the current method name to the log.
 *
 * TTDCONDITIONLOG(<statement>, @"formatted log text %d", param1);
 * If <statement> is true, then the formatted text will be written to the log.
 *
 * TTDINFO/TTDWARNING/TTDERROR(@"formatted log text %d", param1);
 * Will only write the formatted text to the log if TTMAXLOGLEVEL is greater than the respective
 * TTD* method's log level. See below for log levels.
 *
 * The default maximum log level is TTLOGLEVEL_WARNING.
 */

#define TTLOGLEVEL_INFO     5
#define TTLOGLEVEL_WARNING  3
#define TTLOGLEVEL_ERROR    1

#ifndef TTMAXLOGLEVEL
  #define TTMAXLOGLEVEL TTLOGLEVEL_WARNING
#endif

// The general purpose logger. This ignores logging levels.
#ifdef DEBUG
  #define TTDPRINT(xx, ...)  NSLog(@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
  #define TTDPRINT(xx, ...)  ((void)0)
#endif // #ifdef DEBUG

// Prints the current method's name.
#define TTDPRINTMETHODNAME() TTDPRINT(@"%s", __PRETTY_FUNCTION__)

// Debug-only assertions.
#ifdef DEBUG

#import <TargetConditionals.h>

#if TARGET_IPHONE_SIMULATOR

  int TTIsInDebugger();
  // We leave the __asm__ in this macro so that when a break occurs, we don't have to step out of
  // a "breakInDebugger" function.
  #define TTDASSERT(xx) { if(!(xx)) { TTDPRINT(@"TTDASSERT failed: %s", #xx); \
                                      if(TTIsInDebugger()) { __asm__("int $3\n" : : ); }; } \
                        } ((void)0)
#else
  #define TTDASSERT(xx) { if(!(xx)) { TTDPRINT(@"TTDASSERT failed: %s", #xx); } } ((void)0)
#endif // #if TARGET_IPHONE_SIMULATOR

#else
  #define TTDASSERT(xx) ((void)0)
#endif // #ifdef DEBUG

// Log-level based logging macros.
#if TTLOGLEVEL_ERROR <= TTMAXLOGLEVEL
  #define TTDERROR(xx, ...)  TTDPRINT(xx, ##__VA_ARGS__)
#else
  #define TTDERROR(xx, ...)  ((void)0)
#endif // #if TTLOGLEVEL_ERROR <= TTMAXLOGLEVEL

#if TTLOGLEVEL_WARNING <= TTMAXLOGLEVEL
  #define TTDWARNING(xx, ...)  TTDPRINT(xx, ##__VA_ARGS__)
#else
  #define TTDWARNING(xx, ...)  ((void)0)
#endif // #if TTLOGLEVEL_WARNING <= TTMAXLOGLEVEL

#if TTLOGLEVEL_INFO <= TTMAXLOGLEVEL
  #define TTDINFO(xx, ...)  TTDPRINT(xx, ##__VA_ARGS__)
#else
  #define TTDINFO(xx, ...)  ((void)0)
#endif // #if TTLOGLEVEL_INFO <= TTMAXLOGLEVEL

#ifdef DEBUG
  #define TTDCONDITIONLOG(condition, xx, ...) { if ((condition)) { \
                                                  TTDPRINT(xx, ##__VA_ARGS__); \
                                                } \
                                              } ((void)0)
#else
  #define TTDCONDITIONLOG(condition, xx, ...) ((void)0)
#endif // #ifdef DEBUG
