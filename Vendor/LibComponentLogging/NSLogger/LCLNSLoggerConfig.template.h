//
//
// LCLNSLoggerConfig.h
//
//
// Copyright (c) 2010 Arne Harren <ah@0xc0.de>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


//
// LCLNSLoggerConfig.h template for the LCLNSLogger logging class.
//


// Rename the LCLNSLogger class by adding your application/framework's unique
// prefix in order to avoid duplicate symbols in the global class namespace.
#ifndef LCLNSLogger
#define LCLNSLogger                                                            \
    <UniquePrefix>LCLNSLogger
#endif

// Tell LCLNSLogger whether it should show file names.
#define _LCLNSLogger_ShowFileNames /* (BOOL) */                                \
    YES

// Tell LCLNSLogger whether it should show line numbers.
#define _LCLNSLogger_ShowLineNumbers /* (BOOL) */                              \
    YES

// Tell LCLNSLogger whether it should show function names.
#define _LCLNSLogger_ShowFunctionNames /* (BOOL) */                            \
    YES

// Tell LCLNSLogger whether it should set the NSLogger LogToConsole option.
#define _LCLNSLogger_LogToConsole /* (BOOL) */                                 \
    NO

// Tell LCLNSLogger whether it should set the NSLogger BufferLocallyUntilConnection option.
#define _LCLNSLogger_BufferLocallyUntilConnection /* (BOOL) */                 \
    YES

// Tell LCLNSLogger whether it should set the NSLogger BrowseBonjour option.
#define _LCLNSLogger_BrowseBonjour /* (BOOL) */                                \
    YES

// Tell LCLNSLogger whether it should set the NSLogger BrowseOnlyLocalDomains option.
#define _LCLNSLogger_BrowseOnlyLocalDomains /* (BOOL) */                       \
    YES

// Tell LCLNSLogger whether it should set the NSLogger UseSSL option.
#define _LCLNSLogger_UseSSL /* (BOOL) */                                       \
    YES

