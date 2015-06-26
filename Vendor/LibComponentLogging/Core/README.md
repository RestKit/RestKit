

# LibComponentLogging-Core

[http://0xc0.de/LibComponentLogging](http://0xc0.de/LibComponentLogging)    
[http://github.com/aharren/LibComponentLogging-Core](http://github.com/aharren/LibComponentLogging-Core)


## Overview

LibComponentLogging is a small logging library for Objective-C applications on
Mac OS X and the iPhone OS which provides conditional logging based on log
levels and log components. Additionally, different logging strategies can be
used, e.g. writing log messages to a file or sending them to the system log,
while using the same logging interface.

LibComponentLogging is available under the terms of the MIT license.

This Git repository contains the library's Core part.


## Installation

Download the files of the library Core and a logging back-end, e.g. the
LogFile logger, from their repositories on GitHub:

* [Library Core](http://github.com/aharren/LibComponentLogging-Core)

* [LogFile Logger](http://github.com/aharren/LibComponentLogging-LogFile)

* [SystemLog Logger](http://github.com/aharren/LibComponentLogging-SystemLog)

* [NSLog Logger](http://github.com/aharren/LibComponentLogging-NSLog)

* [NSLogger Logger](http://github.com/aharren/LibComponentLogging-NSLogger)

Extract the files and copy the extracted files to your application's source
directory.

Open Xcode and add all files of the library to your application's project.
Xcode will automatically add the library's implementation files to your
project's target.

Create a lcl_config_logger.h file and set up the logger, e.g. set the maximum
file size and the name of the log file for the LogFile logger.

Create a lcl_config_extensions.h file and optionally add #import statements
for logging extensions.

Create your application's lcl_config_components.h file.

Add a #import statement for lcl.h to your application files, e.g. to your
application's prefix header file.

Define your log components in lcl_config_components.h.

Add lcl_log(...) log statements to your application.


## Repository Branches

The Git repository contains the following branches:

* [master](http://github.com/aharren/LibComponentLogging-Core/tree/master):
  The *master* branch contains stable builds of the main logging code
  which are tagged with version numbers.

* [devel](http://github.com/aharren/LibComponentLogging-Core/tree/devel):
  The *devel* branch is the development branch for the logging code
  which contains an Xcode project and unit tests. The code in this branch is
  not stable.


## Related Repositories

The following Git repositories are related to this repository: 

* [LibComponentLogging-LogFile](http://github.com/aharren/LibComponentLogging-LogFile):
  A file logging class which writes log messages to an application-specific log
  file.

* [LibComponentLogging-SystemLog](http://github.com/aharren/LibComponentLogging-SystemLog):
  A logging class which sends log messages to the Apple System Log facility (ASL).

* [LibComponentLogging-NSLog](http://github.com/aharren/LibComponentLogging-NSLog):
  A very simple logger which redirects log messages to NSLog, but adds
  information about the log level, the log component, and the log statement's
  location (file name and line number).

* [LibComponentLogging-NSLogger](http://github.com/aharren/LibComponentLogging-NSLogger):
  A logger which integrates the logging client from Florent Pillet's NSLogger project.    
  See [http://github.com/fpillet/NSLogger](http://github.com/fpillet/NSLogger) for more details about NSLogger.

* [LibComponentLogging-qlog](http://github.com/aharren/LibComponentLogging-qlog):
  An extension which provides a set of quick logging macros.

* [LibComponentLogging-UserDefaults](http://github.com/aharren/LibComponentLogging-UserDefaults)
  An extension which stores/restores log level settings to/from the user defaults.

## Copyright and License

Copyright (c) 2008-2012 Arne Harren <ah@0xc0.de>

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

