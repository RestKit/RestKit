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

/////////////////////////////////////////////////////////////////////////////

// TODO: These specs need to be executed against the RKManagedObjectLoader and RKObjectLoader
// until we can collapse the functionality somehow...
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

@end

@interface RKAnotherUser : NSObject {
    NSNumber *userID;
    NSString *firstName;
    NSString *lastName;
    NSString *email;
    NSString *phone;
    NSString *availability;
    NSArray  *interests;
    NSString *singleAccessToken;
    NSString *password;
    NSString *passwordConfirmation;
    NSString *facebookAccessToken;
    NSDate *facebookAccessTokenExpirationDate;
}

@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSArray  *interests;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *singleAccessToken;
@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *passwordConfirmation;
@property (nonatomic, retain) NSString *facebookAccessToken;
@property (nonatomic, retain) NSDate* facebookAccessTokenExpirationDate;

@end

@implementation RKAnotherUser

@synthesize firstName;
@synthesize lastName;
@synthesize interests;
@synthesize email;
@synthesize phone;
@synthesize singleAccessToken;
@synthesize userID;
@synthesize password;
@synthesize passwordConfirmation;
@synthesize facebookAccessToken;
@synthesize facebookAccessTokenExpirationDate;

+ (NSDictionary*)elementToPropertyMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:
            @"id", @"userID",
            @"first_name", @"firstName",
            @"last_name", @"lastName",
            @"email", @"email",
            @"phone", @"phone",
            @"user_interests", @"interests",
            @"single_access_token", @"singleAccessToken",
            @"password", @"password",
            @"password_confirmation", @"passwordConfirmation",
            @"facebook_access_token", @"facebookAccessToken",
            @"facebook_access_token_expiration_date",
            @"facebookAccessTokenExpirationDate",
            nil];
}

@end

// Works with Michael Deung's RailsUser.json
@interface RKUserRailsJSONMappingSpec : RKSpec {
}
@end

@implementation RKUserRailsJSONMappingSpec

- (RKObjectMappingProvider*)mappingProvider {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKAnotherUser class]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"first_name" toKeyPath:@"firstName"]];
    [provider setObjectMapping:mapping forKeyPath:@"user"];
    return provider;
}

//- (void)itShouldMapWhenGivenARegisteredClassMapping {
//    RKObjectManager* objectManager = RKSpecNewObjectManager();
//    RKSpecStubNetworkAvailability(YES);
//    RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
//    [router setModelName:@"user" forClass:[RKAnotherUser class]];
//    
//    [objectManager setMappingProvider:[self mappingProvider]];
//
//    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
//    [objectManager loadObjectsAtResourcePath:@"/JSON/RailsUser.json" delegate:responseLoader];
//    [responseLoader waitForResponse];
//    RKAnotherUser* user = [responseLoader.objects objectAtIndex:0];
//    [expectThat(user.firstName) should:be(@"Test")];
//}

@end
