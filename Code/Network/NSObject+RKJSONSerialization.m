//
//  NSObject+RKJSONSerialization.m
//  RestKit
//
//  Created by Blake Watters on 7/8/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "NSObject+RKJSONSerialization.h"

@implementation NSObject (RKJSONSerialization)

- (RKJSONSerialization*)JSONSerialization {
	return [RKJSONSerialization JSONSerializationWithObject:self];
}

@end
