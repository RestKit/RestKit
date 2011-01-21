//
//  RKObject.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKObject.h"

@implementation RKObject

+ (NSDictionary*)elementToPropertyMappings {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionary];
}

+ (id)object {
	return [[self new] autorelease];
}

- (NSDictionary*)propertiesForSerialization {
	return RKObjectMappableGetPropertiesByElement(self);
}

@end
