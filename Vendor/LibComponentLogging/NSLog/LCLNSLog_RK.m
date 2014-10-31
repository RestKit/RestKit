//
//
// LCLNSLog_RK.m
//
//
// Copyright (c) 2008-2009 Arne Harren <ah@0xc0.de>
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


#import "LCLNSLog_RK.h"
#import "lcl_RK.h"

Class RKLoggingClass;

@implementation RKNSLogLogger

+ (void)load
{
    if (RKLoggingClass == Nil)
        RKLoggingClass = self;
}

+ (void)logWithComponent:(_RKlcl_component_t)component
                   level:(_RKlcl_level_t)level
                    file:(const char *)file
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
