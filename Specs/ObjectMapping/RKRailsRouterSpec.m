//
//  RKRailsRouterSpec.m
//  RestKit
//
//  Created by Blake Watters on 10/19/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectManager.h"
#import "RKManagedObjectStore.h"
#import "RKRailsRouter.h"
#import "RKHuman.h"

@interface RKRailsRouterSpec : NSObject <UISpec> {
}

@end

@implementation RKRailsRouterSpec

- (void)beforeAll {
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://localhost:4567"];
	objectManager.objectStore = [[RKManagedObjectStore alloc] initWithStoreFilename:@"RestKitSpecs.sqlite"];
}

- (void)itShouldRaiseErrorWhenAskedToRouteAnUnregisteredModel {
	RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
	NSException* exception = nil;
	@try {
		[router serializationForObject:[RKHuman object] method:RKRequestMethodPOST];
	}
	@catch (NSException * e) {
		exception = e;
	}
	[expectThat(exception) shouldNot:be(nil)];
}

- (void)itShouldGenerateARailsIdiomaticSerialization {
	RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
	[router setModelName:@"Human" forClass:[RKHuman class]];
	RKHuman* human = [[RKHuman object] autorelease];
	human.name = @"Blake";
	human.age = [NSNumber numberWithInt:27];
	human.railsID = [NSNumber numberWithInt:31337];
	
	NSObject<RKRequestSerializable>* serialization = [router serializationForObject:human method:RKRequestMethodPOST];
	[expectThat(serialization) shouldNot:be(nil)];
	NSLog(@"Serialization is %@", serialization);
}

@end
