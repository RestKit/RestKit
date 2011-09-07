//
//  RKObjectRouterSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKSpecEnvironment.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"
#import "RKHuman.h"
#import "RKCat.h"

@interface RKSpecObject : NSObject
@end
@implementation RKSpecObject
@end

@interface RKSpecSubclassedObject : RKSpecObject
@end
@implementation RKSpecSubclassedObject
@end

@interface RKObjectRouterSpec : RKSpec {
}

@end

@implementation RKObjectRouterSpec

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

- (void)itShouldReturnPathsIfTheSuperclassIsRegistered {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
	[router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp"];
	NSString* path = [router resourcePathForObject:[RKSpecSubclassedObject new] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/HumanService.asp")];
}

- (void)itShouldFavorExactMatcherOverSuperclassMatches {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
	[router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp"];
    [router routeClass:[RKSpecSubclassedObject class] toResourcePath:@"/SubclassedHumanService.asp"];
	NSString* path = [router resourcePathForObject:[RKSpecSubclassedObject new] method:RKRequestMethodGET];
	[expectThat(path) should:be(@"/SubclassedHumanService.asp")];
	path = [router resourcePathForObject:[RKSpecObject new] method:RKRequestMethodPOST];
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
	[router routeClass:[RKHuman class] toResourcePath:@"/humans/:railsID/:name" forMethod:RKRequestMethodGET];
	
	NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
	[expectThat(resourcePath) should:be(@"/humans/31337/blake")];
}

- (void)itShouldInterpolatePropertyNamesReferencedInTheMappingWithDeprecatedParentheses {
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
	[router routeClass:[RKHuman class] toResourcePath:@":polymorphicResourcePath" forMethod:RKRequestMethodGET];
	
	NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
	[expectThat(resourcePath) should:be(@"/this/is/the/path")];
}

- (void)itShouldAllowForPolymorphicURLsViaMethodCallsWithDeprecatedParentheses {
	RKHuman* blake = [RKHuman object];
	blake.name = @"blake";
	blake.railsID = [NSNumber numberWithInt:31337];
	RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
	[router routeClass:[RKHuman class] toResourcePath:@"(polymorphicResourcePath)" forMethod:RKRequestMethodGET];
	
	NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
	[expectThat(resourcePath) should:be(@"/this/is/the/path")];
}

@end
