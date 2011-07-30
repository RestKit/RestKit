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
#import "RKObjectMapping.h"
#import "RKObjectMappingOperation.h"
#import "RKObjectAttributeMapping.h"
#import "RKObjectRelationshipMapping.h"
#import "RKLog.h"
#import "RKObjectMapper.h"
#import "RKObjectMapper_Private.h"
#import "RKObjectMapperError.h"
#import "RKPolymorphicMappingModels.h"

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

- (id)valueForUndefinedKey:(NSString *)key {
    RKLogError(@"Unexpectedly asked for undefined key '%@'", key);
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    RKLogError(@"Asked to set value '%@' for undefined key '%@'", value, key);
    [super setValue:value forUndefinedKey:key];
}

@end

////////////////////////////////////////////////////////////////////////////////

#pragma mark -

@interface RKObjectMappingNextGenSpec : RKSpec {
    
}

@end

@implementation RKObjectMappingNextGenSpec

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
    assertThat([mapping mappingForKeyPath:@"id"], is(sameInstance(idMapping)));
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
    RKObjectRelationshipMapping* idMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"id" toKeyPath:@"userID" withMapping:nil];
    [mapping addRelationshipMapping:idMapping];
    [expectThat([mapping.mappings containsObject:idMapping]) should:be(YES)];
    [expectThat([mapping.relationshipMappings containsObject:idMapping]) should:be(YES)];
}

- (void)itShouldGenerateAttributeMappings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    assertThat([mapping mappingForKeyPath:@"name"], is(nilValue()));
    [mapping mapKeyPath:@"name" toAttribute:@"name"];
    assertThat([mapping mappingForKeyPath:@"name"], isNot(nilValue()));
}

- (void)itShouldGenerateRelationshipMappings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMapping* anotherMapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    assertThat([mapping mappingForKeyPath:@"another"], is(nilValue()));
    [mapping mapRelationship:@"another" withMapping:anotherMapping];
    assertThat([mapping mappingForKeyPath:@"another"], isNot(nilValue()));
}

- (void)itShouldRemoveMappings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat(mapping.mappings, hasItem(idMapping));
    [mapping removeMapping:idMapping];
    assertThat(mapping.mappings, isNot(hasItem(idMapping)));
}

- (void)itShouldRemoveMappingsByKeyPath {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat(mapping.mappings, hasItem(idMapping));
    [mapping removeMappingForKeyPath:@"id"];
    assertThat(mapping.mappings, isNot(hasItem(idMapping)));
}

- (void)itShouldRemoveAllMappings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    [mapping mapAttributes:@"one", @"two", @"three", nil];
    assertThat(mapping.mappings, hasCountOf(3));
    [mapping removeAllMappings];
    assertThat(mapping.mappings, is(empty()));
}

- (void)itShouldGenerateAnInverseMappings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];    
    [mapping mapKeyPath:@"first_name" toAttribute:@"firstName"];
    [mapping mapAttributes:@"city", @"state", @"zip", nil];
    RKObjectMapping* otherMapping = [RKObjectMapping mappingForClass:[RKSpecAddress class]];
    [otherMapping mapAttributes:@"street", nil];
    [mapping mapRelationship:@"address" withMapping:otherMapping];
    RKObjectMapping* inverse = [mapping inverseMapping];
    assertThat(inverse.objectClass, is(equalTo([NSMutableDictionary class])));
    assertThat([inverse mappingForKeyPath:@"firstName"], isNot(nilValue()));
}

- (void)itShouldLetYouRetrieveMappingsByAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* attributeMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"nameAttribute"];
    [mapping addAttributeMapping:attributeMapping];
    assertThat([mapping mappingForAttribute:@"nameAttribute"], is(equalTo(attributeMapping)));
}

- (void)itShouldLetYouRetrieveMappingsByRelationship {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectRelationshipMapping* relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friend" toKeyPath:@"friendRelationship" withMapping:mapping];
    [mapping addRelationshipMapping:relationshipMapping];
    assertThat([mapping mappingForRelationship:@"friendRelationship"], is(equalTo(relationshipMapping)));
}

#pragma mark - RKObjectMapper Specs

- (void)itShouldPerformBasicMapping {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixture(@"user.json");
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
    id userInfo = RKSpecParseFixture(@"users.json");
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
        
    id userInfo = RKSpecParseFixture(@"user.json");
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
    
    id userInfo = RKSpecParseFixture(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [NSDictionary new];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
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
    
    id userInfo = RKSpecParseFixture(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    RKExampleUser* user = [RKExampleUser user];
    mapper.targetObject = user;
    RKObjectMappingResult* result = [mapper performMapping];
    
    [mockProvider verify];
    [expectThat(result) shouldNot:be(nil)];
    [expectThat([result asObject] == user) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldCreateANewInstanceOfTheAppropriateDestinationObjectWhenThereIsNoTargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixture(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    id mappingResult = [[mapper performMapping] asObject];
    [expectThat([mappingResult isKindOfClass:[RKExampleUser class]]) should:be(YES)];
}

- (void)itShouldDetermineTheMappingClassForAKeyPathByConsultingTheMappingProviderWhenMappingADictionaryWithoutATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];        
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    [[mockProvider expect] mappingsByKeyPath];
        
    id userInfo = RKSpecParseFixture(@"user.json");
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
    
    id userInfo = RKSpecParseFixture(@"user.json");
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
    
    id userInfo = RKSpecParseFixture(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult* result = [mapper performMapping];
    NSArray* users = [result asCollection];
    [expectThat([users isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([users count]) should:be(3)];
    RKExampleUser* user = [users objectAtIndex:0];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldMapACollectionOfObjectsWithDynamicKeys {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    mapping.forceCollectionMapping = YES;
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];    
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"(name).id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];
    
    id userInfo = RKSpecParseFixture(@"DynamicKeys.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult* result = [mapper performMapping];
    NSArray* users = [result asCollection];
    [expectThat([users isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([users count]) should:be(2)];
    RKExampleUser* user = [users objectAtIndex:0];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"blake")];
    user = [users objectAtIndex:1];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"rachit")];
}

- (void)itShouldMapACollectionOfObjectsWithDynamicKeysAndRelationships {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    mapping.forceCollectionMapping = YES;
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    
    RKObjectMapping* addressMapping = [RKObjectMapping mappingForClass:[RKSpecAddress class]];
    [addressMapping mapAttributes:@"city", @"state", nil];
    [mapping mapKeyPath:@"(name).address" toRelationship:@"address" withMapping:addressMapping];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];
    
    id userInfo = RKSpecParseFixture(@"DynamicKeysWithRelationship.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult* result = [mapper performMapping];
    NSArray* users = [result asCollection];
    [expectThat([users isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([users count]) should:be(2)];
    RKExampleUser* user = [users objectAtIndex:0];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"blake")];
    user = [users objectAtIndex:1];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"rachit")];
    [expectThat(user.address) shouldNot:be(nil)];
    [expectThat(user.address.city) should:be(@"New York")];
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
    
    id userInfo = RKSpecParseFixture(@"nested_user.json");
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
    
    id userInfo = RKSpecParseFixture(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = [RKExampleUser user];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
    [expectThat([[mapper.errors objectAtIndex:0] code]) should:be(RKObjectMapperErrorObjectMappingTypeMismatch)];
}

- (void)itShouldAddAnErrorWhenAttemptingToMapADictionaryWithoutAnObjectMapping {
    id userInfo = RKSpecParseFixture(@"user.json");
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
    [expectThat([[mapper.errors objectAtIndex:0] localizedDescription]) should:be(@"Could not find an object mapping for keyPath: ''")];
}

- (void)itShouldAddAnErrorWhenAttemptingToMapACollectionWithoutAnObjectMapping {
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    id userInfo = RKSpecParseFixture(@"users.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
    [expectThat([[mapper.errors objectAtIndex:0] localizedDescription]) should:be(@"Could not find an object mapping for keyPath: ''")];
}

#pragma mark RKObjectMapperDelegate Specs

- (void)itShouldInformTheDelegateWhenMappingBegins {
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixture(@"users.json");
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
    
    id userInfo = RKSpecParseFixture(@"users.json");
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
    
    id userInfo = RKSpecParseFixture(@"user.json");
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
    
    id userInfo = RKSpecParseFixture(@"user.json");
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
    
    id userInfo = RKSpecParseFixture(@"users.json");
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
    
    id userInfo = RKSpecParseFixture(@"user.json");
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
    
    id userInfo = RKSpecParseFixture(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didMapFromObject:userInfo toObject:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (BOOL)fakeValidateValue:(inout id *)ioValue forKey:(NSString *)inKey error:(out NSError **)outError {
    *outError = [NSError errorWithDomain:RKRestKitErrorDomain code:1234 userInfo:nil];
    return NO;
}

- (void)itShouldNotifyTheDelegateWhenItFailedToMapAnObject {    
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:NSClassFromString(@"OCPartialMockObject")];
    [mapping mapAttributes:@"name", nil];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    
    id userInfo = RKSpecParseFixture(@"user.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKExampleUser* exampleUser = [[RKExampleUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:exampleUser];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKey:error:) onObject:self] validateValue:[OCMArg anyPointer] forKey:OCMOCK_ANY error:[OCMArg anyPointer]];
    mapper.targetObject = mockObject;
    [[mockDelegate expect] objectMapper:mapper didFailMappingFromObject:userInfo toObject:[OCMArg any] withError:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockObject verify];
    [mockDelegate verify];
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
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    [operation performMapping:nil];    
    [expectThat(user.name) should:be(@"Blake Watters")];
    [expectThat(user.userID) should:be(123)];    
    [operation release];
}

- (void)itShouldConsiderADictionaryContainingOnlyNullValuesForKeysMappable {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"name", nil];
    RKExampleUser* user = [RKExampleUser user];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(nilValue()));
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
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:user destinationObject:dictionary mapping:mapping];
    BOOL success = [operation performMapping:nil];
    [expectThat(success) should:be(YES)];
    [expectThat([dictionary valueForKey:@"name"]) should:be(@"Blake Watters")];
    [expectThat([dictionary valueForKey:@"id"]) should:be(123)];
    [operation release];
}

- (void)itShouldReturnNoWithoutErrorWhenGivenASourceObjectThatContainsNoMappableKeys {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKExampleUser* user = [RKExampleUser user];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    [expectThat(success) should:be(NO)];
    [expectThat(error) should:be(nil)];
    [operation release];
}

- (void)itShouldInformTheDelegateOfAnErrorWhenMappingFailsBecauseThereIsNoMappableContent {
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMappingOperationDelegate)];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKExampleUser* user = [RKExampleUser user];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    BOOL success = [operation performMapping:nil];
    [expectThat(success) should:be(NO)];
    [mockDelegate verify];
}

- (void)itShouldSetTheErrorWhenMappingOperationFails {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"id", nil];
    RKExampleUser* user = [RKExampleUser user];
    id mockObject = [OCMockObject partialMockForObject:user];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKey:error:) onObject:self] validateValue:[OCMArg anyPointer] forKey:OCMOCK_ANY error:[OCMArg anyPointer]];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockObject mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    [expectThat(error) shouldNot:be(nil)];
    [operation release];
}

#pragma mark - Attribute Mapping

- (void)itShouldMapAStringToADateAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* birthDateMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter new] autorelease];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];    
    [expectThat([dateFormatter stringFromDate:user.birthDate]) should:be(@"11/27/1982")];
}

- (void)itShouldMapStringToURL {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"website" toKeyPath:@"website"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
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
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat([[user isDeveloper] boolValue]) should:be(YES)]; 
}

- (void)itShouldMapAShortTrueStringToANumberBool {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    RKExampleUser* user = [RKExampleUser user];
    [dictionary setValue:@"T" forKey:@"is_developer"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat([[user isDeveloper] boolValue]) should:be(YES)]; 
}

- (void)itShouldMapAShortFalseStringToANumberBool {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    RKExampleUser* user = [RKExampleUser user];
    [dictionary setValue:@"f" forKey:@"is_developer"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat([[user isDeveloper] boolValue]) should:be(NO)]; 
}

- (void)itShouldMapAYesStringToANumberBool {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    RKExampleUser* user = [RKExampleUser user];
    [dictionary setValue:@"yes" forKey:@"is_developer"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat([[user isDeveloper] boolValue]) should:be(YES)]; 
}

- (void)itShouldMapANoStringToANumberBool {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    RKExampleUser* user = [RKExampleUser user];
    [dictionary setValue:@"NO" forKey:@"is_developer"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat([[user isDeveloper] boolValue]) should:be(NO)]; 
}

- (void)itShouldMapAStringToANumber {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"luckyNumber"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat(user.luckyNumber) should:be(187)]; 
}

- (void)itShouldMapAStringToADecimalNumber {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"weight" toKeyPath:@"weight"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSDecimalNumber* weight = user.weight;
    [expectThat([weight isKindOfClass:[NSDecimalNumber class]]) should:be(YES)];
    [expectThat([weight compare:[NSDecimalNumber decimalNumberWithString:@"131.3"]]) should:be(NSOrderedSame)];
}


- (void)itShouldMapANumberToAString {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"name"];
    [mapping addAttributeMapping:websiteMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat(user.name) should:be(@"187")]; 
}

- (void)itShouldMapANumberToADate {
    NSDateFormatter* dateFormatter = [[NSDateFormatter new] autorelease];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate* date = [dateFormatter dateFromString:@"11/27/1982"];
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* birthDateMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"dateAsNumber" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    [dictionary setValue:[NSNumber numberWithInt:[date timeIntervalSince1970]] forKey:@"dateAsNumber"];
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat([dateFormatter stringFromDate:user.birthDate]) should:be(@"11/27/1982")];
}

- (void)itShouldMapANestedKeyPathToAnAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"address.country" toKeyPath:@"country"];
    [mapping addAttributeMapping:countryMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    [expectThat(user.country) should:be(@"USA")];
}

- (void)itShouldMapANestedArrayOfStringsToAnAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"interests" toKeyPath:@"interests"];
    [mapping addAttributeMapping:countryMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSArray* interests = [NSArray arrayWithObjects:@"Hacking", @"Running", nil];
    assertThat(user.interests, is(equalTo(interests)));
}

- (void)itShouldMapANestedDictionaryToAnAttribute {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"address" toKeyPath:@"addressDictionary"];
    [mapping addAttributeMapping:countryMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    
    NSDictionary* address = [NSDictionary dictionaryWithKeysAndObjects:
                             @"city", @"Carrboro",
                             @"state", @"North Carolina",
                             @"id", [NSNumber numberWithInt:1234],
                             @"country", @"USA", nil];
    assertThat(user.addressDictionary, is(equalTo(address)));
}

- (void)itShouldNotSetAPropertyWhenTheValueIsTheSame {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSDictionary* dictionary = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
}

- (void)itShouldNotSetTheDestinationPropertyWhenBothAreNil {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
}

- (void)itShouldSetNilForNSNullValues {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError* error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)itShouldOptionallySetDefaultValueForAMissingKeyPath {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetDefaultValueForMissingAttributes];
    NSError* error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)itShouldOptionallyIgnoreAMissingSourceKeyPath {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKExampleUser* user = [RKExampleUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:nil];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = NO;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetDefaultValueForMissingAttributes];
    NSError* error = nil;
    [operation performMapping:&error];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

#pragma mark - Relationship Mapping

- (void)itShouldMapANestedObject {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping* addressMapping = [RKObjectMapping mappingForClass:[RKSpecAddress class]];
    RKObjectAttributeMapping* cityMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];
    
    RKObjectRelationshipMapping* hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixture(@"user.json");
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
    
    RKObjectRelationshipMapping* hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    [expectThat(success) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
    [expectThat(user.friends) shouldNot:be(nil)];
    [expectThat([user.friends count]) should:be(2)];
    NSArray* names = [NSArray arrayWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    assertThat([user.friends valueForKey:@"name"], is(equalTo(names)));
}

- (void)itShouldMapANestedArrayIntoASet {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    
    RKObjectRelationshipMapping* hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friendsSet" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixture(@"user.json");
    RKExampleUser* user = [RKExampleUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    [expectThat(success) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
    [expectThat(user.friendsSet) shouldNot:be(nil)];
    [expectThat([user.friendsSet isKindOfClass:[NSSet class]]) should:be(YES)];
    [expectThat([user.friendsSet count]) should:be(2)];
    NSSet* names = [NSSet setWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    assertThat([user.friendsSet valueForKey:@"name"], is(equalTo(names)));
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
    
    RKObjectRelationshipMapping* hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixture(@"user.json");
    [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
}

- (void)itShouldNotSetThePropertyWhenTheNestedObjectCollectionIsIdentical {
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectAttributeMapping* idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    RKObjectAttributeMapping* nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:idMapping];
    [userMapping addAttributeMapping:nameMapping];
    
    RKObjectRelationshipMapping* hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];
    
    RKObjectMapper* mapper = [RKObjectMapper new];
    id userInfo = RKSpecParseFixture(@"user.json");
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
    RKObjectRelationshipMapping* relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"address"];    
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];
    
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
    RKObjectRelationshipMapping* relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];
    
    NSMutableDictionary* dictionary = [RKSpecParseFixture(@"user.json") mutableCopy];
    [dictionary removeObjectForKey:@"address"];    
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];
    
    NSError* error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

#pragma mark - RKObjectMappingProvider

- (void)itShouldRegisterRailsIdiomaticObjects {    
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    [mapping mapAttributes:@"name", @"website", nil];
    [mapping mapKeyPath:@"id" toAttribute:@"userID"];
    
    [objectManager.router routeClass:[RKExampleUser class] toResourcePath:@"/humans/(userID)"];
    [objectManager.router routeClass:[RKExampleUser class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
    
    RKExampleUser* user = [RKExampleUser new];
    user.userID = [NSNumber numberWithInt:1];
    
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    loader.timeout = 5;
    [objectManager getObject:user delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    
    [objectManager postObject:user delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"My Name")));
    assertThat(user.website, is(equalTo([NSURL URLWithString:@"http://restkit.org/"])));
}

- (void)itShouldReturnAllMappingsForAClass {
    RKObjectMapping* firstMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMapping* secondMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMapping* thirdMapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectMappingProvider* mappingProvider = [[RKObjectMappingProvider new] autorelease];
    [mappingProvider addObjectMapping:firstMapping];
    [mappingProvider addObjectMapping:secondMapping];
    [mappingProvider setMapping:thirdMapping forKeyPath:@"third"];
    assertThat([mappingProvider objectMappingsForClass:[RKExampleUser class]], is(equalTo([NSArray arrayWithObjects:firstMapping, secondMapping, thirdMapping, nil])));
}

#pragma mark - RKObjectPolymorphicMapping

- (void)itShouldMapASingleObjectDynamically {
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    dynamicMapping.delegateBlock = ^ RKObjectMapping* (id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return girlMapping;
        }
        
        return nil;
    };
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixture(@"boy.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy* user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)itShouldMapASingleObjectDynamicallyWithADeclarativeMatcher {
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKey:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKey:@"type" isEqualTo:@"Girl"];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixture(@"boy.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy* user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)itShouldACollectionOfObjectsPolymorphically {
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKey:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKey:@"type" isEqualTo:@"Girl"];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixture(@"mixed.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    NSArray* objects = [[mapper performMapping] asCollection];
    assertThat(objects, hasCountOf(2));
    assertThat([objects objectAtIndex:0], is(instanceOf([Boy class])));
    assertThat([objects objectAtIndex:1], is(instanceOf([Girl class])));
    Boy* boy = [objects objectAtIndex:0];
    Girl* girl = [objects objectAtIndex:1];
    assertThat(boy.name, is(equalTo(@"Blake Watters")));
    assertThat(girl.name, is(equalTo(@"Sarah")));
}

- (void)itShouldMapAPolymorphicRelationship {
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKey:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKey:@"type" isEqualTo:@"Girl"];
    [boyMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixture(@"friends.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy* blake = [[mapper performMapping] asObject];
    NSArray* friends = blake.friends;
    
    assertThat(friends, hasCountOf(2));
    assertThat([friends objectAtIndex:0], is(instanceOf([Boy class])));
    assertThat([friends objectAtIndex:1], is(instanceOf([Girl class])));
    Boy* boy = [friends objectAtIndex:0];
    Girl* girl = [friends objectAtIndex:1];
    assertThat(boy.name, is(equalTo(@"John Doe")));
    assertThat(girl.name, is(equalTo(@"Jane Doe")));
}

- (void)itShouldBeAbleToDeclineMappingAnObjectByReturningANilObjectMapping {
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    dynamicMapping.delegateBlock = ^ RKObjectMapping* (id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }
        
        return nil;
    };
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixture(@"mixed.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    NSArray* boys = [[mapper performMapping] asCollection];
    assertThat(boys, hasCountOf(1));
    Boy* user = [boys objectAtIndex:0];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)itShouldBeAbleToDeclineMappingObjectsInARelationshipByReturningANilObjectMapping {
    RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKObjectPolymorphicMapping* dynamicMapping = [RKObjectPolymorphicMapping polymorphicMapping];
    dynamicMapping.delegateBlock = ^ RKObjectMapping* (id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }
        
        return nil;
    };
    [boyMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    
    id userInfo = RKSpecParseFixture(@"friends.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy* blake = [[mapper performMapping] asObject];
    assertThat(blake, is(notNilValue()));
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
    assertThat(blake, is(instanceOf([Boy class])));
    NSArray* friends = blake.friends;
    
    assertThat(friends, hasCountOf(1));
    assertThat([friends objectAtIndex:0], is(instanceOf([Boy class])));
    Boy* boy = [friends objectAtIndex:0];
    assertThat(boy.name, is(equalTo(@"John Doe")));
}

@end
