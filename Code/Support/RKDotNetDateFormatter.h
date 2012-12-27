//
//  RKDotNetDateFormatter.h
//  RestKit
//
//  Created by Greg Combs on 9/8/11.
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

#import <Foundation/Foundation.h>

/**
 A subclass of `NSDateFormatter` that serves as translator between ASP.NET date serializations in JSON strings and NSDate objects. This is useful for properly mapping these dates from an ASP.NET driven backend.

 @warning DO NOT attempt to use `setDateFormat:` on this class.  It will return invalid results.
 */
@interface RKDotNetDateFormatter : NSDateFormatter

/**
 Instantiates an autoreleased `RKDotNetDateFormatter` object with the timezone set to the given value. The default time zone is UTC.

 The supplied timeZone, such as one produced with `[NSTimeZone timeZoneWithName:@"UTC"]`,
 is only used during calls to `stringFromDate:, for a detailed explanation see `dateFromString:`

 @param timeZone An NSTimeZone object. A `nil` value sets the timezone to the default value of UTC.
 @return An autoreleased `RKDotNetDateFormatter` object
 @see dotNetDateFormatter
 */
+ (instancetype)dotNetDateFormatterWithTimeZone:(NSTimeZone *)timeZone;

/**
 Returns an `NSDate` object from an ASP.NET style date string respresentation, as seen in JSON.

 Acceptable examples are:
    /Date(1112715000000-0500)/
    /Date(1112715000000)/
    /Date(-1112715000000)/
 Where 1112715000000 is the number of milliseconds since January 1, 1970 00:00 GMT/UTC, and -0500 represents the timezone offset from GMT in 24-hour time. Negatives milliseconds are treated as dates before January 1, 1970.

 *NOTE* `NSDate` objects do not have timezones, and you should never change an actual date value based on a timezone offset.  However, timezones are important when presenting dates to the user.  Therefore, If an offset is present in the ASP.NET string (it should be), we actually ignore the offset portion because we want to store the actual date value in its raw form, without any pollution of timezone information. If, on the other hand, there is no offset in the ASP.NET string, we assume GMT (+0000) anyway. In summation, for this class `setTimeZone:` is ignored except when using `stringFromDate:`

 @param string The ASP.NET style string, /Date(1112715000000-0500)/
 @return An `NSDate` object.
 @see `stringFromDate`
 @see `NSDateFormatter`
 @see `NSTimeZone`
 */
- (NSDate *)dateFromString:(NSString *)string;

/**
 Returns an ASP.NET style date string from an NSDate, such as /Date(1112715000000+0000)/ Where 1112715000000 is the number of milliseconds since January 1, 1970 00:00 GMT/UTC, and +0000 is the timezone offset from GMT in 24-hour time.

 *NOTE *GMT (+0000) is assumed otherwise specified via `setTimeZone:`

 @param date An `NSDate` object from which to return a string value.
 @return The ASP.NET style string, /Date(1112715000000-0500)/
 @see `dateFromString`
 @see `NSDateFormatter`
 @see `NSTimeZone`
 */
- (NSString *)stringFromDate:(NSDate *)date;
@end
