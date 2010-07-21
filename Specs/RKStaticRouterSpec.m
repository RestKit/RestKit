//
//  RKStaticRouterSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKStaticRouter.h"
#import "RKHuman.h"

@interface RKStaticRouterSpec : NSObject <UISpec> {
}

@end

@implementation RKStaticRouterSpec

-(void)itShouldThrowAnExceptionWhenAskedForAPathForAnUnregisteredClassAndMethod {
	RKStaticRouter* router = [[[RKStaticRouter alloc] init] autorelease];
	NSException* exception = nil;
	@try {
		[router pathForObject:[RKHuman newObject] method:RKRequestMethodPOST];
	}
	@catch (NSException * e) {
		exception = e;
	}
	[expectThat(exception) shouldNot:be(nil)];
}

-(void)itShouldThrowAnExceptionWhenAskedForAPathForARegisteredClassButUnregisteredMethod {
	RKStaticRouter* router = [[[RKStaticRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toPath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	NSException* exception = nil;
	@try {
		[router pathForObject:[RKHuman newObject] method:RKRequestMethodPOST];
	}
	@catch (NSException * e) {
		exception = e;
	}
	[expectThat(exception) shouldNot:be(nil)];
}

-(void)itShouldReturnPathsRegisteredForSpecificRequestMethods {
	RKStaticRouter* router = [[[RKStaticRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toPath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	NSString* path = [router pathForObject:[RKHuman newObject] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];		
}

-(void)itShouldReturnPathsRegisteredForTheClassAsAWhole {
	RKStaticRouter* router = [[[RKStaticRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toPath:@"/HumanService.asp"];
	NSString* path = [router pathForObject:[RKHuman newObject] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];
	path = [router pathForObject:[RKHuman newObject] method:RKRequestMethodPOST];
	[expectThat(path) should:be(@"/HumanService.asp")];
}

-(void)itShouldFavorSpecificMethodsWhenClassAndSpecificMethodsAreRegistered {
	RKStaticRouter* router = [[[RKStaticRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toPath:@"/HumanService.asp"];
	[router routeClass:[RKHuman class] toPath:@"/HumanServiceForPUT.asp" forMethod:RKRequestMethodPUT];
	NSString* path = [router pathForObject:[RKHuman newObject] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];
	path = [router pathForObject:[RKHuman newObject] method:RKRequestMethodPOST];
	[expectThat(path) should:be(@"/HumanService.asp")];
	path = [router pathForObject:[RKHuman newObject] method:RKRequestMethodPUT];
	[expectThat(path) should:be(@"/HumanServiceForPUT.asp")];
}

-(void)itShouldRaiseAnExceptionWhenAttemptIsMadeToRegisterOverAnExistingRoute {
	RKStaticRouter* router = [[[RKStaticRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toPath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	NSException* exception = nil;
	@try {
		[router routeClass:[RKHuman class] toPath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
	}
	@catch (NSException * e) {
		exception = e;
	}	
	[expectThat(exception) shouldNot:be(nil)];
}

@end
