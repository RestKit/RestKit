//
//  RKObjectSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/21/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObject.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "NSDictionary+RKAdditions.h"

@interface RKObjectSpec : RKObject <UISpec> {
	NSString* _favoriteColor;
	NSNumber* _age;
}

@property (nonatomic, retain) NSString* favoriteColor;
@property (nonatomic, retain) NSNumber* age;

@end

@implementation RKObjectSpec

@synthesize favoriteColor = _favoriteColor;
@synthesize age = _age;

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"myFavoriteColor", @"favoriteColor",
			@"myAge", @"age",
			nil];
}

- (void)itShouldReturnTheColorPropertiesForSerialization {
	self.age = [NSNumber numberWithInt:10];
	self.favoriteColor = @"blue";
	
	NSDictionary* expectedParams = [NSDictionary dictionaryWithKeysAndObjects:
									@"myFavoriteColor", @"blue",
									@"myAge", [NSNumber numberWithInt:10],
									nil];
	[expectThat([self propertiesForSerialization]) should:be(expectedParams)];
}

@end
