//
//  NSObjectRKKVCTest.m
//  RestKit
//
//  Created by Simon Booth on 31/07/2013.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSObject+RKKVC.h"

@interface NSObjectRKKVCTest : RKTestCase

@end

@implementation NSObjectRKKVCTest

- (void)testFirstKeyInKeyPath
{
    NSDictionary *dict1 = @{ @"a" : @{ @"b" : @"c" } };
    expect([dict1 rk_firstKeyInKeyPath:@"a.b.c"]).to.equal(@"a");
    expect([dict1 rk_firstKeyInKeyPath:@"e.f.g"]).to.equal(@"e");
    
    NSDictionary *dict2 = @{ @"a.b" : @{ @"c" : @"d" } };
    expect([dict2 rk_firstKeyInKeyPath:@"a.b.c"]).to.equal(@"a.b");
    expect([dict2 rk_firstKeyInKeyPath:@"e.f.g"]).to.equal(@"e");
    
    NSDictionary *dict3 = @{ @"a" : @{ @"b.c" : @"d" } };
    expect([dict3 rk_firstKeyInKeyPath:@"a.b.c"]).to.equal(@"a");
    expect([dict3 rk_firstKeyInKeyPath:@"e.f.g"]).to.equal(@"e");
}

- (void)testFirstValueForKeyPath
{
    NSDictionary *dict1 = @{ @"a" : @{ @"b" : @"c" } };
    NSString *keyPath1 = nil;
    id value1 = [dict1 rk_firstValueForKeyPath:@"a.b" outKeyPath:&keyPath1];
    
    expect(value1).to.equal(@{ @"b" : @"c" });
    expect(keyPath1).to.equal(@"b");
    
    NSDictionary *dict2 = @{ @"a.b" : @{ @"c" : @"d" } };
    NSString *keyPath2 = nil;
    id value2 = [dict2 rk_firstValueForKeyPath:@"a.b" outKeyPath:&keyPath2];
    
    expect(value2).to.equal(@{ @"c" : @"d" });
    expect(keyPath2).to.beNil();
    
    NSDictionary *dict3 = @{ @"a" : @{ @"b.c" : @"d" } };
    NSString *keyPath3 = nil;
    id value3 = [dict3 rk_firstValueForKeyPath:@"a.b" outKeyPath:&keyPath3];
    
    expect(value3).to.equal(@{ @"b.c" : @"d" });
    expect(keyPath3).to.equal(@"b");
}

- (void)testRKValueForKeyPath
{
    NSDictionary *dict1 = @{ @"a" : @{ @"b" : @"c" } };
    expect([dict1 rk_valueForKeyPath:@"a"]).to.equal(@{ @"b" : @"c" });
    expect([dict1 rk_valueForKeyPath:@"a.b"]).to.equal(@"c");
    
    NSDictionary *dict2 = @{ @"a.b" : @{ @"c" : @"d" } };
    expect([dict2 rk_valueForKeyPath:@"a.b"]).to.equal(@{ @"c" : @"d" });
    expect([dict2 rk_valueForKeyPath:@"a.b.c"]).to.equal(@"d");
    
    NSDictionary *dict3 = @{ @"a" : @{ @"b.c" : @"d" } };
    expect([dict3 rk_valueForKeyPath:@"a"]).to.equal(@{ @"b.c" : @"d" });
    expect([dict3 rk_valueForKeyPath:@"a.b.c"]).to.equal(@"d");
    
    NSDictionary *dict4 = @{ @"a" : @{ @"b.c" : @{ @"d" : @"e" } } };
    expect([dict4 rk_valueForKeyPath:@"a"]).to.equal(@{ @"b.c" : @{ @"d" : @"e" } });
    expect([dict4 rk_valueForKeyPath:@"a.b.c"]).to.equal(@{ @"d" : @"e" });
    expect([dict4 rk_valueForKeyPath:@"a.b.c.d"]).to.equal(@"e");
}

@end
