//
//  RKObjectMappingOperationSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"

@interface RKObjectMappingOperationSpec : RKSpec {
    
}

@end

@implementation RKObjectMappingOperationSpec

- (void)itShouldNotCrashComparingANumberToAString {
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation new] autorelease]
    BOOL result = [operation isValue:[NSNumber numberWithInt:1] equalToValue:@"1"];
    [expectThat(result) should:be(NO)];
}

@end
