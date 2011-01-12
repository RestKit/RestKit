//
//  NSObject+RKJSONSerialization.m
//  RestKit
//
//  Created by Blake Watters on 7/8/10.
//
//

#import "NSObject+RKJSONSerialization.h"

@implementation NSObject (RKJSONSerialization)

- (RKJSONSerialization*)JSONSerialization {
	return [RKJSONSerialization JSONSerializationWithObject:self];
}

@end
