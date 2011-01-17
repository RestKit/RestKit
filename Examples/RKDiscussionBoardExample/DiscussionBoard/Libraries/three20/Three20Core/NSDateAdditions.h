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

#import <Foundation/Foundation.h>

@interface NSDate (TTCategory)

/**
 * Returns the current date with the time set to midnight.
 */
+ (NSDate*)dateWithToday;

/**
 * Returns a copy of the date with the time set to midnight on the same day.
 */
- (NSDate*)dateAtMidnight;

/**
 * Formats the date with 'h:mm a' or the localized equivalent.
 */
- (NSString*)formatTime;

/**
 * Formats the date with 'EEEE, LLLL d, YYYY' or the localized equivalent.
 */
- (NSString*)formatDate;

/**
 * Formats the date according to how old it is.
 *
 * For dates less than a day old, the format is 'h:mm a', for less than a week old the
 * format is 'EEEE', and for anything older the format is 'M/d/yy'.
 */
- (NSString*)formatShortTime;

/**
 * Formats the date according to how old it is.
 *
 * For dates less than a day old, the format is 'h:mm a', for less than a week old the
 * format is 'EEE h:mm a', and for anything older the format is 'MMM d h:mm a'.
 */
- (NSString*)formatDateTime;

/**
 * Formats dates within 24 hours like '5 minutes ago', or calls formatDateTime if older.
 */
- (NSString*)formatRelativeTime;

/**
 * Formats dates within 1 week like '5m' or '2d', or calls formatShortTime if older.
 */
- (NSString*)formatShortRelativeTime;

/**
 * Formats the date with 'MMMM d", "Today", or "Yesterday".
 *
 * You must supply date components for today and yesterday because they are relatively expensive
 * to create, so it is best to avoid creating them every time you call this method if you
 * are going to be calling it multiple times in a loop.
 */
- (NSString*)formatDay:(NSDateComponents*)today yesterday:(NSDateComponents*)yesterday;

/**
 * Formats the date with 'MMMM".
 */
- (NSString*)formatMonth;

/**
 * Formats the date with 'yyyy".
 */
- (NSString*)formatYear;

@end
