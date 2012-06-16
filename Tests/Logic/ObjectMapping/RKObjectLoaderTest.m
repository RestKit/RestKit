//
//  RKObjectLoaderTest.m
//  RestKit
//
//  Created by Blake Watters on 4/27/11.
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
#import "RKObjectMappingProvider.h"
#import "RKErrorMessage.h"
#import "RKJSONParserJSONKit.h"

// Models
#import "RKObjectLoaderTestResultModel.h"

@interface RKTestComplexUser : NSObject {
    NSNumber *_userID;
    NSString *_firstname;
    NSString *_lastname;
    NSString *_email;
    NSString *_phone;
}

@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *firstname;
@property (nonatomic, retain) NSString *lastname;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;

@end

@implementation RKTestComplexUser

@synthesize userID = _userID;
@synthesize firstname = _firstname;
@synthesize lastname = _lastname;
@synthesize phone = _phone;
@synthesize email = _email;

- (void)willSendWithObjectLoader:(RKObjectLoader *)objectLoader
{
    return;
}

@end

@interface RKTestResponseLoaderWithWillMapData : RKTestResponseLoader {
    id _mappableData;
}

@property (nonatomic, readonly) id mappableData;

@end

@implementation RKTestResponseLoaderWithWillMapData

@synthesize mappableData = _mappableData;

- (void)dealloc
{
    [_mappableData release];
    [super dealloc];
}

- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData
{
    [*mappableData setValue:@"monkey!" forKey:@"newKey"];
    _mappableData = [*mappableData retain];
}

@end

/////////////////////////////////////////////////////////////////////////////

@interface RKObjectLoaderTest : RKTestCase {

}

@end

@implementation RKObjectLoaderTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (RKObjectMappingProvider *)providerForComplexUser
{
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"firstname" toKeyPath:@"firstname"]];
    [provider setMapping:userMapping forKeyPath:@"data.STUser"];
    return provider;
}

- (RKObjectMappingProvider *)errorMappingProvider
{
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"" toKeyPath:@"errorMessage"]];
    errorMapping.rootKeyPath = @"errors";
    provider.errorMapping = errorMapping;
    return provider;
}

- (void)testShouldHandleTheErrorCaseAppropriately
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.mappingProvider = [self errorMappingProvider];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/errors.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    assertThat(responseLoader.error, isNot(nilValue()));
    assertThat([responseLoader.error localizedDescription], is(equalTo(@"error1, error2")));

    NSArray *objects = [[responseLoader.error userInfo] objectForKey:RKObjectMapperErrorObjectsKey];
    RKErrorMessage *error1 = [objects objectAtIndex:0];
    RKErrorMessage *error2 = [objects lastObject];

    assertThat(error1.errorMessage, is(equalTo(@"error1")));
    assertThat(error2.errorMessage, is(equalTo(@"error2")));
}

- (void)testShouldNotCrashWhenLoadingAnErrorResponseWithAnUnmappableMIMEType
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/404" delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.loadedUnexpectedResponse, is(equalToBool(YES)));
}

#pragma mark - Complex JSON

- (void)testShouldLoadAComplexUserObjectWithTargetObject
{
    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    NSString *authString = [NSString stringWithFormat:@"TRUEREST username=%@&password=%@&apikey=123456&class=iphone", @"username", @"password"];
    [objectLoader.URLRequest addValue:authString forHTTPHeaderField:@"Authorization"];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.targetObject = user;
    objectLoader.mappingProvider = [self providerForComplexUser];

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldLoadAComplexUserObjectWithoutTargetObject
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatUnsignedInteger([responseLoader.objects count], is(equalToInt(1)));
    RKTestComplexUser *user = [responseLoader.objects lastObject];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldLoadAComplexUserObjectUsingRegisteredKeyPath
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatUnsignedInteger([responseLoader.objects count], is(equalToInt(1)));
    RKTestComplexUser *user = [responseLoader.objects lastObject];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

#pragma mark - willSendWithObjectLoader:

- (void)testShouldInvokeWillSendWithObjectLoaderOnSend
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [[RKObjectLoader alloc] initWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/200"] mappingProvider:[self providerForComplexUser]];
    objectLoader.configurationDelegate = objectManager;
    objectLoader.sourceObject = mockObject;
    objectLoader.delegate = responseLoader;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader send];
    [responseLoader waitForResponse];
    [mockObject verify];
}

- (void)testShouldInvokeWillSendWithObjectLoaderOnSendAsynchronously
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    [objectManager setMappingProvider:[self providerForComplexUser]];
    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [RKObjectLoader loaderWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/200"] mappingProvider:objectManager.mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.sourceObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [mockObject verify];
}

- (void)testShouldInvokeWillSendWithObjectLoaderOnSendSynchronously
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    [objectManager setMappingProvider:[self providerForComplexUser]];
    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    RKObjectLoader *objectLoader = [RKObjectLoader loaderWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/200"] mappingProvider:objectManager.mappingProvider];
    objectLoader.sourceObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader sendSynchronously];
    [mockObject verify];
}

- (void)testShouldLoadResultsNestedAtAKeyPath
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [objectMapping mapKeyPath:@"id" toAttribute:@"ID"];
    [objectMapping mapKeyPath:@"ends_at" toAttribute:@"endsAt"];
    [objectMapping mapKeyPath:@"photo_url" toAttribute:@"photoURL"];
    [objectManager.mappingProvider setMapping:objectMapping forKeyPath:@"results"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/JSON/ArrayOfResults.json" delegate:loader];
    [loader waitForResponse];
    assertThat([loader objects], hasCountOf(2));
    assertThat([[[loader objects] objectAtIndex:0] ID], is(equalToInt(226)));
    assertThat([[[loader objects] objectAtIndex:0] photoURL], is(equalTo(@"1308262872.jpg")));
    assertThat([[[loader objects] objectAtIndex:1] ID], is(equalToInt(235)));
    assertThat([[[loader objects] objectAtIndex:1] photoURL], is(equalTo(@"1308634984.jpg")));
}

- (void)testShouldAllowMutationOfTheParsedDataInWillMapData
{
    RKTestResponseLoaderWithWillMapData *loader = (RKTestResponseLoaderWithWillMapData *)[RKTestResponseLoaderWithWillMapData responseLoader];
    RKObjectManager *manager = [RKTestFactory objectManager];
    [manager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:loader];
    [loader waitForResponse];
    assertThat([loader.mappableData valueForKey:@"newKey"], is(equalTo(@"monkey!")));
}

- (void)testShouldAllowYouToPostAnObjectAndHandleAnEmpty204Response
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router routeClass:[RKTestComplexUser class] toResourcePath:@"/204"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKTestComplexUser class]];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *loader = [objectManager loaderForObject:user method:RKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.objectMapping = mapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"blake@restkit.org")));
}

- (void)testShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContent
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router routeClass:[RKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKTestComplexUser class]];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *loader = [objectManager loaderForObject:user method:RKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.objectMapping = mapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)testShouldMapContentWithoutAMIMEType
{
    // TODO: Not sure that this is even worth it. Unable to get the Sinatra server to produce such a response
    return;
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [[RKParserRegistry sharedRegistry] setParserClass:[RKJSONParserJSONKit class] forMIMEType:@"text/html"];
    [objectManager.router routeClass:[RKTestComplexUser class] toResourcePath:@"/noMIME"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKTestComplexUser class]];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *loader = [objectManager loaderForObject:user method:RKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.objectMapping = mapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnother
{
    RKObjectMapping *sourceMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [sourceMapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    RKObjectMapping *targetMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [targetMapping mapAttributes:@"ID", nil];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router routeClass:[RKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKTestComplexUser class]];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *loader = [objectManager loaderForObject:user method:RKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.sourceObject = user;
    loader.targetObject = nil;
    loader.objectMapping = targetMapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));

    // Our original object should not have changed
    assertThat(user.email, is(equalTo(@"blake@restkit.org")));

    // And we should have a new one
    RKObjectLoaderTestResultModel *newObject = [[responseLoader objects] lastObject];
    assertThat(newObject, is(instanceOf([RKObjectLoaderTestResultModel class])));
    assertThat(newObject.ID, is(equalToInt(31337)));
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnotherViaURLConfiguration
{
    RKObjectMapping *sourceMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [sourceMapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    RKObjectMapping *targetMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [targetMapping mapAttributes:@"ID", nil];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router routeClass:[RKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKTestComplexUser class]];
    [objectManager.mappingProvider setObjectMapping:targetMapping forResourcePathPattern:@"/notNestedUser"];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *loader = [objectManager loaderForObject:user method:RKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.sourceObject = user;
    loader.targetObject = nil;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));

    // Our original object should not have changed
    assertThat(user.email, is(equalTo(@"blake@restkit.org")));

    // And we should have a new one
    RKObjectLoaderTestResultModel *newObject = [[responseLoader objects] lastObject];
    assertThat(newObject, is(instanceOf([RKObjectLoaderTestResultModel class])));
    assertThat(newObject.ID, is(equalToInt(31337)));
}

// TODO: Should live in a different file...
- (void)testShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContentViapostObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router routeClass:[RKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKTestComplexUser class]];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    // NOTE: The postObject: should infer the target object from sourceObject and the mapping class
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    [objectManager postObject:user usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)testShouldRespectTheRootKeyPathWhenConstructingATemporaryObjectMappingProvider
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];

    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.objectMapping = userMapping;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.targetObject = user;

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldDetermineObjectLoaderBasedOnResourcePathPatternWithExactMatch
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    [mappingProvider setObjectMapping:userMapping forResourcePathPattern:@"/JSON/ComplexNestedUser.json"];

    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/ComplexNestedUser.json"];
    RKObjectLoader *objectLoader = [RKObjectLoader loaderWithURL:URL mappingProvider:mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.targetObject = user;

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    NSLog(@"Response: %@", responseLoader.objects);

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldDetermineObjectLoaderBasedOnResourcePathPatternWithPartialMatch
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    [mappingProvider setObjectMapping:userMapping forResourcePathPattern:@"/JSON/:name\\.json"];

    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/ComplexNestedUser.json"];
    RKObjectLoader *objectLoader = [RKObjectLoader loaderWithURL:URL mappingProvider:mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.targetObject = user;

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    NSLog(@"Response: %@", responseLoader.objects);

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldReturnSuccessWhenTheStatusCodeIs200AndTheResponseBodyIsEmpty
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1234"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = userMapping;
    objectLoader.targetObject = user;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldInvokeTheDelegateWithTheTargetObjectWhenTheStatusCodeIs200AndTheResponseBodyIsEmpty
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];

    RKTestComplexUser *user = [[RKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];

    RKObjectLoader *objectLoader = [RKObjectLoader loaderWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/humans/1234"] mappingProvider:objectManager.mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = userMapping;
    objectLoader.targetObject = user;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, hasItem(user));
}

- (void)testShouldConsiderTheLoadOfEmptyObjectsWithoutAnyMappableAttributesAsSuccess
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping mapAttributes:@"firstname", nil];
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"firstUser"];
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"secondUser"];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/users/empty" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyArray
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/array" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)testShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyDictionary
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/dictionary" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)testShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyString
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/string" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)testShouldNotBlockNetworkOperationsWhileAwaitingObjectMapping
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestCache.storagePolicy = RKRequestCacheStoragePolicyDisabled;
    objectManager.client.requestQueue.concurrentRequestsLimit = 1;
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    userMapping.rootKeyPath = @"human";
    [userMapping mapAttributes:@"name", @"id", nil];

    // Suspend the Queue to block object mapping
    dispatch_suspend(objectManager.mappingQueue);

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    [objectManager.mappingProvider setObjectMapping:userMapping forResourcePathPattern:@"/humans/1"];
    [objectManager loadObjectsAtResourcePath:@"/humans/1" delegate:nil];
    [objectManager.client get:@"/empty/string" delegate:responseLoader];
    [responseLoader waitForResponse];

    // We should get a response is network is released even though object mapping didn't finish
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

#pragma mark - Block Tests

- (void)testInvocationOfDidLoadObjectBlock
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObject = ^(id object) {
        expectedResult = object;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(notNilValue()));
}

- (void)testInvocationOfDidLoadObjectBlockIsSingularObjectOfCorrectType
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObject = ^(id object) {
        expectedResult = object;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(instanceOf([RKTestComplexUser class])));
}

- (void)testInvocationOfDidLoadObjectsBlock
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjects = ^(NSArray *objects) {
        expectedResult = objects;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(notNilValue()));
}

- (void)testInvocationOfDidLoadObjectsBlocksIsCollectionOfObjects
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjects = ^(NSArray *objects) {
        expectedResult = [objects retain];
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    NSLog(@"The expectedResult = %@", expectedResult);
    assertThat(expectedResult, is(instanceOf([NSArray class])));
    assertThat(expectedResult, hasCountOf(1));
    [expectedResult release];
}

- (void)testInvocationOfDidLoadObjectsDictionaryBlock
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjectsDictionary = ^(NSDictionary *dictionary) {
        expectedResult = dictionary;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(notNilValue()));
}

- (void)testInvocationOfDidLoadObjectsDictionaryBlocksIsDictionaryOfObjects
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjectsDictionary = ^(NSDictionary *dictionary) {
        expectedResult = dictionary;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(instanceOf([NSDictionary class])));
    assertThat(expectedResult, hasCountOf(1));
}

// NOTE: Errors are fired in a number of contexts within the RKObjectLoader. We have centralized the cases into a private
// method and test that one case here. There should be better coverage for this.
- (void)testInvocationOfOnDidFailWithError
{
    RKObjectLoader *loader = [RKObjectLoader loaderWithURL:nil mappingProvider:nil];
    NSError *expectedError = [NSError errorWithDomain:@"Testing" code:1234 userInfo:nil];
    __block NSError *blockError = nil;
    loader.onDidFailWithError = ^(NSError *error) {
        blockError = error;
    };
    [loader performSelector:@selector(informDelegateOfError:) withObject:expectedError];
    assertThat(blockError, is(equalTo(expectedError)));
}

- (void)testShouldNotAssertDuringObjectMappingOnSynchronousRequest
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = userMapping;
    [objectLoader sendSynchronously];
    RKResponse *response = [objectLoader sendSynchronously];

    assertThatInteger(response.statusCode, is(equalToInt(200)));
}

@end
