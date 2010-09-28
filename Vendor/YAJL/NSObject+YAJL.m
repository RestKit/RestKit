//
//  NSObject+YAJL.m
//  YAJL
//
//  Created by Gabriel Handford on 7/23/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSObject+YAJL.h"
#import "YAJLGen.h"
#import "YAJLDocument.h"

@implementation NSObject (YAJL)

#pragma mark Gen

- (NSString *)yajl_JSONString {
  return [self yajl_JSONStringWithOptions:YAJLGenOptionsNone indentString:@"  "];
}

- (NSString *)yajl_JSONStringWithOptions:(YAJLGenOptions)options indentString:(NSString *)indentString {
  YAJLGen *gen = [[YAJLGen alloc] initWithGenOptions:options indentString:indentString];
  [gen object:self];
  NSString *buffer = [[gen buffer] retain];
  [gen release];
  return [buffer autorelease];
}

#pragma mark Parsing

- (id)yajl_JSON {
  NSError *error = nil;
  id JSON = [self yajl_JSON:&error];
  if (error) [NSException raise:YAJLParserException format:[error localizedDescription], nil];
  return JSON;
}

- (id)yajl_JSON:(NSError **)error {
  return [self yajl_JSONWithOptions:YAJLParserOptionsNone error:error];
}

- (id)yajl_JSONWithOptions:(YAJLParserOptions)options error:(NSError **)error {
  NSData *data = nil; 
  if ([self isKindOfClass:[NSData class]]) {
    data = (NSData *)self;
  } else if ([self respondsToSelector:@selector(dataUsingEncoding:)]) {
    data = [(id)self dataUsingEncoding:NSUTF8StringEncoding];
  } else {
    [NSException raise:YAJLParsingUnsupportedException format:@"Object of type (%@) must implement dataUsingEncoding: to be parsed", [self class]];
  }
  
  YAJLDocument *document = [[YAJLDocument alloc] initWithData:data parserOptions:options error:error];
  id root = [document.root retain];
  [document release];
  return [root autorelease];
}

@end
