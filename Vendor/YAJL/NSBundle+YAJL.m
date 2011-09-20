//
//  NSBundle+YAJL.m
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

#import "NSBundle+YAJL.h"
#import "GHNSBundle+Utils.h"
#import "NSObject+YAJL.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(NSBundle_YAJL)

@implementation NSBundle (YAJL)

- (id)yajl_JSONFromResource:(NSString *)resource {
  NSError *error = nil;
  id JSONValue = [self yajl_JSONFromResource:resource options:YAJLParserOptionsNone error:&error];
  if (error) [NSException raise:YAJLParserException format:[error localizedDescription], nil];
  return JSONValue;
}

- (id)yajl_JSONFromResource:(NSString *)resource options:(YAJLParserOptions)options error:(NSError **)error {
  return [[self yajl_gh_loadStringDataFromResource:resource] yajl_JSONWithOptions:YAJLParserOptionsAllowComments error:error];
}

@end
