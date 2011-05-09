//
//  RKObjectMappingNextGenSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>
#import "RKSpecEnvironment.h"
#import "RKJSONParser.h"
#import "RKObjectMapping.h"
#import "RKObjectMappingOperation.h"
#import "RKObjectAttributeMapping.h"
#import "RKObjectRelationshipMapping.h"
#import "Logging.h"
#import "RKObjectMapper.h"
#import "RKObjectMapper_Private.h"

////////////////////////////////////////////////////////////////////////////////

@interface RKSpecAddress : NSObject {
    NSNumber* _addressID;
    NSString* _city;
    NSString* _state;
    NSString* _country;
}

@property (nonatomic, retain) NSNumber* addressID;
@property (nonatomic, retain) NSString* city;
@property (nonatomic, retain) NSString* state;
@property (nonatomic, retain) NSString* country;

@end

@implementation RKSpecAddress

@synthesize addressID = _addressID;
@synthesize city = _city;
@synthesize state = _state;
@synthesize country = _country;

+ (RKSpecAddress*)address {
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[RKSpecAddress class]]) {
        return [[(RKSpecAddress*)object addressID] isEqualToNumber:self.addressID];
    } else {
        return NO;
    }
}

@end

@interface RKExampleUser : NSObject {
    NSNumber* _userID;
    NSString* _name;
    NSDate* _birthDate;
    NSArray* _favoriteColors;
    NSDictionary* _addressDictionary;
    NSURL* _website;
    NSNumber* _isDeveloper;
    NSNumber* _luckyNumber;
    NSDecimalNumber* _weight;
    NSArray* _interests;
    NSString* _country;
    
    // Relationships
    RKSpecAddress* _address;
    NSArray* _friends;
}

@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSDate* birthDate;
@property (nonatomic, retain) NSArray* favoriteColors;
@property (nonatomic, retain) NSDictionary* addressDictionary;
@property (nonatomic, retain) NSURL* website;
@property (nonatomic, retain) NSNumber* isDeveloper;
@property (nonatomic, retain) NSNumber* luckyNumber;
@property (nonatomic, retain) NSDecimalNumber* weight;
@property (nonatomic, retain) NSArray* interests;
@property (nonatomic, retain) NSString* country;
@property (nonatomic, retain) RKSpecAddress* address;
@property (nonatomic, retain) NSArray* friends;
@property (nonatomic, retain) NSSet* friendsSet;

@end

@implementation RKExampleUser

@synthesize userID = _userID;
@synthesize name = _name;
@synthesize birthDate = _birthDate;
@synthesize favoriteColors = _favoriteColors;
@synthesize addressDictionary = _addressDictionary;
@synthesize website = _website;
@synthesize isDeveloper = _isDeveloper;
@synthesize luckyNumber = _luckyNumber;
@synthesize weight = _weight;
@synthesize interests = _interests;
@synthesize country = _country;
@synthesize address = _address;
@synthesize friends = _friends;
@synthesize friendsSet = _friendsSet;

+ (RKExampleUser*)user {
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[RKExampleUser class]]) {
        return [[(RKExampleUser*)object userID] isEqualToNumber:self.userID];
    } else {
        return NO;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////

#pragma mark -

@interface RKObjectMappingNextGenSpec : NSObject <UISpec> {
    
}

@end

@implementation RKObjectMappingNextGenSpec

- (void)beforeAll {
    LoggerSetViewerHost(NULL, (CFStringRef) @"localhost", 50000);
    LoggerStart(LoggerGetDefaultLogger());
    LoggerSetOptions(NULL,						// configure the default logger
//                     kLoggerOption_LogToConsole | 
                     kLoggerOption_BufferLogsUntilConnection |
                     kLoggerOption_UseSSL |
                     kLoggerOption_BrowseBonjour |
                     kLoggerOption_BrowseOnlyLocalDomain);
}

- (void)afterAll {
    LoggerFlush(NULL, YES);
}

#pragma mark - RKObjectKeyPathMapping Specs

- (void)itShouldDefineElementToPropertyMapping {
    RKObjectAttributeMapping* elementMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [expectThat(elementMapping.sourceKeyPath) should:be(@"id")];
    [expectThat(elementMapping.destinationKeyPath) should:be(@"userID")];
}

- (void)itShouldDescribeElementMappings {
    RKObjectAttributeMapping* elementMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [expectThat([elementMapping description]) should:be(@"RKObjectKeyPathMapping: id => userID")];
}

#pragma mark - RKObjectMapping Specs

- (void)itShouldDefineMappingFromAnElementToAProperty {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    [expectThat([mapping mappingForKeyPath:@"id"] == idMapping) should:be(YES)];
    // [expectThat([mapping mappingForKeyPath:@"id"]) should:be(idMapping)]; // TODO: Trigger UIExpectation be() matcher bug...
}

- (void)itShouldAddMappingsToAttributeMappings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    [expectThat([mapping.mappings containsObject:idMapping]) should:be(YES)];
    [expectThat([mapping.attributeMappings containsObject:idMapping]) should:be(YES)];
}

- (void)itShouldAddMappingsToRelationshipMappings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectRelationshipMapping* idMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"id" toKeyPath:@"userID" objectMapping:nil];
    [mapping addRelationshipMapping:idMapping];
    [expectThat([mapping.mappings containsObject:idMapping]) should:be(YES)];
    [expectThat([mapping.relationshipMappings containsObject:idMapping]) should:be(YES)];
}

#pragma mark - RKObjectMapper Specs

- (void)itShouldPerformBasicMapping {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:mapping];
    [mapper release];
    [expectThat(success) should:be(YES)];
    [expectThat(user.userID) should:be(31337)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldMapACollectionOfSimpleObjectDictionaries {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
   
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    NSArray* users = [mapper mapCollection:userInfo atKeyPath:@"" usingMapping:mapping];
    [expectThat([users count]) should:be(3)];
    RKExampleUser* blake = [users objectAtIndex:0];
    [expectThat(blake.name) should:be(@"Blake Watters")];
    [mapper release];
}
                                    
- (void)itShouldDetermineTheObjectMappingByConsultingTheMappingProviderWhenThereIsATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
        
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [RKExampleUser user];
    [mapper performMapping];
    
    [mockProvider verify];
}

- (void)itShouldAddAnErrorWhenTheKeyPathMappingAndObjectClassDoNotAgree {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [NSDictionary new];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(2)];
}

- (void)itShouldMapToATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    RKExampleUser* user = [RKExampleUser user];
    mapper.targetObject = user;
    RKObjectMappingResult* result = [mapper performMapping];
    
    [mockProvider verify];
    [expectThat(result) shouldNot:be(nil)];
    NSLog(@"Got back result: %@", result);
    NSLog(@"Got back result object: %@", [result asObject]);
    [expectThat([result asObject] == user) should:be(YES)];    
//    [expectThat(@"1234") should:be(user)];
//    [expectThat(userReference) should:be(user)]; // TODO: This kind of invocation of the be() matcher causes UISpec to fuck up memory management
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldCreateANewInstanceOfTheAppropriateDestinationObjectWhenThereIsNoTargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    id mappingResult = [[mapper performMapping] asObject];
    [expectThat([mappingResult isKindOfClass:[RKExampleUser class]]) should:be(YES)];
}

- (void)itShouldDetermineTheMappingClassForAKeyPathByConsultingTheMappingProviderWhenMappingADictionaryWithoutATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];        
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    [[mockProvider expect] keyPathsAndObjectMappings];
        
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    [mapper performMapping];
    [mockProvider verify];
}

- (void)itShouldMapWithoutATargetMapping {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    RKExampleUser* user = [[mapper performMapping] asObject];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldMapACollectionOfObjects {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult* result = [mapper performMapping];
    NSArray* users = [result asCollection];
    [expectThat([users isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([users count]) should:be(3)];
    RKExampleUser* user = [users objectAtIndex:0];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldBeAbleToMapFromAUserObjectToADictionary {    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];
    
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:user mappingProvider:provider];
    RKObjectMappingResult* result = [mapper performMapping];
    NSDictionary* userInfo = [result asObject];
    [expectThat([userInfo isKindOfClass:[NSDictionary class]]) should:be(YES)];
    [expectThat([userInfo valueForKey:@"name"]) should:be(@"Blake Watters")];
}


- (void)itShouldMapRegisteredSubKeyPathsOfAnUnmappableDictionaryAndReturnTheResults {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"user"];
    
    id userInfo = RKSpecParseFixtureJSON(@"nested_user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    NSDictionary* dictionary = [[mapper performMapping] asDictionary];
    [expectThat([dictionary isKindOfClass:[NSDictionary class]]) should:be(YES)];
    RKExampleUser* user = [dictionary objectForKey:@"user"];
    [expectThat(user) shouldNot:be(nil)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

#pragma mark Mapping Error States

- (void)itShouldAddAnErrorWhenYouTryToMapAnArrayToATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = [RKExampleUser user];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(2)];
    [expectThat([[mapper.errors objectAtIndex:0] code]) should:be(RKObjectMapperErrorObjectMappingTypeMismatch)];
}

- (void)itShouldAddAnErrorWhenAttemptingToMapADictionaryWithoutAnObjectMapping {
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
    [expectThat([[mapper.errors objectAtIndex:0] localizedDescription]) should:be(@"Could not find an object mapping for keyPath: ")];
}

- (void)itShouldAddAnErrorWhenAttemptingToMapACollectionWithoutAnObjectMapping {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
    [expectThat([[mapper.errors objectAtIndex:0] localizedDescription]) should:be(@"Could not find an object mapping for keyPath: ")];
}

#pragma mark RKObjectMapperDelegate Specs

- (void)itShouldInformTheDelegateWhenMappingBegins {
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapperWillBeginMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldInformTheDelegateWhenMappingEnds {
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate stub] objectMapperWillBeginMapping:mapper];
    [[mockDelegate expect] objectMapperDidFinishMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsSuccessful {
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didFindMappableObject:[OCMArg any] atKeyPath:@""withMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsNotSuccessful {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    [provider setMapping:mapping forKeyPath:@"users"];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    [[mockDelegate expect] objectMapper:mapper didNotFindMappableObjectAtKeyPath:@"users"];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldInformTheDelegateOfError {
    id mockProvider = [OCMockObject niceMockForClass:[RKObjectMappingProvider class]];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    [[mockDelegate expect] objectMapper:mapper didAddError:[OCMArg isNotNil]];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenItWillMapAnObject {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    [provider setMapping:mapping forKeyPath:@""];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper willMapFromObject:userInfo toObject:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenItDidMapAnObject {
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didMapFromObject:userInfo toObject:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenItFailedToMapAnObject {
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didFailMappingFromObject:userInfo toObject:[OCMArg any] withError:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

#pragma mark - RKObjectManager specs

// TODO: Map with registered object types
- (void)itShouldImplementKeyPathToObjectMappingRegistrationServices {
    // Here we want it to find the registered mapping for a class and use that to process the mapping
}

- (void)itShouldSetSelfAsTheObjectMapperDelegateForObjectLoadersCreatedViaTheManager {
    
}

#pragma mark - RKObjectMappingOperationSpecs

- (void)itShouldBeAbleToMapADictionaryToAUser {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:123], @"id", @"Blake Watters", @"name", nil];
    RKExampleUser* user = [RKExampleUser user];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    [operation performMapping:nil];    
    [expectThat(user.name) should:be(@"Blake Watters")];
    [expectThat(user.userID) should:be(123)];    
    [operation release];
}

- (void)itShouldBeAbleToMapAUserToADictionary {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];
    
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:user destinationObject:dictionary objectMapping:mapping];
    BOOL success = [operation performMapping:nil];
    [expectThat(success) should:be(YES)];
    [expectThat([dictionary valueForKey:@"name"]) should:be(@"Blake Watters")];
    [expectThat([dictionary valueForKey:@"id"]) should:be(123)];
    [operation release];
}

- (void)itShouldFailMappingWhenGivenASourceObjectThatContainsNoMappableKeys {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKExampleUser* user = [RKExampleUser user];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    [expectThat(success) should:be(NO)];
    [expectThat(error) shouldNot:be(nil)];
    [operation release];
}

- (void)itShouldInformTheDelegateOfAnErrorWhenMappingFailsBecauseThereIsNoMappableContent {
    // TODO: Pending, this spec is crashing at [mockDelegate verify];
    return;
    // TODO: WTF?
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKObjectMappingOperationDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKExampleUser* user = [RKExampleUser user];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    [[mockDelegate expect] objectMappingOperation:operation didFailWithError:[OCMArg isNotNil]];
    [mockDelegate verify];
    return;
//    [[mockDelegate expect] objectMappingOperation:operation didNotFindMappingForKeyPath:@"balls"];
//    [mockDelegate verify];
    operation.delegate = mockDelegate;
    [operation performMapping:nil];
    RKLOG_MAPPING(0, @"The delegate is.... %@", mockDelegate);
    [mockDelegate verify];
}

- (void)itShouldSetTheErrorWhenMappingOperationFails {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKExampleUser* user = [RKExampleUser user];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    [expectThat(error) shouldNot:be(nil)];
    [expectThat([error code]) should:be(RKObjectMapperErrorUnmappableContent)];
    [operation release];
}

// TODO: RKObjectMappingOperationDelegate specs

#pragma mark - Attribute Mapping

- (void)itShouldMapAStringToADateAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* birthDateMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter new] autorelease];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];    
    [expectThat([dateFormatter stringFromDate:user.birthDate]) should:be(@"11/27/1982")];
}

- (void)itShouldMapADateToAString {
    
}
// TODO: It should assume date strings with timestamps are in UTC time
// TODO: It should serialize dates by consulting the datePropertyAsString method (if available)
// TODO: It should serialize dates
// TODO: It should let you specify a format string for the date (maybe?)

- (void)itShouldMapStringToURL {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"website" toKeyPath:@"website"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat(user.website) shouldNot:be(nil)];
    [expectThat([user.website isKindOfClass:[NSURL class]]) should:be(YES)];
    [expectThat([user.website absoluteString]) should:be(@"http://restkit.org/")];
}

- (void)itShouldMapAStringToANumberBool {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat([[user isDeveloper] boolValue]) should:be(YES)]; 
}

- (void)itShouldMapAStringToANumber {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"luckyNumber"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat(user.luckyNumber) should:be(187)]; 
}

- (void)itShouldMapAStringToADecimalNumber {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"weight" toKeyPath:@"weight"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSDecimalNumber* weight = user.weight;
    [expectThat([weight isKindOfClass:[NSDecimalNumber class]]) should:be(YES)];
    [expectThat([weight compare:[NSDecimalNumber decimalNumberWithString:@"131.3"]]) should:be(NSOrderedSame)];
}

- (void)itShouldMapANestedKeyPathToAnAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"address.country" toKeyPath:@"country"];
    [mapping addAttributeMapping:countryMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat(user.country) should:be(@"USA")];
}

- (void)itShouldMapANestedArrayOfStringsToAnAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"interests" toKeyPath:@"interests"];
    [mapping addAttributeMapping:countryMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSArray* interests = [NSArray arrayWithObjects:@"Hacking", @"Running", nil];
    [expectThat(user.interests) should:be(interests)];
}

- (void)itShouldMapANestedDictionaryToAnAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"address" toKeyPath:@"addressDictionary"];
    [mapping addAttributeMapping:countryMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSDictionary* address = [NSDictionary dictionaryWithKeysAndObjects:
                             @"city", @"Carrboro",
                             @"state", @"North Carolina",
                             @"id", [NSNumber numberWithInt:1234],
                             @"country", @"USA", nil];
    [expectThat(user.addressDictionary) should:be(address)];
}

- (void)itShouldNotSetAPropertyWhenTheValueIsTheSame {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
}

- (void)itShouldNotSetTheDestinationPropertyWhenBothAreNil {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
}

- (void)itShouldSetNilForNSNullValues {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSDictionary* dictionary = RKSpecParseFixtureJSON(@"user.json");
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)itShouldOptionallySetNilForAMissingKeyPath {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixtureJSON(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetNilForMissingAttributes];
    NSError* error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)itShouldOptionallyIgnoreAMissingSourceKeyPath {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixtureJSON(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:nil];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user objectMapping:mapping];
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = NO;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetNilForMissingAttributes];
    NSError* error = nil;
    [operation performMapping:&error];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

// TODO: It should handle valueForUndefinedKey
// We can probably just copy the time zone to the mapper instance?

#pragma mark - Relationship Mapping

- (void)itShouldMapANestedObject {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping* addressMapping = [RKObjectMapping mappingForClass:[RKSpecAddress class]];
    RKObjectAttributeMapping* cityMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];
    
    RKObjectRelationshipMapping* hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" objectMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    [expectThat(success) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
    [expectThat(user.address) shouldNot:be(nil)];
}

- (void)itShouldMapANestedObjectCollection {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    
    RKObjectRelationshipMapping* hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" objectMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    [expectThat(success) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
    [expectThat(user.friends) shouldNot:be(nil)];
    [expectThat([user.friends count]) should:be(2)];
    NSArray* names = [NSArray arrayWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    [expectThat([user.friends valueForKey:@"name"]) should:be(names)];
}

- (void)itShouldMapANestedArrayIntoASet {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    
    RKObjectRelationshipMapping* hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friendsSet" objectMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    [expectThat(success) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
    [expectThat(user.friendsSet) shouldNot:be(nil)];
    [expectThat([user.friendsSet isKindOfClass:[NSSet class]]) should:be(YES)];
    [expectThat([user.friendsSet count]) should:be(2)];
    NSSet* names = [NSSet setWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    [expectThat([user.friendsSet valueForKey:@"name"]) should:be(names)];
}

- (void)itShouldNotSetThePropertyWhenTheNestedObjectIsIdentical {
    RKExampleUser* user = [RKExampleUser user];
    RKSpecAddress* address = [RKSpecAddress address];
    address.addressID = [NSNumber numberWithInt:1234];
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:OCMOCK_ANY];
    
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping* addressMapping = [RKObjectMapping mappingForClass:[RKSpecAddress class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];
    
    RKObjectRelationshipMapping* hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" objectMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
//    RKExampleUser* user = [RKExampleUser user];
    [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
}

- (void)itShouldNotSetThePropertyWhenTheNestedObjectCollectionIsIdentical {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:idMapping];
    [userMapping addAttributeMapping:nameMapping];
    
    RKObjectRelationshipMapping* hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" objectMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    
    // Set the friends up
    RKExampleUser* jeremy = [RKExampleUser user];
    jeremy.name = @"Jeremy Ellison";
    jeremy.userID = [NSNumber numberWithInt:187];
    RKExampleUser* rachit = [RKExampleUser user];
    rachit.name = @"Rachit Shukla"; 
    rachit.userID = [NSNumber numberWithInt:7];
    user.friends = [NSArray arrayWithObjects:jeremy, rachit, nil];
    
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setFriends:OCMOCK_ANY];
    [mapper mapFromObject:userInfo toObject:mockUser atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    [mockUser verify];
}

- (void)itShouldOptionallyNilOutTheRelationshipIfItIsMissing {
    RKExampleUser* user = [RKExampleUser user];
    RKSpecAddress* address = [RKSpecAddress address];
    address.addressID = [NSNumber numberWithInt:1234];
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setAddress:nil];
    
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping* addressMapping = [RKObjectMapping mappingForClass:[RKSpecAddress class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];
    RKObjectRelationshipMapping* relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" objectMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixtureJSON(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"address"];    
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetNilForMissingRelationships];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser objectMapping:mockMapping];
    
    NSError* error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)itShouldNotNilOutTheRelationshipIfItIsMissingAndCurrentlyNilOnTheTargetObject {
    RKExampleUser* user = [RKExampleUser user];
    user.address = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:nil];
    
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping* addressMapping = [RKObjectMapping mappingForClass:[RKSpecAddress class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];
    RKObjectRelationshipMapping* relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" objectMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixtureJSON(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"address"];    
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetNilForMissingRelationships];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser objectMapping:mockMapping];
    
    NSError* error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

#pragma mark - Unidentified Components

// TODO: Error keyPath. Needs a place to live just like the date format strings
// TODO: This probably lives outside of the mapper

- (void)itShouldParseErrorsOutOfThePayload {
    
}

#pragma mark - Core Data Integration

@end
