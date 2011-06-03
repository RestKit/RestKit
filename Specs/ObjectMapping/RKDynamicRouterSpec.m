//
//  RKDynamicRouterSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"
#import "RKHuman.h"
#import "RKCat.h"

@interface RKDynamicRouterSpec : NSObject <UISpec> {
}

@end

@implementation RKDynamicRouterSpec

- (void)beforeAll {
    RKSpecNewManagedObjectStore();
}

-(void)itShouldThrowAnExceptionWhenAskedForAPathForAnUnregisteredClassAndMethod {
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
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
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
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
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	NSString* path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];		
}

-(void)itShouldReturnPathsRegisteredForTheClassAsAWhole {
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/HumanService.asp"];
	NSString* path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];
	path = [router resourcePathForObject:[RKHuman object] method:RKRequestMethodPOST];
	[expectThat(path) should:be(@"/HumanService.asp")];
}

-(void)itShouldFavorSpecificMethodsWhenClassAndSpecificMethodsAreRegistered {
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
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
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
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
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"/humans/(railsID)/(name)" forMethod:RKRequestMethodGET];
	
	NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
	[expectThat(resourcePath) should:be(@"/humans/31337/blake")];
}

- (void)itShouldAllowForPolymorphicURLsViaMethodCalls {
	RKHuman* blake = [RKHuman object];
	blake.name = @"blake";
	blake.railsID = [NSNumber numberWithInt:31337];
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"(polymorphicResourcePath)" forMethod:RKRequestMethodGET];
	
	NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
	[expectThat(resourcePath) should:be(@"/this/is/the/path")];
}

@end
