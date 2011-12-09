//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SOCKit.h"

#import <objc/runtime.h>
#import <assert.h>

typedef enum {
  SOCArgumentTypeNone,
  SOCArgumentTypePointer,
  SOCArgumentTypeBool,
  SOCArgumentTypeInteger,
  SOCArgumentTypeLongLong,
  SOCArgumentTypeFloat,
  SOCArgumentTypeDouble,
} SOCArgumentType;

SOCArgumentType SOCArgumentTypeForTypeAsChar(char argType);
NSString* kTemporaryBackslashToken = @"/backslash/";


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface SOCParameter : NSObject {
@private
  NSString* _string;
}

- (id)initWithString:(NSString *)string;
+ (id)parameterWithString:(NSString *)string;

- (NSString *)string;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface SOCPattern()

- (void)_compilePattern;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SOCPattern


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [_patternString release]; _patternString = nil;
  [_tokens release]; _tokens = nil;
  [_parameters release]; _parameters = nil;
  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithString:(NSString *)string {
  if ((self = [super init])) {
    _patternString = [string copy];

    [self _compilePattern];
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)patternWithString:(NSString *)string {
  return [[[self alloc] initWithString:string] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Pattern Compilation


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSCharacterSet *)nonParameterCharacterSet {
  NSMutableCharacterSet* parameterCharacterSet = [NSMutableCharacterSet alphanumericCharacterSet];
  [parameterCharacterSet addCharactersInString:@".@_"];
  NSCharacterSet* nonParameterCharacterSet = [parameterCharacterSet invertedSet];
  return nonParameterCharacterSet;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)_compilePattern {
  if ([_patternString length] == 0) {
    return;
  }

  NSMutableArray* tokens = [[NSMutableArray alloc] init];
  NSMutableArray* parameters = [[NSMutableArray alloc] init];

  NSCharacterSet* nonParameterCharacterSet = [self nonParameterCharacterSet];

  // Turn escaped backslashes into a special backslash token to avoid \\. being interpreted as
  // `\` and `\.` rather than `\\` and `.`.
  NSString* escapedPatternString = _patternString;
  if ([escapedPatternString rangeOfString:@"\\\\"].length > 0) {
    escapedPatternString = [escapedPatternString stringByReplacingOccurrencesOfString: @"\\\\"
                                                                           withString: kTemporaryBackslashToken];
  }
  
  // Scan through the string, creating tokens that are either strings or parameters.
  // Parameters are prefixed with ":".
  NSScanner* scanner = [NSScanner scannerWithString:escapedPatternString];

  // NSScanner skips whitespace and newlines by default (not ideal!).
  [scanner setCharactersToBeSkipped:nil];

  while (![scanner isAtEnd]) {
    NSString* token = nil;
    [scanner scanUpToString:@":" intoString:&token];

    if ([token length] > 0) {
      if (![token hasSuffix:@"\\"]) {
        // Add this static text to the token list.
        [tokens addObject:token];

      } else {
        // This token is escaping the next colon, so we skip the parameter creation.
        [tokens addObject:[token stringByAppendingString:@":"]];

        // Skip the colon.
        [scanner setScanLocation:[scanner scanLocation] + 1];
        continue;
      }
    }

    if (![scanner isAtEnd]) {
      // Skip the colon.
      [scanner setScanLocation:[scanner scanLocation] + 1];

      // Scanning won't modify the token if there aren't any characters to be read, so we must
      // clear it before scanning again.
      token = nil;
      [scanner scanUpToCharactersFromSet:nonParameterCharacterSet intoString:&token];

      if ([token length] > 0) {
        // Only add parameters that have valid names.
        SOCParameter* parameter = [SOCParameter parameterWithString:token];
        [parameters addObject:parameter];
        [tokens addObject:parameter];

      } else {
        // Allows for http:// to get by without creating a parameter.
        [tokens addObject:@":"];
      }
    }
  }

  // This is an outbound pattern.
  if ([parameters count] > 0) {
    BOOL lastWasParameter = NO;
    for (id token in tokens) {
      if ([token isKindOfClass:[SOCParameter class]]) {
        NSAssert(!lastWasParameter, @"Parameters must be separated by non-parameter characters.");
        lastWasParameter = YES;

      } else {
        lastWasParameter = NO;
      }
    }
  }

  [_tokens release];
  _tokens = [tokens copy];
  [_parameters release]; _parameters = nil;
  if ([parameters count] > 0) {
    _parameters = [parameters copy];
  }
  [tokens release]; tokens = nil;
  [parameters release]; parameters = nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)_stringFromEscapedToken:(NSString *)token {
  if ([token rangeOfString:@"\\"].length == 0
      && [token rangeOfString:kTemporaryBackslashToken].length == 0) {
    // The common case (faster and creates fewer autoreleased strings).
    return token;
    
  } else {
    // Escaped characters may exist.
    // Create a mutable copy so that we don't excessively create new autoreleased strings.
    NSMutableString* mutableToken = [token mutableCopy];
    [mutableToken replaceOccurrencesOfString:@"\\." withString:@"." options:0 range:NSMakeRange(0, [mutableToken length])];
    [mutableToken replaceOccurrencesOfString:@"\\@" withString:@"@" options:0 range:NSMakeRange(0, [mutableToken length])];
    [mutableToken replaceOccurrencesOfString:@"\\:" withString:@":" options:0 range:NSMakeRange(0, [mutableToken length])];
    [mutableToken replaceOccurrencesOfString:kTemporaryBackslashToken withString:@"\\" options:0 range:NSMakeRange(0, [mutableToken length])];
    return [mutableToken autorelease];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)gatherParameterValues:(NSArray**)pValues fromString:(NSString *)string  {
  const NSInteger stringLength = [string length];
  NSInteger validUpUntil = 0;
  NSInteger matchingTokens = 0;

  NSMutableArray* values = nil;
  if (nil != pValues) {
    values = [NSMutableArray array];
  }

  NSInteger tokenIndex = 0;
  for (id token in _tokens) {

    if ([token isKindOfClass:[NSString class]]) {
      // Replace the escaped characters in the token before we start comparing the string.
      token = [self _stringFromEscapedToken:token];

      NSInteger tokenLength = [token length];
      if (validUpUntil + tokenLength > stringLength) {
        // There aren't enough characters in the string to satisfy this token.
        break;
      }
      if (![[string substringWithRange:NSMakeRange(validUpUntil, tokenLength)]
            isEqualToString:token]) {
        // The tokens don't match up.
        break;
      }

      // The string token matches.
      validUpUntil += tokenLength;
      ++matchingTokens;

    } else {
      NSInteger parameterLocation = validUpUntil;

      // Look ahead for the next string token match.
      if (tokenIndex + 1 < [_tokens count]) {
        NSString* nextToken = [self _stringFromEscapedToken:[_tokens objectAtIndex:tokenIndex + 1]];
        NSAssert([nextToken isKindOfClass:[NSString class]], @"The token following a parameter must be a string.");

        NSRange nextTokenRange = [string rangeOfString:nextToken options:0 range:NSMakeRange(validUpUntil, stringLength - validUpUntil)];
        if (nextTokenRange.length == 0) {
          // Couldn't find the next token.
          break;
        }
        if (nextTokenRange.location == validUpUntil) {
          // This parameter is empty.
          break;
        }

        validUpUntil = nextTokenRange.location;
        ++matchingTokens;

      } else {
        // Anything goes until the end of the string then.
        if (validUpUntil == stringLength) {
          // The last parameter is empty.
          break;
        }

        validUpUntil = stringLength;
        ++matchingTokens;
      }

      NSRange parameterRange = NSMakeRange(parameterLocation, validUpUntil - parameterLocation);
      [values addObject:[string substringWithRange:parameterRange]];
    }
    
    ++tokenIndex;
  }

  if (nil != pValues) {
    *pValues = [[values copy] autorelease];
  }
  
  return validUpUntil == stringLength && matchingTokens == [_tokens count];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)stringMatches:(NSString *)string {
  return [self gatherParameterValues:nil fromString:string];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setArgument:(NSString*)text withType:(SOCArgumentType)type atIndex:(NSInteger)index forInvocation:(NSInvocation*)invocation {
  // There are two implicit arguments with an invocation.
  index+=2;

  switch (type) {
    case SOCArgumentTypeNone: {
      break;
    }
    case SOCArgumentTypeInteger: {
      int val = [text intValue];
      [invocation setArgument:&val atIndex:index];
      break;
    }
    case SOCArgumentTypeLongLong: {
      long long val = [text longLongValue];
      [invocation setArgument:&val atIndex:index];
      break;
    }
    case SOCArgumentTypeFloat: {
      float val = [text floatValue];
      [invocation setArgument:&val atIndex:index];
      break;
    }
    case SOCArgumentTypeDouble: {
      double val = [text doubleValue];
      [invocation setArgument:&val atIndex:index];
      break;
    }
    case SOCArgumentTypeBool: {
      BOOL val = [text boolValue];
      [invocation setArgument:&val atIndex:index];
      break;
    }
    default: {
      [invocation setArgument:&text atIndex:index];
      break;
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setArgumentsFromValues:(NSArray *)values forInvocation:(NSInvocation *)invocation {
  Method method = class_getInstanceMethod([invocation.target class], invocation.selector);
  NSAssert(nil != method, @"The method must exist with the given invocation target.");

  for (NSInteger ix = 0; ix < [values count]; ++ix) {
    NSString* value = [values objectAtIndex:ix];

    char argType[4];
    method_getArgumentType(method, (unsigned int) ix + 2, argType, sizeof(argType) / sizeof(argType[0]));
    SOCArgumentType type = SOCArgumentTypeForTypeAsChar(argType[0]);

    [self setArgument:value withType:type atIndex:ix forInvocation:invocation];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)performSelector:(SEL)selector onObject:(id)object sourceString:(NSString *)sourceString {
  BOOL isInitializer = [NSStringFromSelector(selector) hasPrefix:@"init"] && [object class] == object;

  if (isInitializer) {
    object = [[object alloc] autorelease];
  }

  NSArray* values = nil;
  NSAssert([self gatherParameterValues:&values fromString:sourceString], @"The pattern can't be used with this string.");

  id returnValue = nil;

  NSMethodSignature* sig = [object methodSignatureForSelector:selector];
  NSAssert(nil != sig, @"%@ does not respond to selector: '%@'", object, NSStringFromSelector(selector));
  NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
  [invocation setTarget:object];
  [invocation setSelector:selector];
  [self setArgumentsFromValues:values forInvocation:invocation];
  [invocation invoke];

  if (sig.methodReturnLength) {
    [invocation getReturnValue:&returnValue];
  }

  return returnValue;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)parameterDictionaryFromSourceString:(NSString *)sourceString {
  NSMutableDictionary* kvs = [[NSMutableDictionary alloc] initWithCapacity:[_parameters count]];

  NSArray* values = nil;
  NSAssert([self gatherParameterValues:&values fromString:sourceString], @"The pattern can't be used with this string.");

  for (NSInteger ix = 0; ix < [values count]; ++ix) {
    SOCParameter* parameter = [_parameters objectAtIndex:ix];
    id value = [values objectAtIndex:ix];
    [kvs setObject:value forKey:parameter.string];
  }

  NSDictionary* result = [[kvs copy] autorelease];
  [kvs release]; kvs = nil;
  return result;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)_stringWithParameterValues:(NSDictionary *)parameterValues {
  NSMutableString* accumulator = [[NSMutableString alloc] initWithCapacity:[_patternString length]];

  for (id token in _tokens) {
    if ([token isKindOfClass:[NSString class]]) {
      [accumulator appendString:[self _stringFromEscapedToken:token]];

    } else {
      SOCParameter* parameter = token;
      [accumulator appendString:[parameterValues objectForKey:parameter.string]];
    }
  }

  NSString* result = nil;
  result = [[accumulator copy] autorelease];
  [accumulator release]; accumulator = nil;
  return result;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)stringFromObject:(id)object {
  if ([_tokens count] == 0) {
    return @"";
  }
  NSMutableDictionary* parameterValues =
  [NSMutableDictionary dictionaryWithCapacity:[_parameters count]];
  for (SOCParameter* parameter in _parameters) {
    NSString* stringValue = [NSString stringWithFormat:@"%@", [object valueForKeyPath:parameter.string]];
    [parameterValues setObject:stringValue forKey:parameter.string];
  }
  return [self _stringWithParameterValues:parameterValues];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#if NS_BLOCKS_AVAILABLE
- (NSString *)stringFromObject:(id)object withBlock:(NSString *(^)(NSString*))block {
  if ([_tokens count] == 0) {
    return @"";
  }
  NSMutableDictionary* parameterValues = [NSMutableDictionary dictionaryWithCapacity:[_parameters count]];
  for (SOCParameter* parameter in _parameters) {
    NSString* stringValue = [NSString stringWithFormat:@"%@", [object valueForKeyPath:parameter.string]];
    if (nil != block) {
      stringValue = block(stringValue);
    }
    if (nil != stringValue) {
      [parameterValues setObject:stringValue forKey:parameter.string];
    }
  }
  return [self _stringWithParameterValues:parameterValues];
}
#endif

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SOCParameter

- (void)dealloc {
  [_string release]; _string = nil;
  [super dealloc];
}

- (id)initWithString:(NSString *)string {
  if ((self = [super init])) {
    _string = [string copy];
  }
  return self;
}

+ (id)parameterWithString:(NSString *)string {
  return [[[self alloc] initWithString:string] autorelease];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Parameter: %@", _string];
}

- (NSString *)string {
  return [[_string retain] autorelease];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
SOCArgumentType SOCArgumentTypeForTypeAsChar(char argType) {
  if (argType == 'c' || argType == 'i' || argType == 's' || argType == 'l' || argType == 'C'
      || argType == 'I' || argType == 'S' || argType == 'L') {
    return SOCArgumentTypeInteger;

  } else if (argType == 'q' || argType == 'Q') {
    return SOCArgumentTypeLongLong;

  } else if (argType == 'f') {
    return SOCArgumentTypeFloat;

  } else if (argType == 'd') {
    return SOCArgumentTypeDouble;

  } else if (argType == 'B') {
    return SOCArgumentTypeBool;

  } else {
    return SOCArgumentTypePointer;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
NSString* SOCStringFromStringWithObject(NSString* string, id object) {
  SOCPattern* pattern = [[SOCPattern alloc] initWithString:string];
  NSString* result = [pattern stringFromObject:object];
  [pattern release];
  return result;
}
