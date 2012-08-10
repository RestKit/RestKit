//
//  RKObjectRouterTest.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import "RKTestEnvironment.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"
#import "RKTestUser.h"

@interface RKTestObject : NSObject
@end
@implementation RKTestObject
+ (id)object
{
    return [[self new] autorelease];
}
@end

@interface RKTestSubclassedObject : RKTestObject
@end
@implementation RKTestSubclassedObject
@end

@interface RKObjectRouterTest : RKTestCase {
}

@end

@implementation RKTestUser (PolymorphicResourcePath)

- (NSString *)polymorphicResourcePath
{
    return @"/this/is/the/path";
}

@end

@implementation RKObjectRouterTest

- (void)testThrowAnExceptionWhenAskedForAPathForAnUnregisteredClassAndMethod
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    NSException *exception = nil;
    @try {
        [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodPOST];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testThrowAnExceptionWhenAskedForAPathForARegisteredClassButUnregisteredMethod
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    NSException *exception = nil;
    @try {
        [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodPOST];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testReturnPathsRegisteredForTestificRequestMethods
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    NSString *path = [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testReturnPathsRegisteredForTheClassAsAWhole
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanService.asp"];
    NSString *path = [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testShouldReturnPathsIfTheSuperclassIsRegistered
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanService.asp"];
    NSString *path = [router resourcePathForObject:[RKTestSubclassedObject new] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testShouldFavorExactMatcherOverSuperclassMatches
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanService.asp"];
    [router routeClass:[RKTestSubclassedObject class] toResourcePath:@"/SubclassedHumanService.asp"];
    NSString *path = [router resourcePathForObject:[RKTestSubclassedObject new] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/SubclassedHumanService.asp")));
    path = [router resourcePathForObject:[RKTestObject new] method:RKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testFavorTestificMethodsWhenClassAndTestificMethodsAreRegistered
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanService.asp"];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanServiceForPUT.asp" forMethod:RKRequestMethodPUT];
    NSString *path = [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[RKTestObject object] method:RKRequestMethodPUT];
    assertThat(path, is(equalTo(@"/HumanServiceForPUT.asp")));
}

- (void)testRaiseAnExceptionWhenAttemptIsMadeToRegisterOverAnExistingRoute
{
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestObject class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    NSException *exception = nil;
    @try {
        [router routeClass:[RKTestObject class] toResourcePathPattern:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testShouldInterpolatePropertyNamesReferencedInTheMapping
{
    RKTestUser *blake = [RKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestUser class] toResourcePathPattern:@"/humans/:userID/:name" forMethod:RKRequestMethodGET];

    NSString *resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/humans/31337/blake")));
}

- (void)testShouldInterpolatePropertyNamesReferencedInTheMappingWithDeprecatedParentheses
{
    RKTestUser *blake = [RKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestUser class] toResourcePathPattern:@"/humans/(userID)/(name)" forMethod:RKRequestMethodGET];

    NSString *resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/humans/31337/blake")));
}

- (void)testShouldAllowForPolymorphicURLsViaMethodCalls
{
    RKTestUser *blake = [RKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestUser class] toResourcePathPattern:@":polymorphicResourcePath" forMethod:RKRequestMethodGET escapeRoutedPath:NO];

    NSString *resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/this/is/the/path")));
}

- (void)testShouldAllowForPolymorphicURLsViaMethodCallsWithDeprecatedParentheses
{
    RKTestUser *blake = [RKTestUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKTestUser class] toResourcePathPattern:@"(polymorphicResourcePath)" forMethod:RKRequestMethodGET escapeRoutedPath:NO];

    NSString *resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/this/is/the/path")));
}

@end
