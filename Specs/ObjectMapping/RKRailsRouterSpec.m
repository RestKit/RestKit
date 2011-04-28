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
#import "RKCat.h"

@interface RKRailsRouterSpec : NSObject <UISpec> {
}

@end

@implementation RKRailsRouterSpec

- (void)beforeAll {
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://localhost:4567"];
	objectManager.objectStore = [[RKManagedObjectStore alloc] initWithStoreFilename:@"RestKitSpecs.sqlite"];
    [RKObjectManager setSharedManager:objectManager];
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

- (void)itShouldNotSerializeIDForChildrenWithoutPrimaryKeys
{
    RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
	[router setModelName:@"Human" forClass:[RKHuman class]];
    RKHuman* human = [[RKHuman object] autorelease];
	human.name = @"Peter";
	human.age = [NSNumber numberWithInt:25];
    RKCat* cat1 = [[RKCat object] autorelease];
    cat1.name = @"Zeus";
    cat1.birthYear = [NSNumber numberWithInt:1982];
    [human addCatsObject:cat1];
    RKCat* cat2 = [[RKCat object] autorelease];
    cat2.name = @"Nala";
    cat2.birthYear = [NSNumber numberWithInt:2003];
    [human addCatsObject:cat2];
    
    NSDictionary* serialization = (NSDictionary*) [router serializationForObject:human method:RKRequestMethodPOST];
    NSArray* serializedCats = [serialization objectForKey:@"human[cats_attributes]"];
    for (NSDictionary *catDict in serializedCats) {
        [expectThat([catDict objectForKey:@"name"]) shouldNot:be(nil)];
        [expectThat([catDict objectForKey:@"id"]) should:be(nil)];
    }
}

- (void)itShouldSerializeAllAttributesForChildrenWithPrimaryKeys
{
    RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
	[router setModelName:@"Human" forClass:[RKHuman class]];
    RKHuman* human = [[RKHuman object] autorelease];
	human.name = @"Peter";
	human.age = [NSNumber numberWithInt:25];
    RKCat* cat1 = [[RKCat object] autorelease];
    cat1.name = @"Zeus";
    cat1.birthYear = [NSNumber numberWithInt:1982];
    cat1.railsID = [NSNumber numberWithInt:1];
    [human addCatsObject:cat1];
    RKCat* cat2 = [[RKCat object] autorelease];
    cat2.name = @"Nala";
    cat2.birthYear = [NSNumber numberWithInt:2003];
    cat2.railsID = [NSNumber numberWithInt:2];
    [human addCatsObject:cat2];
    
    NSDictionary* serialization = (NSDictionary*) [router serializationForObject:human method:RKRequestMethodPOST];
    NSArray* serializedCats = [serialization objectForKey:@"human[cats_attributes]"];
    for (NSDictionary *catDict in serializedCats) {
        [expectThat([catDict objectForKey:@"name"]) shouldNot:be(nil)];
        [expectThat([catDict objectForKey:@"id"]) shouldNot:be(nil)];
    }
}

@end
