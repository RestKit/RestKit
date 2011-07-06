//
//  RKObjectMappingResultSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/5/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectMappingResult.h"

@interface RKObjectMappingResultSpec : RKSpec

@end

@implementation RKObjectMappingResultSpec

- (void)itShouldNotCrashWhenAsObjectIsInvokedOnAnEmptyResult {
    NSException* exception = nil;
    RKObjectMappingResult* result = [RKObjectMappingResult mappingResultWithDictionary:[NSDictionary dictionary]];
    @try {
        [result asObject];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)itShouldReturnNilForAnEmptyCollectionCoercedToAsObject {
    RKObjectMappingResult* result = [RKObjectMappingResult mappingResultWithDictionary:[NSDictionary dictionary]];
    assertThat([result asObject], is(equalTo(nil)));
}

- (void)itShouldReturnTheFirstObjectInTheCollectionWhenCoercedToAsObject {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"one", @"one", @"two", @"two", nil];
    RKObjectMappingResult* result = [RKObjectMappingResult mappingResultWithDictionary:dictionary];
    assertThat([result asObject], is(equalTo(@"one")));
}

@end
