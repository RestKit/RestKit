//
//  RKObjectiveCppTest.mm
//  RestKit
//
//  Created by Blake Watters on 4/11/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKHTTPUtilities.h"
#import "RKObjectUtilities.h"
#import "RKMIMETypes.h"
#import "RKPathUtilities.h"
#import "RKDictionaryUtilities.h"

@interface RKObjectiveCppTest : RKTestCase

@end

@implementation RKObjectiveCppTest

- (void)testCompiles
{
    // Nothing to do.
}

- (void)testCompilesWithHTTPUtilities {
    NSIndexSet *codes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
    expect(codes).notTo.beNil();
}

- (void)testCompilesWithObjectUtilities {
    BOOL eq = RKClassIsCollection([NSArray class]);
    expect(eq).to.equal(YES);
}

- (void)testCompilesWithMIMETypes {
    BOOL match = RKMIMETypeInSet(@"text/plain", [NSSet set]);
    expect(match).to.equal(NO);
}

- (void)testCompilesWithPathUtilities {
    NSString *path = RKApplicationDataDirectory();
    expect(path).notTo.beNil();
}

- (void)testCompilesWithDictionaryUtilities {
    NSDictionary *dict = RKDictionaryByMergingDictionaryWithDictionary([NSDictionary dictionary], [NSDictionary dictionary]);
    expect(dict).notTo.beNil();
}

@end