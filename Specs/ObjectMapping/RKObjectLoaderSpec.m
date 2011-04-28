//
//  RKObjectLoaderSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/27/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"

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

- (void)itShouldLoadAComplexUserObject {
    RKSpecComplexUser* user = [RKSpecComplexUser object];
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    RKObjectLoader* objectLoader = [objectManager objectLoaderWithResourcePath:@"/complex_nested_user" delegate:responseLoader];
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
