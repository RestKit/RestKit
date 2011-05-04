//
//  RKDynamicRouterSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKManagedObjectStore.h"
#import "RKHuman.h"
#import "RKCat.h"

@interface RKDynamicRouterSpec : NSObject <UISpec> {
}

@end

@implementation RKDynamicRouterSpec

- (void)beforeAll {
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://localhost:4567"];
	objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RestKitSpecs.sqlite"];
}

-(void)itShouldThrowAnExceptionWhenAskedForAPathForAnUnregisteredClassAndMethod {
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	NSException* exception = nil;
	@try {
		[router resourcePathForObject:[RKHuman object] method:RKRequestMethodPOST];
	}
	@catch (NSException * e) {
		exception = e;
	}
	[expectThat(exception) shouldNot:be(nil)];
}

-(void)itShouldThrowAnExceptionWhenAskedForAPathForARegisteredClassButUnregisteredMethod {
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	NSException* exception = nil;
	@try {
		[router resourcePathForObject:[RKHuman object] method:RKRequestMethodPOST];
	}
	@catch (NSException * e) {
		exception = e;
	}
	[expectThat(exception) shouldNot:be(nil)];
}

-(void)itShouldReturnPathsRegisteredForSpecificRequestMethods {
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	NSString* path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];		
}

-(void)itShouldReturnPathsRegisteredForTheClassAsAWhole {
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp"];
	NSString* path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];
	path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodPOST];
	[expectThat(path) should:be(@"/HumanService.asp")];
}

-(void)itShouldFavorSpecificMethodsWhenClassAndSpecificMethodsAreRegistered {
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp"];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanServiceForPUT.asp" forMethod:RKRequestMethodPUT];
	NSString* path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];
	path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodPOST];
	[expectThat(path) should:be(@"/HumanService.asp")];
	path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodPUT];
	[expectThat(path) should:be(@"/HumanServiceForPUT.asp")];
}

-(void)itShouldRaiseAnExceptionWhenAttemptIsMadeToRegisterOverAnExistingRoute {
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	NSException* exception = nil;
	@try {
		[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	}
	@catch (NSException * e) {
		exception = e;
	}
	[expectThat(exception) shouldNot:be(nil)];
}

- (void)itShouldInterpolatePropertyNamesReferencedInTheMapping {
	RKHuman* blake = [RKHuman object];
	blake.name = @"blake";
	blake.railsID = [NSNumber numberWithInt:31337];
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/humans/(railsID)/(name)" forMethod:RKRequestMethodGET];
	
	NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
	[expectThat(resourcePath) should:be(@"/humans/31337/blake")];
}

- (void)itShouldAllowForPolymorphicURLsViaMethodCalls {
	RKHuman* blake = [RKHuman object];
	blake.name = @"blake";
	blake.railsID = [NSNumber numberWithInt:31337];
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"(polymorphicResourcePath)" forMethod:RKRequestMethodGET];
	
	NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
	[expectThat(resourcePath) should:be(@"/this/is/the/path")];
}

- (void)itShouldSerializeToOneRelationWithoutId
{
    RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
    
    RKHuman* human = [[RKHuman object] autorelease];
    RKCat* cat = [[RKCat object] autorelease];
    
    cat.name = @"Cat";
    human.name = @"Owner";
    cat.human = human;
    
    NSDictionary* serialization = (NSDictionary*) [router serializationForObject:cat method:RKRequestMethodPOST];
    NSDictionary* serializedRelation = [serialization objectForKey:@"human"];
    [expectThat([serializedRelation objectForKey:@"name"]) should:be(@"Owner")]; 
}

- (void)itShouldSerializeToOneRelationWithId
{
    RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
    
    RKHuman* human = [[RKHuman object] autorelease];
    RKCat* cat = [[RKCat object] autorelease];
    
    cat.name = @"Cat";
    human.railsID = [NSNumber numberWithInt:1];
    human.name = @"Owner";
    cat.human = human;
    
    NSDictionary* serialization = (NSDictionary*) [router serializationForObject:cat method:RKRequestMethodPOST];
    NSDictionary* serializedRelation = [serialization objectForKey:@"human"];
    [expectThat([serializedRelation objectForKey:@"name"]) should:be(@"Owner")]; 
}


- (void)itShouldSerializeToManyRelationWithoutId
{
    RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
    
    RKHuman* human = [[RKHuman object] autorelease];
	human.name = @"Owner";
    RKCat* cat1 = [[RKCat object] autorelease];
    cat1.name = @"Cat1";
    [human addCatsObject:cat1];
    RKCat* cat2 = [[RKCat object] autorelease];
    cat2.name = @"Cat2";
    [human addCatsObject:cat2];
    
    NSDictionary* serialization = (NSDictionary*) [router serializationForObject:human method:RKRequestMethodPOST];
    NSArray* serializedCats = [serialization objectForKey:@"cats"];
    
    NSDictionary *serCat1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:0], @"age",
                             [NSNumber numberWithInt:0], @"birth_year",
                             @"Cat1", @"name",
                             nil];
    
    NSDictionary *serCat2 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:0], @"age",
                             [NSNumber numberWithInt:0], @"birth_year",
                             @"Cat2", @"name",
                             nil];
    [expectThat([serializedCats count]) should:be(2)];
    [expectThat([serializedCats containsObject:serCat1]) should:be(TRUE)];
    [expectThat([serializedCats containsObject:serCat2]) should:be(TRUE)];
}

- (void)itShouldSerializeToManyRelationWithId
{
    RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
    
    RKHuman* human = [[RKHuman object] autorelease];
	human.name = @"Owner";
    RKCat* cat1 = [[RKCat object] autorelease];
    cat1.name = @"Cat1";
    cat1.railsID = [NSNumber numberWithInt:1];
    [human addCatsObject:cat1];
    RKCat* cat2 = [[RKCat object] autorelease];
    cat2.name = @"Cat2";
    cat2.railsID = [NSNumber numberWithInt:2];
    [human addCatsObject:cat2];
    
    NSDictionary* serialization = (NSDictionary*) [router serializationForObject:human method:RKRequestMethodPOST];
    NSArray* serializedCats = [serialization objectForKey:@"cats"];
    
    NSDictionary *serCat1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:0], @"age",
                             [NSNumber numberWithInt:0], @"birth_year",
                             [NSNumber numberWithInt:1], @"id",
                             @"Cat1", @"name",
                             nil];
    
    NSDictionary *serCat2 = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:0], @"age",
                             [NSNumber numberWithInt:0], @"birth_year",
                             [NSNumber numberWithInt:2], @"id",
                             @"Cat2", @"name",
                             nil];
    [expectThat([serializedCats count]) should:be(2)];
    [expectThat([serializedCats containsObject:serCat1]) should:be(TRUE)];
    [expectThat([serializedCats containsObject:serCat2]) should:be(TRUE)];
}

@end
