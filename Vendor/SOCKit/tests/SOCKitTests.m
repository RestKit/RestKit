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

#import <SenTestingKit/SenTestingKit.h>
#import <QuartzCore/QuartzCore.h>

#import "SOCKit.h"

typedef void (^SimpleBlock)(void);
NSString *sockitBetterURLEncodeString(NSString *unencodedString);

@interface SOCTestObject : NSObject

- (id)initWithId:(NSInteger)ident floatValue:(CGFloat)flv doubleValue:(double)dv longLongValue:(long long)llv stringValue:(NSString *)string;
- (id)initWithId:(NSInteger)ident floatValue:(CGFloat)flv doubleValue:(double)dv longLongValue:(long long)llv stringValue:(NSString *)string userInfo:(id)userInfo;

@property (nonatomic, readwrite, assign) NSInteger ident;
@property (nonatomic, readwrite, assign) CGFloat flv;
@property (nonatomic, readwrite, assign) double dv;
@property (nonatomic, readwrite, assign) long long llv;
@property (nonatomic, readwrite, copy) NSString* string;
@end

@implementation SOCTestObject

@synthesize ident;
@synthesize flv;
@synthesize dv;
@synthesize llv;
@synthesize string;

- (void)dealloc {
  [string release]; string = nil;
  [super dealloc];
}

- (id)initWithId:(NSInteger)anIdent floatValue:(CGFloat)anFlv doubleValue:(double)aDv longLongValue:(long long)anLlv stringValue:(NSString *)aString {
  if ((self = [super init])) {
    self.ident = anIdent;
    self.flv = anFlv;
    self.dv = aDv;
    self.llv = anLlv;
    self.string = aString;
  }
  return self;
}

- (id)initWithId:(NSInteger)anIdent floatValue:(CGFloat)anFlv doubleValue:(double)aDv longLongValue:(long long)anLlv stringValue:(NSString *)aString userInfo:(id)userInfo {
  return [self initWithId:anIdent floatValue:anFlv doubleValue:aDv longLongValue:anLlv stringValue:aString];
}

@end

@interface SOCKitTests : SenTestCase
@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SOCKitTests


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testEmptyCases {
  STAssertTrue([SOCStringFromStringWithObject(nil, nil) isEqualToString:@""], @"Should be the same string.");

  STAssertTrue([SOCStringFromStringWithObject(@"", nil) isEqualToString:@""], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@" ", nil) isEqualToString:@" "], @"Should be the same string.");

  STAssertTrue([SOCStringFromStringWithObject(@"abcdef", nil) isEqualToString:@"abcdef"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"abcdef", [NSArray array]) isEqualToString:@"abcdef"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testFailureCases {
  STAssertThrows([SOCPattern patternWithString:@":dilly:isacat"], @"Parameters must be separated by strings.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testSingleParameterCoding {
  NSDictionary* obj = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:1337], @"leet",
                       [NSNumber numberWithInt:5000], @"five",
                       nil];
  STAssertTrue([SOCStringFromStringWithObject(@":leet", obj) isEqualToString:@"1337"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":five", obj) isEqualToString:@"5000"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":six", obj) isEqualToString:@"(null)"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testMultiParameterCoding {
  NSDictionary* obj = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:1337], @"leet",
                       [NSNumber numberWithInt:5000], @"five",
                       nil];
  STAssertTrue([SOCStringFromStringWithObject(@":leet/:five", obj) isEqualToString:@"1337/5000"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":five/:five", obj) isEqualToString:@"5000/5000"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":five/:five/:five/:five/:five/:five", obj) isEqualToString:@"5000/5000/5000/5000/5000/5000"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testCharacterEscapes {
  NSDictionary* obj = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:1337], @"leet",
                       [NSNumber numberWithInt:5000], @"five",
                       nil];

  STAssertTrue([SOCStringFromStringWithObject(@".", obj) isEqualToString:@"."], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"\\.", obj) isEqualToString:@"."], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":", obj) isEqualToString:@":"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"\\:", obj) isEqualToString:@":"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"@", obj) isEqualToString:@"@"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"\\@", obj) isEqualToString:@"@"], @"Should be the same string.");

  STAssertTrue([SOCStringFromStringWithObject(@":leet\\.value", obj) isEqualToString:@"1337.value"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":leet\\:value", obj) isEqualToString:@"1337:value"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":leet\\@value", obj) isEqualToString:@"1337@value"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":leet\\:\\:value", obj) isEqualToString:@"1337::value"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@":leet\\:\\:\\.\\@value", obj) isEqualToString:@"1337::.@value"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"\\\\:leet", obj) isEqualToString:@"\\1337"], @"Should be the same string.");

  SOCPattern* pattern = [SOCPattern patternWithString:@"soc://\\:ident"];
  STAssertTrue([pattern stringMatches:@"soc://:ident"], @"String should conform.");
  pattern = [SOCPattern patternWithString:@"soc://\\\\:ident"];
  STAssertTrue([pattern stringMatches:@"soc://\\3"], @"String should conform.");
  pattern = [SOCPattern patternWithString:@"soc://:ident\\.json"];
  STAssertTrue([pattern stringMatches:@"soc://3.json"], @"String should conform.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testCollectionOperators {
  NSDictionary* obj = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:1337], @"leet",
                       [NSNumber numberWithInt:5000], @"five",
                       nil];
  STAssertTrue([SOCStringFromStringWithObject(@":@count", obj) isEqualToString:@"2"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testBlockTransformations {
    NSDictionary *obj = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"JUICE|BOX&121", @"password", @"Joe Bob Briggs", @"name", [NSNumber numberWithInt:15], @"group", nil];
    SOCPattern *pattern = [SOCPattern patternWithString:@"/people/:group/:name?password=:password"];
    NSString *expectedString = @"/people/15/Joe Bob Briggs?password=JUICE|BOX&121";
    NSString *actualString = [pattern stringFromObject:obj withBlock:nil];
    STAssertTrue([actualString isEqualToString:expectedString], @"Should be the same string (testing nil block parameter).");
    STAssertTrue([actualString isEqualToString:[pattern stringFromObject:obj]], @"Should be the same string (testing nil block parameter).");
    actualString = [pattern stringFromObject:obj withBlock:^NSString *(NSString* interpolatedValue) {
        return @"Test Message";
    }];
    expectedString = @"/people/Test Message/Test Message?password=Test Message";
    STAssertTrue([actualString isEqualToString:expectedString], @"Should be the same string (testing nil block parameter).");
    STAssertFalse([actualString isEqualToString:[pattern stringFromObject:obj]], @"Should not be the same string, one was transformed with a block.");
    actualString = [pattern stringFromObject:obj withBlock:^NSString *(NSString* interpolatedValue) {
        return sockitBetterURLEncodeString(interpolatedValue);
    }];
    expectedString = @"/people/15/Joe%20Bob%20Briggs?password=JUICE%7CBOX%26121";
    STAssertTrue([actualString isEqualToString:expectedString], @"Should be the same string (testing nil block parameter).");
    STAssertFalse([actualString isEqualToString:[pattern stringFromObject:obj]], @"Should not be the same string, one was transformed with a block.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testOutboundParameters {
  SOCPattern* pattern = [SOCPattern patternWithString:@"soc://:ident"];
  STAssertTrue([pattern stringMatches:@"soc://3"], @"String should conform.");
  STAssertTrue([pattern stringMatches:@"soc://33413413454353254235245235"], @"String should conform.");

  STAssertFalse([pattern stringMatches:@""], @"String should not conform.");
  STAssertFalse([pattern stringMatches:@"soc://"], @"String should not conform.");

  STAssertTrue([pattern stringMatches:@"soc://joe"], @"String might conform.");

  pattern = [SOCPattern patternWithString:@"soc://:ident/sandwich"];
  STAssertTrue([pattern stringMatches:@"soc://3/sandwich"], @"String should conform.");
  STAssertTrue([pattern stringMatches:@"soc://33413413454353254235245235/sandwich"], @"String should conform.");

  STAssertFalse([pattern stringMatches:@""], @"String should not conform.");
  STAssertFalse([pattern stringMatches:@"soc://"], @"String should not conform.");
  STAssertFalse([pattern stringMatches:@"soc:///sandwich"], @"String should not conform.");

  pattern = [SOCPattern patternWithString:@"soc://:ident/sandwich/:catName"];
  STAssertTrue([pattern stringMatches:@"soc://3/sandwich/dilly"], @"String should conform.");
  STAssertTrue([pattern stringMatches:@"soc://33413413454353254235245235/sandwich/dilly"], @"String should conform.");

  STAssertFalse([pattern stringMatches:@""], @"String should not conform.");
  STAssertFalse([pattern stringMatches:@"soc://"], @"String should not conform.");
  STAssertFalse([pattern stringMatches:@"soc://33413413454353254235245235/sandwich/"], @"String should not conform.");
  STAssertFalse([pattern stringMatches:@"soc:///sandwich/"], @"String should not conform.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testPerformSelectorOnObjectWithSourceString {
  SOCPattern* pattern = [SOCPattern patternWithString:@"soc://:ident/:flv/:dv/:llv/:string"];
  SOCTestObject* testObject = [pattern performSelector:@selector(initWithId:floatValue:doubleValue:longLongValue:stringValue:userInfo:) onObject:[SOCTestObject class] sourceString:@"soc://3/3.5/6.14/13413143124321/dilly"];
  STAssertEquals(testObject.ident, (NSInteger)3, @"Values should be equal.");
  STAssertEquals(testObject.flv, (CGFloat)3.5, @"Values should be equal.");
  STAssertEquals(testObject.dv, 6.14, @"Values should be equal.");
  STAssertEquals(testObject.llv, (long long)13413143124321, @"Values should be equal.");
  STAssertTrue([testObject.string isEqualToString:@"dilly"], @"Values should be equal.");

  testObject = [pattern performSelector:@selector(initWithId:floatValue:doubleValue:longLongValue:stringValue:) onObject:[SOCTestObject class] sourceString:@"soc://3/3.5/6.14/13413143124321/dilly"];
  STAssertEquals(testObject.ident, (NSInteger)3, @"Values should be equal.");
  STAssertEquals(testObject.flv, (CGFloat)3.5, @"Values should be equal.");
  STAssertEquals(testObject.dv, 6.14, @"Values should be equal.");
  STAssertEquals(testObject.llv, (long long)13413143124321, @"Values should be equal.");
  STAssertTrue([testObject.string isEqualToString:@"dilly"], @"Values should be equal.");

  pattern = [SOCPattern patternWithString:@"soc://:ident"];
  [pattern performSelector:@selector(setIdent:) onObject:testObject sourceString:@"soc://6"];
  STAssertEquals(testObject.ident, (NSInteger)6, @"Values should be equal.");

  [pattern performSelector:@selector(setLlv:) onObject:testObject sourceString:@"soc://6"];
  STAssertEquals(testObject.llv, (long long)6, @"Values should be equal.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testExtractParameterKeyValuesFromSourceString {
  SOCPattern* pattern = [SOCPattern patternWithString:@"soc://:ident/:flv/:dv/:llv/:string"];
  NSDictionary* kvs = [pattern parameterDictionaryFromSourceString:@"soc://3/3.5/6.14/13413143124321/dilly"];
  STAssertEquals([[kvs objectForKey:@"ident"] intValue], 3, @"Values should be equal.");
  STAssertEquals([[kvs objectForKey:@"flv"] floatValue], 3.5f, @"Values should be equal.");
  STAssertEquals([[kvs objectForKey:@"dv"] doubleValue], 6.14, @"Values should be equal.");
  STAssertEquals([[kvs objectForKey:@"llv"] longLongValue], 13413143124321L, @"Values should be equal.");
  STAssertTrue([[kvs objectForKey:@"string"] isEqualToString:@"dilly"], @"Values should be equal.");
}

@end

// NSString's stringByAddingPercentEscapes doesn't do a complete job (it ignores "/?&", among others)
NSString *sockitBetterURLEncodeString(NSString *unencodedString) {
    NSString * encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes( NULL, (CFStringRef)unencodedString, NULL,
                                                                                   (CFStringRef)@"!*'();:@&=+$,/?%#[]", NSASCIIStringEncoding );
    return [encodedString autorelease];
}

