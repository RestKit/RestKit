//
//  RKObjectLoaderSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/27/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKRailsRouter.h"

@interface RKSpecComplexUser : RKObject {
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
@interface RKObjectLoaderSpec : NSObject <UISpec> {
}

@end

@implementation RKObjectLoaderSpec

- (void)beforeAll {
    RKRequestQueue* queue = [[RKRequestQueue alloc] init];
    queue.suspended = NO;
    [RKRequestQueue setSharedQueue:queue];
    [queue release];
}

// TODO: Should move into a mapping scenario
#pragma mark - Complex JSON

- (void)itShouldLoadAComplexUserObjectWithTargetObject {
    RKSpecComplexUser* user = [RKSpecComplexUser object];
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    NSString *authString = [NSString stringWithFormat:@"TRUEREST username=%@&password=%@&apikey=123456&class=iphone", @"username", @"password"];
    [objectLoader.URLRequest addValue:authString forHTTPHeaderField:@"Authorization"];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.targetObject = user;
    objectLoader.keyPath = @"data.STUser";
    objectLoader.objectClass = [RKSpecComplexUser class];
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

- (void)itShouldLoadAComplexUserObjectWithoutTargetObject {    
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.keyPath = @"data.STUser";
    objectLoader.objectClass = [RKSpecComplexUser class];
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [expectThat([responseLoader.objects count]) should:be(1)];
    RKSpecComplexUser* user = [responseLoader.objects lastObject];
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

- (void)itShouldLoadAComplexUserObjectUsingRegisteredKeyPath {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [objectManager registerClass:[RKSpecComplexUser class] forElementNamed:@"data.STUser"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    objectLoader.method = RKRequestMethodGET;
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [expectThat([responseLoader.objects count]) should:be(1)];
    RKSpecComplexUser* user = [responseLoader.objects lastObject];
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

- (void)itShouldNotLoadAComplexUserObjectUsingRegisteredKeyPathAndExplicitObjectClass {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [objectManager registerClass:[RKSpecComplexUser class] forElementNamed:@"data.STUser"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectClass = [RKSpecComplexUser class];
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [expectThat([responseLoader.objects count]) should:be(1)];
    RKSpecComplexUser* user = [responseLoader.objects lastObject];
    
    [expectThat(user.firstname) should:be(nil)];
}

- (void)itShouldLoadAComplexUserObjectUsingRegisteredKeyPathAndExplicitObjectClassAndKeyPath {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [objectManager registerClass:[RKSpecComplexUser class] forElementNamed:@"data.STUser"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/JSON/ComplexNestedUser.json" delegate:responseLoader];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.keyPath = @"data.STUser";
    objectLoader.objectClass = [RKSpecComplexUser class];
    
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [expectThat([responseLoader.objects count]) should:be(1)];
    RKSpecComplexUser* user = [responseLoader.objects lastObject];
    
    [expectThat(user.firstname) should:be(@"Diego")];
}

#pragma mark - willSendWithObjectLoader:

- (void)itShouldInvokeWillSendWithObjectLoaderOnSend {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecComplexUser* user = [RKSpecComplexUser object];
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
    RKSpecComplexUser* user = [RKSpecComplexUser object];
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
    RKSpecComplexUser* user = [RKSpecComplexUser object];
    id mockObject = [OCMockObject partialMockForObject:user];
    
    // Explicitly init so we don't get a managed object loader...
    RKObjectLoader* objectLoader = [[RKObjectLoader alloc] initWithResourcePath:@"/" objectManager:objectManager delegate:nil];
    objectLoader.targetObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader sendSynchronously];
    [mockObject verify];
}

@end

@interface RKAnotherUser : RKObject {
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
@interface RKUserRailsJSONMappingSpec : NSObject <UISpec> {
}
@end

@implementation RKUserRailsJSONMappingSpec

- (void)itShouldMapWhenGivenARegisteredClassMapping {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
    [router setModelName:@"user" forClass:[RKAnotherUser class]];
    
    [objectManager registerClass:[RKAnotherUser class] forElementNamed:@"user"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/JSON/RailsUser.json" delegate:responseLoader];
    [responseLoader waitForResponse];
    RKAnotherUser* user = [responseLoader.objects objectAtIndex:0];
    [expectThat(user.firstName) should:be(@"Test")];
}

- (void)itShouldMapToAnEmptyObjectAndLogAWarningWhenExplicitlyGivenAnObjectClassAndThePayloadIsNotMappable {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
    [router setModelName:@"user" forClass:[RKAnotherUser class]];
    
    [objectManager registerClass:[RKAnotherUser class] forElementNamed:@"user"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* loader = [objectManager objectLoaderWithResourcePath:@"/JSON/RailsUser.json" delegate:responseLoader];
    loader.objectClass = [RKAnotherUser class];
    [loader send];
    [responseLoader waitForResponse];
    RKAnotherUser* user = [responseLoader.objects objectAtIndex:0];
    [expectThat(user.firstName) should:be(nil)];
    // TODO: Can't test the log message right now...
}

- (void)itShouldMapWhenGivenAKeyPathAndAnObjectClassAndTheClassIsRegistered {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
    [router setModelName:@"user" forClass:[RKAnotherUser class]];
    
    [objectManager registerClass:[RKAnotherUser class] forElementNamed:@"user"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* loader = [objectManager objectLoaderWithResourcePath:@"/JSON/RailsUser.json" delegate:responseLoader];
    loader.keyPath = @"user";
    loader.objectClass = [RKAnotherUser class];
    [loader send];
    [responseLoader waitForResponse];
    RKAnotherUser* user = [responseLoader.objects objectAtIndex:0];
    [expectThat(user.firstName) should:be(@"Test")];
}

- (void)itShouldMapWhenGivenAKeyPathAndAnObjectClassAndTheClassIsNotRegistered {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
    [router setModelName:@"user" forClass:[RKAnotherUser class]];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader* loader = [objectManager objectLoaderWithResourcePath:@"/JSON/RailsUser.json" delegate:responseLoader];
    loader.keyPath = @"user";
    loader.objectClass = [RKAnotherUser class];
    [loader send];
    [responseLoader waitForResponse];
    RKAnotherUser* user = [responseLoader.objects objectAtIndex:0];
    [expectThat(user.firstName) should:be(@"Test")];
}

@end
