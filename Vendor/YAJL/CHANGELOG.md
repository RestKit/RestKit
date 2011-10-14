== 0.2.25

- Fixing YAJL (iOS) build.

== 0.2.22

- Fixing YAJL (Mac OSX) build.

== 0.2.21

- Renaming categories to namespace them in case they are used externally.

== 0.2.20

- Added framework build for iPhone

== 0.2.17

- Updated to use yalj 1.0.9 (iPhone)

== 0.2.16

- Hudson (JUnit XML support)
- Fix YAJL.h import
- Updated to use yajl 1.0.9

== 0.2.15

- YAJLParserOptionsStrictPrecision option
- Parsing as double on long long overflow, unless strict precision option

== 0.2.14

- Fixing build problem

== 0.2.13

- Using long long for non-decimal types (instead of always double).

== 0.2.12

- Fixing MacOSX build/install to use @rpath correctly
- Defined error codes, and error userInfo key for value we errored on

== 0.2.11

- Fixed bug where yajl_JSONWithOptions:error: would ignore options.

== 0.2.10

- Gen options for ignoring unknown types and supporting PList types like NSData and NSDate
- Changed default capacity in YAJLDocument for slightly better perf

== 0.2.9

- Enabling verbose errors in yajl

== 0.2.8

- Memory usage fix from wooster (autorelease to release)
- Fixed memory leak when number parse error
- Added default init methods for YAJLDocument and YAJLParser

== 0.2.7

- Changed yajl_encodeJSON to JSON for YAJLCoding protocol
- Updating comments for YAJLCoding

== 0.2.6

- Supporting gen/parse from NSObject category (supports NSString, NSData and custom)
- Including standard/optimized build for arm6/7
- Include yajl_*.h api header files (iPhone)
- 32/64 bit universal build (Mac OSX)

== 0.2.5 

- Added YAJLGen wrapper for yajl_gen
- Added streaming support to YAJLDocument
- Added NSString category
- Added NSObject category

== 0.2.4

- Using yajl_number callback since its more compliant (correctly handles large double values)
- Changing YAJLParser API to allow for streaming data
- Added test for overflow.json
- Added test for insane sample.json

== 0.2.3

- Fixed memory leak in YAJLParser
