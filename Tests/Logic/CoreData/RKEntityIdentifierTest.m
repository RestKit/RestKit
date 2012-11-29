//
//  RKEntityIndexTest.m
//  RestKit
//
//  Created by Blake Watters on 11/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKEntityIdentifier.h"

@interface RKEntityIdentifierTest : RKTestCase

@end

@implementation RKEntityIdentifierTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)testThatInitEntityIdentifierWithNilAttributesRaisesException
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    NSException *expectedExcepetion = nil;
    @try {
        RKEntityIdentifier *entityIdentifier __unused = [[RKEntityIdentifier alloc] initWithEntity:entity attributes:nil];
    }
    @catch (NSException *exception) {
        expectedExcepetion = exception;
    }
    expect(expectedExcepetion).notTo.beNil();
    expect([expectedExcepetion description]).to.equal(@"Invalid parameter not satisfying: attributes");
}

- (void)testThatInitEntityIdentifierWithEmptyAttributesRaisesException
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    NSException *expectedExcepetion = nil;
    @try {
        RKEntityIdentifier *entityIdentifier __unused = [[RKEntityIdentifier alloc] initWithEntity:entity attributes:@[]];
    }
    @catch (NSException *exception) {
        expectedExcepetion = exception;
    }
    expect(expectedExcepetion).notTo.beNil();
    expect([expectedExcepetion description]).to.equal(@"At least one attribute must be provided to identify managed objects");
}

- (void)testThatInitWithInvalidEntityNameRaisesError
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSException *expectedExcepetion = nil;
    @try {
        RKEntityIdentifier *entityIdentifier __unused = [RKEntityIdentifier identifierWithEntityName:@"Invalid" attributes:nil inManagedObjectStore:managedObjectStore];
    }
    @catch (NSException *exception) {
        expectedExcepetion = exception;
    }
    expect(expectedExcepetion).notTo.beNil();
    expect([expectedExcepetion description]).to.equal(@"Invalid parameter not satisfying: entity");
}

- (void)testInitializingEntityIdentifierByName
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSAttributeDescription *railsIDAttribute = entity.attributesByName[@"railsID"];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    expect(entityIdentifier.entity).to.equal(entity);
    NSArray *attributes = @[ railsIDAttribute ];
    expect(entityIdentifier.attributes).equal(attributes);
}

#pragma mark - Entity Identifier Inference

// TODO: The attributes to auto-detect: entityNameID, ID, identififer, url, URL

- (void)testEntityIdentifierInferenceForEntityWithLlamaCasedIDAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    [entity setProperties:@[ identifierAttribute ]];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    expect(entityIdentifier).notTo.beNil();
    NSArray *attributeNames = @[ @"monkeyID" ];
    expect([[entityIdentifier attributes] valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithIDAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"ID"];
    [entity setProperties:@[ identifierAttribute ]];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    expect(entityIdentifier).notTo.beNil();
    NSArray *attributeNames = @[ @"ID" ];
    expect([[entityIdentifier attributes] valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithIdentifierAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"identifier"];
    [entity setProperties:@[ identifierAttribute ]];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    expect(entityIdentifier).notTo.beNil();
    NSArray *attributeNames = @[ @"identifier" ];
    expect([[entityIdentifier attributes] valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithURLAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"URL"];
    [entity setProperties:@[ identifierAttribute ]];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    expect(entityIdentifier).notTo.beNil();
    NSArray *attributeNames = @[ @"URL" ];
    expect([[entityIdentifier attributes] valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithUrlAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"url"];
    [entity setProperties:@[ identifierAttribute ]];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    expect(entityIdentifier).notTo.beNil();
    NSArray *attributeNames = @[ @"url" ];
    expect([[entityIdentifier attributes] valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyForSingleValue
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"]; // We ignore this by specifying the userInfo key
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentifierUserInfoKey: @"name" }];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    expect(entityIdentifier).notTo.beNil();
    NSArray *attributeNames = @[ @"name" ];
    expect([[entityIdentifier attributes] valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyForArrayOfValues
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentifierUserInfoKey: @[ @"name", @"monkeyID" ] }];
    RKEntityIdentifier *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    expect(entityIdentifier).notTo.beNil();
    NSArray *attributeNames = @[ @"name", @"monkeyID" ];
    expect([[entityIdentifier attributes] valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyRaisesErrorForInvalidValue
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentifierUserInfoKey: @(12345) }];
    
    NSException *caughtException = nil;
    @try {
        RKEntityIdentifier __unused *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect([caughtException name]).to.equal(NSInvalidArgumentException);
        expect([caughtException reason]).to.equal(@"Invalid value given in user info key 'RKEntityIdentifierAttributes' of entity 'Monkey': expected an `NSString` or `NSArray` of strings, instead got '12345' (__NSCFNumber)");
    }
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyRaisesErrorForNonexistantAttributeName
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    [entity setProperties:@[ identifierAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentifierUserInfoKey: @"nonExistant" }];
    
    NSException *caughtException = nil;
    @try {
        RKEntityIdentifier __unused *entityIdentifier = [RKEntityIdentifier inferredIdentifierForEntity:entity];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect([caughtException name]).to.equal(NSInvalidArgumentException);
        expect([caughtException reason]).to.equal(@"Invalid identifier attribute specified in user info key 'RKEntityIdentifierAttributes' of entity 'Monkey': no attribue was found with the name 'nonExistant'");
    }
}

@end
