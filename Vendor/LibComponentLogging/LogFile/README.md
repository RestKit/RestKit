

# LibComponentLogging-LogFile

[http://0xc0.de/LibComponentLogging](http://0xc0.de/LibComponentLogging)    
[http://github.com/aharren/LibComponentLogging-LogFile](http://github.com/aharren/LibComponentLogging-LogFile)


## Overview

LibComponentLogging-LogFile is a file logging class for Objective-C (Mac OS X
and iPhone OS) which writes log messages to an application-specific log file.

The application's log file is opened automatically when the first log message
needs to be written to the log file. If the log file reaches a configured
maximum size, it gets rotated and all previous messages will be moved to a
backup log file. The backup log file is kept until the next rotation.

The logging class can be used as a logging back-end for LibComponentLogging,
but it can also be used as a standalone logger without the Core files of
LibComponentLogging.

The LogFile logger uses the format

    <date> <time> <pid>:<tid> <level> <component>:<file>:<line>:<function> <message>

where the file name, the line number and the function name are optional.

Example:

    2009-02-01 12:38:32.796 4964:10b D component1:main.m:28:-[Class method] Message
    2009-02-01 12:38:32.798 4964:10b D component2:main.m:32:-[Class method] Message
    2009-02-01 12:38:32.799 4964:10b D component3:main.m:36:-[Class method] Message


## Usage

Before you start, copy the LCLLogFile.h and .m file to your project and create
a LCLLogFileConfig.h configuration file (based on the packaged template file).
The configuration file defines the name of the log file, the maximum log file
size, whether new log messages get appended to an existing log file on startup,
and much more.

Then, import the LCLLogFile.h in your source files or in your prefix header file
if you are using LCLLogFile as a standalone logging class, or add an import to
your lcl_config_logger.h file if you are using the class as a logging back-end
for LibComponentLogging.

In case you are using the LCLLogFile class with LibComponentLogging, you can
simply start logging to the log file by using the standard logging macro from
LibComponentLogging, e.g.

    lcl_log(lcl_cMyComponent, lcl_vError, @"message ...");

If you are using the class as a standalone logger, you can simply call one of
the log... methods from the LCLLogFile class, e.g.

    [LCLLogFile logWithIdentifier:"MyComponent" level:1 ... format:@"message ...", ...];

or you can wrap these calls into your own logging macros.

In both scenarios, the log file will be opened automatically for you.


## Repository Branches

The Git repository contains the following branches:

* [master](http://github.com/aharren/LibComponentLogging-LogFile/tree/master):
  The *master* branch contains stable builds of the main logging code which are
  tagged with version numbers.

* [devel](http://github.com/aharren/LibComponentLogging-LogFile/tree/devel):
  The *devel* branch is the development branch for the logging code which
  contains an Xcode project with dependent code, e.g. the Core files of
  LibComponentLogging, and unit tests. The code in this branch is not stable.


## Related Repositories

The following Git repositories are related to this repository: 

* [http://github.com/aharren/LibComponentLogging-Core](http://github.com/aharren/LibComponentLogging-Core):
  Core files of LibComponentLogging.

* [http://github.com/aharren/LibComponentLogging-LogFile-Example](http://github.com/aharren/LibComponentLogging-LogFile-Example):
  An example Xcode project which uses the LibComponentLogging-LogFile logger.


## Copyright and License

Copyright (c) 2008-2011 Arne Harren <ah@0xc0.de>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

