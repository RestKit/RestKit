//
//  RKObjectLoaderSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/27/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectMappingProvider.h"
#import "RKErrorMessage.h"

// Models
#import "RKObjectLoaderSpecResultModel.h"

@interface RKSpecComplexUser : NSObject {
    NSNumber* _userID;
    NSString* _firstname;
    NSString* _lastname;
    NSString* _email;
    NSString* _phone;
}

@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSString* firstname;
@property (nonatomic, retain) NSString* lastname;
@property (nonatomic, retain) NSString* email;
@property (nonatomic, retain) NSString* phone;

@end

@implementation RKSpecComplexUser

@synthesize userID = _userID;
@synthesize firstname = _firstname;
@synthesize lastname = _lastname;
@synthesize phone = _phone;
@synthesize email = _email;

+ (NSDictionary*)elementToPropertyMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:
            @"id", @"userID",
            @"firstname", @"firstname",
            @"lastname", @"lastname", 
            @"email", @"email",
            @"phone", @"phone",
            nil];
}

- (void)willSendWithObjectLoader:(RKObjectLoader *)objectLoader {
    NSLog(@"RKSpecComplexUser willSendWithObjectLoader: INVOKED!!");
    return;
}

@end

@interface RKSpecResponseLoaderWithWillMapData : RKSpecResponseLoader {
    id _mappableData;
}

@property (nonatomic, readonly) id mappableData;

@end

@implementation RKSpecResponseLoaderWithWillMapData

@synthesize mappableData = _mappableData;

- (void)dealloc {
    [_mappableData release];
    [super dealloc];
}

- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData {
    [*mappableData setValue:@"monkey!" forKey:@"newKey"];
    _mappableData = [*mappableData retain];
}

@end

/////////////////////////////////////////////////////////////////////////////

@interface RKObjectLoaderSpec : RKSpec {
    
}

@end

@implementation RKObjectLoaderSpec

- (void)beforeAll {
    RKRequestQueue* queue = [[RKRequestQueue alloc] init];
    queue.suspended = NO;
    [RKRequestQueue setSharedQueue:queue];
    [queue release];
}

- (RKObjectMappingProvider*)providerForComplexUser {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    [userMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"firstname" toKeyPath:@"firstname"]];
    [provider setMapping:userMapping forKeyPath:@"data.STUser"];
    return provider;
}

- (RKObjectMappingProvider*)errorMappingProvider {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping* errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"" toKeyPath:@"errorMessage"]];
    [provider setMapping:errorMapping forKeyPath:@"error"];
    [provider setMapping:errorMapping forKeyPath:@"errors"];
    return provider;
}

- (void)itShouldHandleTheErrorCaseAppropriately {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/errors.json" delegate:responseLoader];
    objectLoader.method = RKRequestMethodGET;
    
    [objectManager setMappingProvider:[self errorMappingProvider]];
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    
    [expectThat(responseLoader.failureError) shouldNot:be(nil)];
    
    [expectThat([responseLoader.failureError localizedDescription]) should:be(@"error1, error2")];
    
    NSArray* objects = [[responseLoader.failureError userInfo] objectForKey:RKObjectMapperErrorObjectsKey];
    RKErrorMessage* error1 = [objects objectAtIndex:0];
    RKErrorMessage* error2 = [objects lastObject];
    
    [expectThat(error1.errorMessage) should:be(@"error1")];
    [expectThat(error2.errorMessage) should:be(@"error2")];
}

- (void)itShouldNotCrashWhenLoadingAnErrorResponseWithAnUnmappableMIMEType {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/404" delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.unknownResponse, is(equalToBool(YES)));
}

#pragma mark - Complex JSON

- (void)itShouldLoadAComplexUserObjectWithTargetObject {
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    NSString *authString = [NSString stringWithFormat:@"TRUEREST username=%@&password=%@&apikey=123456&class=iphone", @"username", @"password"];
    [objectLoader.URLRequest addValue:authString forHTTPHeaderField:@"Authorization"];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.targetObject = user;

    [objectManager setMappingProvider:[self providerForComplexUser]];
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    
    NSLog(@"Response: %@", responseLoader.objects);
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

- (void)itShouldLoadAComplexUserObjectWithoutTargetObject {    
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    objectLoader.method = RKRequestMethodGET;
    
    [objectManager setMappingProvider:[self providerForComplexUser]];
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [expectThat([responseLoader.objects count]) should:be(1)];
    RKSpecComplexUser* user = [responseLoader.objects lastObject];
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

- (void)itShouldLoadAComplexUserObjectUsingRegisteredKeyPath {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    objectLoader.method = RKRequestMethodGET;
    
    [objectManager setMappingProvider:[self providerForComplexUser]];
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [expectThat([responseLoader.objects count]) should:be(1)];
    RKSpecComplexUser* user = [responseLoader.objects lastObject];
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

#pragma mark - willSendWithObjectLoader:

- (void)itShouldInvokeWillSendWithObjectLoaderOnSend {
//    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager setMappingProvider:[self providerForComplexUser]];
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [[RKObjectLoader alloc] initWithResourcePath:@"/" objectManager:objectManager delegate:responseLoader];
    objectLoader.sourceObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader send];
    [responseLoader waitForResponse];    
    [mockObject verify];
}

- (void)itShouldInvokeWillSendWithObjectLoaderOnSendAsynchronously {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [objectManager setMappingProvider:[self providerForComplexUser]];
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];
    
    // Explicitly init so we don't get a managed object loader...
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [[RKObjectLoader alloc] initWithResourcePath:@"/" objectManager:objectManager delegate:responseLoader];
    objectLoader.sourceObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];    
    [mockObject verify];
}

- (void)itShouldInvokeWillSendWithObjectLoaderOnSendSynchronously {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [objectManager setMappingProvider:[self providerForComplexUser]];
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];
    
    // Explicitly init so we don't get a managed object loader...
    RKObjectLoader* objectLoader = [[RKObjectLoader alloc] initWithResourcePath:@"/" objectManager:objectManager delegate:nil];
    objectLoader.sourceObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader sendSynchronously];
    [mockObject verify];
}

- (void)itShouldLoadResultsNestedAtAKeyPath {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKObjectMapping* objectMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderSpecResultModel class]];
    [objectMapping mapKeyPath:@"id" toAttribute:@"ID"];
    [objectMapping mapKeyPath:@"ends_at" toAttribute:@"endsAt"];
    [objectMapping mapKeyPath:@"photo_url" toAttribute:@"photoURL"];
    [objectManager.mappingProvider setMapping:objectMapping forKeyPath:@"results"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/JSON/ArrayOfResults.json" delegate:loader];
    [loader waitForResponse];
    assertThat([loader objects], hasCountOf(2));
    assertThat([[[loader objects] objectAtIndex:0] ID], is(equalToInt(226)));
    assertThat([[[loader objects] objectAtIndex:0] photoURL], is(equalTo(@"1308262872.jpg")));
    assertThat([[[loader objects] objectAtIndex:1] ID], is(equalToInt(235)));
    assertThat([[[loader objects] objectAtIndex:1] photoURL], is(equalTo(@"1308634984.jpg")));
}

- (void)itShouldAllowMutationOfTheParsedDataInWillMapData {
    RKSpecResponseLoaderWithWillMapData* loader = (RKSpecResponseLoaderWithWillMapData*)[RKSpecResponseLoaderWithWillMapData responseLoader];
    RKObjectManager* manager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    [manager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:loader];
    [loader waitForResponse];
    assertThat([loader.mappableData valueForKey:@"newKey"], is(equalTo(@"monkey!")));
}

- (void)itShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContent {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping* serializationMapping = [mapping inverseMapping];
    
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.router routeClass:[RKSpecComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKSpecComplexUser class]];
    
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* loader = [objectManager objectLoaderForObject:user method:RKRequestMethodPOST delegate:responseLoader];
    loader.objectMapping = mapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader success], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)itShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnother {
    RKObjectMapping* sourceMapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    [sourceMapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping* serializationMapping = [sourceMapping inverseMapping];
    
    RKObjectMapping* targetMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderSpecResultModel class]];
    [targetMapping mapAttributes:@"ID", nil];
    
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.router routeClass:[RKSpecComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKSpecComplexUser class]];
    
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* loader = [objectManager objectLoaderForObject:user method:RKRequestMethodPOST delegate:responseLoader];
    loader.sourceObject = user;
    loader.targetObject = nil;
    loader.objectMapping = targetMapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader success], is(equalToBool(YES)));
    
    // Our original object should not have changed
    assertThat(user.email, is(equalTo(@"blake@restkit.org")));
    
    // And we should have a new one
    RKObjectLoaderSpecResultModel* newObject = [[responseLoader objects] lastObject];
    assertThat(newObject, is(instanceOf([RKObjectLoaderSpecResultModel class])));
    assertThat(newObject.ID, is(equalToInt(31337)));
}

// TODO: Should live in a different file...
- (void)itShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContentViapostObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    RKObjectMapping* serializationMapping = [mapping inverseMapping];
    
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.router routeClass:[RKSpecComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[RKSpecComplexUser class]];
    
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    // NOTE: The postObject: should infer the target object from sourceObject and the mapping class
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    [objectManager postObject:user mapResponseWith:mapping delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader success], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)itShouldRespectTheRootKeyPathWhenConstructingATemporaryObjectMappingProvider {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    objectLoader.objectMapping = userMapping;
    objectLoader.method = RKRequestMethodGET;
    objectLoader.targetObject = user;
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    
    NSLog(@"Response: %@", responseLoader.objects);
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

- (void)itShouldReturnSuccessWhenTheStatusCodeIs200AndTheResponseBodyIsEmpty {
    RKObjectManager* objectManager = RKSpecNewObjectManager();

    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [RKObjectLoader loaderWithResourcePath:@"/humans/1234" objectManager:objectManager delegate:responseLoader];
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = userMapping;
    objectLoader.targetObject = user;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.success, is(equalToBool(YES)));
}

- (void)itShouldInvokeTheDelegateWithTheTargetObjectWhenTheStatusCodeIs200AndTheResponseBodyIsEmpty {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [RKObjectLoader loaderWithResourcePath:@"/humans/1234" objectManager:objectManager delegate:responseLoader];
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = userMapping;
    objectLoader.targetObject = user;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, hasItem(user));
}

- (void)itShouldConsiderTheLoadOfEmptyObjectsWithoutAnyMappableAttributesAsSuccess {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKSpecComplexUser class]];
    [userMapping mapAttributes:@"firstname", nil];
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"firstUser"];
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"secondUser"];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/users/empty" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.success, is(equalToBool(YES)));
}

- (void)itShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyArray {
    RKObjectManager* objectManager = RKSpecNewObjectManager();    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/array" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)itShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyDictionary {
    RKObjectManager* objectManager = RKSpecNewObjectManager();    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/dictionary" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)itShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyString {
    RKObjectManager* objectManager = RKSpecNewObjectManager();    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/string" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}
@end
