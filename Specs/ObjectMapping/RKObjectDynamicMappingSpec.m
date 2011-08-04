//
//  RKObjectDynamicMappingSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectDynamicMapping.h"
#import "RKDynamicMappingModels.h"

@interface RKObjectDynamicMappingSpec : RKSpec <RKObjectDynamicMappingDelegate>

@end

@implementation RKObjectDynamicMappingSpec

- (void)itShouldPickTheAppropriateMappingBasedOnAnAttributeValue {
    RKObjectDynamicMapping* dynamicMapping = [RKObjectDynamicMapping dynamicMapping];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"girl.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"boy.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)itShouldMatchOnAnNSNumberAttributeValue {
    RKObjectDynamicMapping* dynamicMapping = [RKObjectDynamicMapping dynamicMapping];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"numeric_type" isEqualTo:[NSNumber numberWithInt:0]];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"numeric_type" isEqualTo:[NSNumber numberWithInt:1]];
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"girl.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"boy.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)itShouldPickTheAppropriateMappingBasedOnDelegateCallback {
    RKObjectDynamicMapping* dynamicMapping = [RKObjectDynamicMapping dynamicMapping];
    dynamicMapping.delegate = self;
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"girl.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"boy.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)itShouldPickTheAppropriateMappingBasedOnBlockDelegateCallback {
    RKObjectDynamicMapping* dynamicMapping = [RKObjectDynamicMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id data) {
        if ([[data valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return [RKObjectMapping mappingForClass:[Girl class] block:^(RKObjectMapping* mapping) {
                [mapping mapAttributes:@"name", nil];
            }];
        } else if ([[data valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return [RKObjectMapping mappingForClass:[Boy class] block:^(RKObjectMapping* mapping) {
                [mapping mapAttributes:@"name", nil];
            }];
        }
        
        return nil;
    };
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"girl.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"boy.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)itShouldFailAnAssertionWhenInvokedWithSomethingOtherThanADictionary {
    NSException* exception = nil;
    RKObjectDynamicMapping* dynamicMapping = [RKObjectDynamicMapping dynamicMapping];
    @try {
        [dynamicMapping objectMappingForDictionary:(NSDictionary*)[NSArray array]];
    }
    @catch (NSException* e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

#pragma mark - RKDynamicObjectMappingDelegate

- (RKObjectMapping*)objectMappingForData:(id)data {
    if ([[data valueForKey:@"type"] isEqualToString:@"Girl"]) {
        return [RKObjectMapping mappingForClass:[Girl class] block:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    } else if ([[data valueForKey:@"type"] isEqualToString:@"Boy"]) {
        return [RKObjectMapping mappingForClass:[Boy class] block:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }
    
    return nil;
}

@end
