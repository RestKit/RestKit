// This is a forked copy of the ISO8601DateFormatter

/*ISO8601DateFormatter.h
 *
 *Created by Peter Hosey on 2009-04-11.
 *Copyright 2009 Peter Hosey. All rights reserved.
 */

#import <Foundation/Foundation.h>

/*This class converts dates to and from ISO 8601 strings. A good introduction to ISO 8601: <http://www.cl.cam.ac.uk/~mgk25/iso-time.html>
 *
 *Parsing can be done strictly, or not. When you parse loosely, leading whitespace is ignored, as is anything after the date.
 *The loose parser will return an NSDate for this string: @" \t\r\n\f\t  2006-03-02!!!"
 *Leading non-whitespace will not be ignored; the string will be rejected, and nil returned. See the README that came with this addition.
 *
 *The strict parser will only accept a string if the date is the entire string. The above string would be rejected immediately, solely on these grounds.
 *Also, the loose parser provides some extensions that the strict parser doesn't.
 *For example, the standard says for "-DDD" (an ordinal date in the implied year) that the logical representation (meaning, hierarchically) would be "--DDD", but because that extra hyphen is "superfluous", it was omitted.
 *The loose parser will accept the extra hyphen; the strict parser will not.
 *A full list of these extensions is in the README file.
 */

/*The format to either expect or produce.
 *Calendar format is YYYY-MM-DD.
 *Ordinal format is YYYY-DDD, where DDD ranges from 1 to 366; for example, 2009-32 is 2009-02-01.
 *Week format is YYYY-Www-D, where ww ranges from 1 to 53 (the 'W' is literal) and D ranges from 1 to 7; for example, 2009-W05-07.
 */
enum {
	RKISO8601DateFormatCalendar,
	RKISO8601DateFormatOrdinal,
	RKISO8601DateFormatWeek,
};
typedef NSUInteger RKISO8601DateFormat;

@interface RKISO8601DateFormatter: NSFormatter

/**
 The time zone for tge formatter.
 
 **Default:** `[NSTimeZone defaultTimeZone]`
 */
@property (nonatomic, strong) NSTimeZone *timeZone;

/**
 The locale for the formatter.
 
 **Default:** `[NSLocale currentLocale]`
 */
@property (nonatomic, strong) NSLocale *locale;

#pragma mark Parsing

/**
 A Boolean value that determines if the receiver parses strictly.
 
 **Default**: `NO`
 */
@property (nonatomic, assign) BOOL parsesStrictly;

- (NSDateComponents *)dateComponentsFromString:(NSString *)string;
- (NSDate *)dateFromString:(NSString *)string;

#pragma mark Unparsing

/**
 **Default**: `RKISO8601DateFormatCalendar`
 */
@property (nonatomic, assign) RKISO8601DateFormat format;

/**
 A Boolean value that specifies if time should be included in the formatted strings.
 
 **Default**: `NO`
 */
@property (nonatomic, assign) BOOL includeTime;

/**
 The separator character to use between time components.
 
 **Default**: `':'`
 */
@property (nonatomic, assign) unichar timeSeparator;

/**
 Returns an ISO-8601 string representation of the given date.
 
 @param date The date to be formatted into a string.
 @return An ISO-8601 formatted string representation of the date.
 */
- (NSString *)stringFromDate:(NSDate *)date;

@end
