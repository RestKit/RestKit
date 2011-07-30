//
//  RKObjectPolymorphicMappingSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectPolymorphicMapping.h"
#import "RKPolymorphicMappingModels.h"

@interface RKObjectPolymorphicMappingSpec : RKSpec <RKObjectPolymorphicMappingDelegate>

@end

@implementation RKObjectPolymorphicMappingSpec

- (void)itShouldPickTheAppropriateMappingBasedOnAnAttributeValue {
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKey:@"type" isEqualTo:@"Girl"];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKey:@"type" isEqualTo:@"Boy"];
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"girl.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"boy.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)itShouldMatchOnAnNSNumberAttributeValue {
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class] block:^(RKObjectMapping* mapping) {
        [mapping mapAttributes:@"name", nil];
    }];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKey:@"numeric_type" isEqualTo:[NSNumber numberWithInt:0]];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKey:@"numeric_type" isEqualTo:[NSNumber numberWithInt:1]];
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"girl.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"boy.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)itShouldPickTheAppropriateMappingBasedOnDelegateCallback {
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    dynamicMapping.delegate = self;
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"girl.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"boy.json")];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)itShouldPickTheAppropriateMappingBasedOnBlockDelegateCallback {
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    dynamicMapping.delegateBlock = ^ RKObjectMapping* (id data) {
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
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
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
