//
//  NSDictionary+RKRequestSerializationSpec.m
//  RestKit
//
//  Created by Blake Watters on 2/24/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "NSDictionary+RKAdditions.h"

@interface NSDictionary_RKRequestSerializationSpec : NSObject <UISpec> {
	
}

@end

@implementation NSDictionary_RKRequestSerializationSpec

- (void)itShouldHaveKeysAndValuesDictionaryInitializer {
	NSDictionary* dictionary1 = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", @"value2", @"key2", nil];
	NSDictionary* dictionary2 = [NSDictionary dictionaryWithKeysAndObjects:@"key", @"value", @"key2", @"value2", nil];
	[expectThat(dictionary2) should:be(dictionary1)];
}

@end
