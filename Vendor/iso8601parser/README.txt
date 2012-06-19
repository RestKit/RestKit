How to use in your program
==========================

Add the source files to your project.

Parsing
-------

Create an ISO 8601 date formatter, then call [formatter dateFromString:myString]. The method will return either an NSDate or nil.

There are a total of six parser methods. The one that contains the actual parser is -[ISO8601DateFormatter dateComponentsFromString:timeZone:range:]. The other five are based on this one.

The "outTimeZone" parameter, when not set to NULL, is a pointer to an NSTimeZone *variable. If the string specified a time zone, you'll receive the time zone object in that variable. If the string didn't specify a time zone, you'll receive nil.

The "outRange" parameter, when not set to NULL, is a pointer to NSRange storage. You will receive the range of the parsed substring in that storage.

Unparsing
---------

Create an ISO 8601 date formatter, then call [formatter stringFromDate:myDate]. The method will return a string.

The formatter has several properties that control its behavior:

* You can set the format of the resulting strings. By default, the formatter will generate calendar-date strings; your other options are week dates and ordinal dates.
* You can set a default time zone; by default, it will use [NSTimeZone defaultTimeZone].
* You can enable a strict mode, wherein the formatter enforces sanity checks on the string. By default, the parser will afford you quite a bit of leeway.
* You can set whether to include the time in the string, and if so, what hour-minute separator to use (default ':').

How to test that this code works
================================

'make test' will perform all tests. If you want to perform only *some* tests:

Parsing
-------

Type 'make parser-test'. make will build the test program (testparser), then invoke testparser.sh.py to generate testparser.sh. Then make will invoke testparser.sh, which will invoke the test program with various dates.

If you don't want to use my tests, 'make testparser' will create the test program without running it. You can then invoke testparser yourself with any date you want to. If it doesn't give you the result you expected, contact me, making sure to provide me with both the input and the output.

Unparsing
---------

Type 'make unparser-test'. make will build the test programs, then invoke testunparser.sh. This shell script invokes each test program for -01-01 of every year from 1991 to 2010, writing the output to a file, and then runs diff -qs between that file (testunparser.out) and a file (testunparser-expected.out) containing known correct output. diff should report that the files are identical.

Three test programs are included: unparse-date, unparse-weekdate, and unparse-ordinal date. If you don't want to use my tests, you can make these test programs separately. Each takes a date specified by ISO 8601 (parsed with my own ISO 8601 parser), and outputs a string that should represent the same date.

Notes
=====

Version history
---------------

This version is 0.6. Changes from 0.5:
* When not set to strict parsing, allow a space before the time-zone specification, for greater compatibility with NSDate output (`description`) and input (`dateWithString:`). 27603efc8a77
* Bug fix: We no longer try to format the formatter. 83415de9f527
* Bug fix: Hours are now zero-padded correctly ([#4](https://bitbucket.org/boredzo/iso-8601-parser-unparser/issue/4/time-zones-are-emitted-without-leading)). a5608e189ebe af0c6b397428
* Fixed many various compiler warnings. Some fixes contributed by Sparks. 8be3d6f7c6f2 78ae31de2170 68dc351e9fdb e7ea87db8621 873f499ae6db
* Now 75 times faster. 6a023812bd2b 05dc35d6b505 3b2225e0ce8c d59720ad015a 10f526956963 297b8dae4095 796be11aa596 cadf0f0c8199 61d2959c6921
* iOS users can now tell the ISO 8601 date formatter class to drop its caches (which you should do when you receive a memory warning). 2bb1725914b1
* Added a couple of command-line options to the calendar-format-unparser test tool. c644aadb2b14
* The parser test tool now displays parsed dates in GMT rather than the local time zone. 788c1455ecb1
* Added a test tool to test unparsing with the time included. a89a9a8b3d61
* You can now “make analysis” to run the Clang Static Analyzer on the date formatter. b3dd33841f42
* The test tools are now built using Clang. 0723d3aa6596

Changes in 0.5 from 0.4:
* Rewrote as an NSFormatter subclass using NSCalendar.
  * Making it a formatter makes it much easier to use with Bindings.
  * Using NSCalendar means we're no longer using NSCalendarDate, which Apple has said they will deprecate at some point.
* Fixed a bug in week date generation: One subtraction could give a negative result, which was a problem because my implementation of the algorithm used unsigned integers. I've changed it to use signed integers, so the result truly is negative now. I also added a test case for this.

Changes in 0.4 from 0.3:
* Added the ability to use a time separator other than ':'.

Changes in 0.3 from 0.2:
* Colin Barrett noticed that I used %m instead of %M when creating the time strings. Oops.
* Colin also noticed that I had the ?: in -ISO8601DateStringWithTime: the wrong way around. Oops again.

Changes in 0.2 from 0.1:
* The unparser is new. The  has been munged to allow both components together, 
* The parser has not changed.

Parsing
-------

Whitespace before a date, and anything after a date, is ignored. Thus, "    T23 and all's well" is a valid date for the purpose of this method. (Yes, T23 is a valid ISO 8601 date. It means 23:00:00, or 11 PM.)

All of the frills of ISO 8601 are supported, except for extended dates (years longer than 4 digits). Specifically, you can use week-based dates (2006-W2 for the second week of 2006), ordinal dates (2006-365 for December 31), decimal minutes (11:30.5 == 11:30:30), and decimal seconds (11:30:10.5). All methods of specifying a time zone are supported.

ISO 8601 leaves quite a bit up to the parties exchanging dates. I hope I've chosen reasonable defaults. For example (note that I'm writing this on 2006-02-24):

• If the month or month and date are missing, 1 is assumed. "2006" == "2006-01-01".
• If the year or year and month are missing, the current ones are assumed. "--02-01" == "2006-02-01". "---28" == "2006-02-28".
• In the case of week-based dates, with  the day missing, this implementation returns the first day of that week: 2006-W1 is 2006-01-01, 2006-W2 is 2006-01-08, etc.
• For any date without a time, midnight on that date is used.
• ISO 8601 permits the choice of either T0 or T24 for midnight. This implementation uses T0. T24 will get you T0 on the following day.
• If no time-zone is specified, local time (as returned by [NSTimeZone localTimeZone]) is used.

When a date is parsed that has a year but no century, this implementation adds the current century.

The implementation is tolerant of out-of-range numbers. For example, "2005-13-40T24:62:89" == 1:02 AM on 2006-02-10. Notice that the month (13 > 12), date (40 > 31), hour (24 > 23), minute (62 > 59), and second (89 > 59) are all out-of-range.

As mentioned above, there is a "strict" mode that enforces sanity checks. In particular, the date must be the entire contents of the string, and numbers are range-checked. If you have any suggestions on how to make this mode more strict, contact me.

Unparsing
---------

I use Rick McCarty's algorithm for converting calendar dates to week dates (http://personal.ecu.edu/mccartyr/ISOwdAlg.txt), slightly tweaked.

Bugs
====

Parsing
-------

* This method won't extract a date from just anywhere in a string, only immediately after the start of the string (or any leading whitespace). There are two solutions: either require you to invoke the parser on a string that is only an ISO 8601 date, with nothing before or after (bad for parsing purposes), or make the parser able to find an ISO 8601 date as a substring. I won't do the first one, and barring a patch, I probably won't do the second one either.

* Date ranges (also specified by ISO 8601) are not supported; this method will only return one date. To handle ranges would require at least one more method.

* There is no method to analyze a date string and tell you what was found in it (year, month, week, day, ordinal day, etc.). Feel free to submit a patch.

Copyright
=========

This code is copyright 2006–2011 Peter Hosey. It is under the BSD license; see LICENSE.txt for the full text of the license.
