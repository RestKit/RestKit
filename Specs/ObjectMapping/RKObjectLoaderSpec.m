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

- (void)objectLoader:(RKObjectLoader *)loader willMapData:(id)mappableData {
    [mappableData setValue:@"monkey!" forKey:@"newKey"];
    _mappableData = [mappableData retain];
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
    [provider setObjectMapping:userMapping forKeyPath:@"data.STUser"];
    return provider;
}

- (RKObjectMappingProvider*)errorMappingProvider {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping* errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"" toKeyPath:@"errorMessage"]];
    [provider setObjectMapping:errorMapping forKeyPath:@"error"];
    [provider setObjectMapping:errorMapping forKeyPath:@"errors"];
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
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [objectManager setMappingProvider:[self providerForComplexUser]];
    RKSpecComplexUser* user = [[RKSpecComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [[RKObjectLoader alloc] initWithResourcePath:@"/" objectManager:objectManager delegate:responseLoader];
    objectLoader.targetObject = mockObject;
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
    objectLoader.targetObject = mockObject;
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
    objectLoader.targetObject = mockObject;
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
    [objectManager.mappingProvider setObjectMapping:objectMapping forKeyPath:@"results"];
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

@end
