//
//  RKObjectMapperSpec.m
//  RestKit
//
//  Created by Jeremy Ellison on 12/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectMapper.h"
#import "RKMappableObject.h"
#import "RKMappableAssociation.h"
#import "RKObjectMapperSpecModel.h"
#import "RKObject.h"
#import "NSDictionary+RKAdditions.h"

@interface RKObjectMapper (Private)
- (void)updateModel:(id)model ifNewPropertyValue:(id)propertyValue forPropertyNamed:(NSString*)propertyName;
@end

@interface RKObjectMapperSpecUser : RKObject {
@private
    NSNumber* userID;
    NSString* encryptedPassword;
    NSString* name;
    NSString* salt;
    NSDate* createdAt;
    NSDate* updatedAt;
    NSString* image;
    NSString* email;
}

@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSString* encryptedPassword;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* salt;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, retain) NSDate* updatedAt;
@property (nonatomic, retain) NSString* image;
@property (nonatomic, retain) NSString* email;

@end

@implementation RKObjectMapperSpecUser

@synthesize userID, encryptedPassword, name, salt, createdAt, updatedAt, image, email;

+ (NSDictionary*)elementToPropertyMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:
            @"id", @"userID",
            @"encrypted_password", @"encryptedPassword",
            @"name", @"name",
            @"salt", @"salt",
            @"created_at", @"createdAt",
            @"updated_at", @"updatedAt",
            @"image", @"image",
            @"email", @"email",
            nil];
}

@end

@interface RKObjectMapperSpec : NSObject <UISpec>

- (NSString*)jsonString;
- (NSString*)jsonCollectionString;

@end

@implementation RKObjectMapperSpec

- (NSString*)userJSON {
    return @"{\"user\":"
           @"{\"encrypted_password\":\"68dad82a867c4a61719fec594c119188ed35cd3b7d42eed1647e46d85f2ffdd8\",\"name\":\"mimi\","
           @"\"salt\":\"809c79c24cbebfe3f9feea2e9bf98255e5af0f0b8514b6c0d71dcc63fa083688\",\"created_at\":\"2011-02-16T23:04:22Z\","
           @"\"updated_at\":\"2011-02-16T23:04:22Z\",\"id\":"
           @"10,\"image\":null,\"email\":\"mimi@mimi.com\"}}";
}

- (void)itShouldMapWhenGivenAClassAndElements {
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
    RKObjectMapperSpecUser* user = (RKObjectMapperSpecUser*) [mapper mapFromString:[self userJSON] toClass:[RKObjectMapperSpecUser class] keyPath:@"user"];
    [expectThat(user.name) should:be(@"mimi")];
}

- (void)itShouldMapWhenGivenRegisteredElementsAndASingleObject {
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
    [mapper registerClass:[RKObjectMapperSpecUser class] forElementNamed:@"user"];
	mapper.format = RKMappingFormatJSON;
    RKObjectMapperSpecUser* user = (RKObjectMapperSpecUser*) [mapper mapFromString:[self userJSON] toClass:nil keyPath:nil];
    [expectThat(user.name) should:be(@"mimi")];
}

- (void)itShouldMapFromJSON {
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	id result = [mapper mapFromString:[self jsonString]];
	
	[expectThat(result) shouldNot:be(nil)];
	[expectThat([result dateTest]) shouldNot:be(nil)];
	[expectThat([result numberTest]) should:be(2)];
	[expectThat([result stringTest]) should:be(@"SomeString")];
	
	[expectThat([result hasOne]) shouldNot:be(nil)];
	[expectThat([[result hasOne] testString]) should:be(@"A String")];
	
	[expectThat([result hasMany]) shouldNot:be(nil)];
	[expectThat([[result hasMany] count]) should:be(2)];
}

- (void)itShouldMapObjectsFromJSON {
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	NSString* collectionString = [self jsonCollectionString];
	NSArray* results = [mapper mapFromString:collectionString];
	NSLog(@"Results: %@", results);
	[expectThat([results count]) should:be(2)];
	
	RKMappableObject* result = (RKMappableObject*) [results objectAtIndex:0];
	[expectThat(result) shouldNot:be(nil)];
	[expectThat([result dateTest]) shouldNot:be(nil)];
	[expectThat([result numberTest]) should:be(2)];
	[expectThat([result stringTest]) should:be(@"SomeString")];
	
	[expectThat([result hasOne]) shouldNot:be(nil)];
	[expectThat([[result hasOne] testString]) should:be(@"A String")];
	
	[expectThat([result hasMany]) shouldNot:be(nil)];
	[expectThat([[result hasMany] count]) should:be(2)];
}

- (NSString*)arrayOfHashesJSON {
    return @"{\"user\":"
    @"[{\"encrypted_password\":\"68dad82a867c4a61719fec594c119188ed35cd3b7d42eed1647e46d85f2ffdd8\",\"name\":\"mimi\","
    @"\"salt\":\"809c79c24cbebfe3f9feea2e9bf98255e5af0f0b8514b6c0d71dcc63fa083688\",\"created_at\":\"2011-02-16T23:04:22Z\","
    @"\"updated_at\":\"2011-02-16T23:04:22Z\",\"id\":"
    @"10,\"image\":null,\"email\":\"mimi@mimi.com\"}]}";
}

- (void)itShouldMapAnArrayOfHashes {
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
    [mapper registerClass:[RKObjectMapperSpecUser class] forElementNamed:@"user"];
    NSArray* array = [mapper mapFromString:[self arrayOfHashesJSON]];
    [expectThat([array isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([array count]) should:be(1)];
    [expectThat([[array lastObject] name]) should:be(@"mimi")];
}

// NOTE: email attribute is omitted!
- (NSString*)userJSONMissingAnElement {
    return @"{\"user\":"
    @"{\"encrypted_password\":\"68dad82a867c4a61719fec594c119188ed35cd3b7d42eed1647e46d85f2ffdd8\",\"name\":\"mimi\","
    @"\"salt\":\"809c79c24cbebfe3f9feea2e9bf98255e5af0f0b8514b6c0d71dcc63fa083688\",\"created_at\":\"2011-02-16T23:04:22Z\","
    @"\"updated_at\":\"2011-02-16T23:04:22Z\",\"id\":"
    @"10,\"image\":null}}";
}

- (void)itShouldNotCrashWhenAttemptingToMapWithAMissingElement {
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
    mapper.missingElementMappingPolicy = RKSetNilForMissingElementMappingPolicy;
	mapper.format = RKMappingFormatJSON;
    [mapper registerClass:[RKObjectMapperSpecUser class] forElementNamed:@"user"];
    
    NSException* exception = nil;
    @try {
        [mapper mapFromString:[self userJSONMissingAnElement]];
    }
    @catch (NSException * e) {
        exception = e;
    }
    [expectThat(exception) should:be(nil)];
}

- (void)itShouldNotNilOutWhenAttemptingToMapWithAMissingElementIfConfiguredNotTo {
    RKObjectMapperSpecUser* user = [RKObjectMapperSpecUser object];
    user.email = @"foo@bar.com";
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
    mapper.missingElementMappingPolicy = RKIgnoreMissingElementMappingPolicy;
	mapper.format = RKMappingFormatJSON;
    [mapper registerClass:[RKObjectMapperSpecUser class] forElementNamed:@"user"];
    
    [mapper mapObject:user fromString:[self userJSONMissingAnElement]];
    [expectThat(user.email) should:be(@"foo@bar.com")];
}

- (void)itShouldNilOutWhenAttemptingToMapWithAMissingElementIfConfiguredToDoSo {
    RKObjectMapperSpecUser* user = [RKObjectMapperSpecUser object];
    user.email = @"foo@bar.com";
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
    mapper.missingElementMappingPolicy = RKSetNilForMissingElementMappingPolicy;
	mapper.format = RKMappingFormatJSON;
    [mapper registerClass:[RKObjectMapperSpecUser class] forElementNamed:@"user"];
    
    [mapper mapObject:user fromString:[self userJSONMissingAnElement]];
    [expectThat(user.email) should:be(nil)];
}

- (void)itShouldMapAnArrayOfStringsToAProperty {
/*
 'tags' =>
 array (
 'url' => 'http://localhost/~David/gallery3/rest/item_tags/1?
 output=html',
 'members' =>
 array (
 0 => 'http://localhost/~David/gallery3/rest/tag_item/379,1?
 output=html',
 1 => 'http://localhost/~David/gallery3/rest/tag_item/380,1?
 output=html',
 2 => 'http://localhost/~David/gallery3/rest/tag_item/381,1?
 output=html',
 ),
 )
*/
    // TODO: IMPLEMENT ME
}

// TODO: re-implement these specs when we re-implement xml parsing.
//- (void)itShouldMapFromXML {
//	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
//	mapper.format = RKMappingFormatXML;
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
//	id result = [mapper mapFromString:[self xmlString]];
//	
//	[expectThat(result) shouldNot:be(nil)];
//	[expectThat([result dateTest]) shouldNot:be(nil)];
//	[expectThat([result numberTest]) should:be(2)];
//	[expectThat([result stringTest]) should:be(@"SomeString")];
//	
//	[expectThat([result hasOne]) shouldNot:be(nil)];
//	[expectThat([[result hasOne] testString]) should:be(@"A String")];
//	
//	[expectThat([result hasMany]) shouldNot:be(nil)];
//	[expectThat([[result hasMany] count]) should:be(2)];
//}
//
//- (void)itShouldMapObjectsFromXML {
//	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
//	mapper.format = RKMappingFormatXML;
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
//	NSArray* results = [mapper mapFromString:[self xmlCollectionString]];
//	[expectThat([results count]) should:be(2)];
//	
//	RKMappableObject* result = (RKMappableObject*) [results objectAtIndex:0];
//	[expectThat(result) shouldNot:be(nil)];
//	[expectThat([result dateTest]) shouldNot:be(nil)];
//	[expectThat([result numberTest]) should:be(2)];
//	[expectThat([result stringTest]) should:be(@"SomeString")];
//	
//	[expectThat([result hasOne]) shouldNot:be(nil)];
//	[expectThat([[result hasOne] testString]) should:be(@"A String")];
//	
//	[expectThat([result hasMany]) shouldNot:be(nil)];
//	[expectThat([[result hasMany] count]) should:be(2)];
//}

- (void)itShouldNotUpdateNilPropertyToNil {
	RKObjectMapperSpecModel* model = [[[RKObjectMapperSpecModel alloc] init] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	[mapper updateModel:model ifNewPropertyValue:nil forPropertyNamed:@"name"];
	
	[expectThat(model.name) should:be(nil)];
}

- (void)itShouldBeAbleToSetNonNilPropertiesToNil {
	RKObjectMapperSpecModel* model = [[[RKObjectMapperSpecModel alloc] init] autorelease];
	model.age = [NSNumber numberWithInt:0];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	[mapper updateModel:model ifNewPropertyValue:nil forPropertyNamed:@"age"];
	
	[expectThat(model.age) should:be(nil)];
}

- (void)itShouldBeAbleToSetNilPropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[[RKObjectMapperSpecModel alloc] init] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	[mapper updateModel:model ifNewPropertyValue:[NSNumber numberWithInt:0] forPropertyNamed:@"age"];
	
	[expectThat(model.age) should:be([NSNumber numberWithInt:0])];
}

- (void)itShouldBeAbleToSetNonNilNSStringPropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[[RKObjectMapperSpecModel alloc] init] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	
	model.name = @"Bob";
	[mapper updateModel:model ifNewPropertyValue:@"Will" forPropertyNamed:@"name"];
	[expectThat(model.name) should:be(@"Will")];	
}

- (void)itShouldBeAbleToSetNonNilNSNumberPropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[[RKObjectMapperSpecModel alloc] init] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	
	model.age = [NSNumber numberWithInt:16];
	[mapper updateModel:model ifNewPropertyValue:[NSNumber numberWithInt:17] forPropertyNamed:@"age"];
	[expectThat(model.age) should:be(17)];	
}

- (void)itShouldBeAbleToSetNonNilNSDatePropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[[RKObjectMapperSpecModel alloc] init] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	
	model.createdAt = [NSDate date];
	[mapper updateModel:model ifNewPropertyValue:[NSDate dateWithTimeIntervalSince1970:0] forPropertyNamed:@"createdAt"];
	[expectThat(model.createdAt) should:be([NSDate dateWithTimeIntervalSince1970:0])];	
}

- (NSString*)jsonString {
	return
	@"{"
	@"   \"test_serialization_class\":{"
	@"      \"date_test\":\"2009-08-17T19:24:40Z\","
	@"      \"number_test\":2,"
	@"      \"string_test\":\"SomeString\","
	@"      \"has_one\":{"
	@"         \"test_string\":\"A String\""
	@"      },"
	@"      \"has_manys\":["
	@"         {"
	@"            \"has_many\":{"
	@"               \"test_string\":\"A String 2\""
	@"            }"
	@"         },"
	@"         {"
	@"            \"has_many\":{"
	@"               \"test_string\":\"A String 3\""
	@"            }"
	@"         }"
	@"      ]"
	@"   }"
	@"}";
}

- (NSString*)jsonCollectionString {
	return
	@"["
	@"      {"
	@"         \"test_serialization_class\":{"
	@"            \"date_test\":\"2009-08-17T19:24:40Z\","
	@"            \"number_test\":2,"
	@"            \"string_test\":\"SomeString\","
	@"            \"has_one\":{"
	@"               \"test_string\":\"A String\""
	@"            },"
	@"            \"has_manys\":["
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 2\""
	@"                  }"
	@"               },"
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 3\""
	@"                  }"
	@"               }"
	@"            ]"
	@"         }"
	@"      },"
	@"      {"
	@"         \"test_serialization_class\":{"
	@"            \"date_test\":\"2009-08-17T19:24:40Z\","
	@"            \"number_test\":2,"
	@"            \"string_test\":\"SomeString\","
	@"            \"has_one\":{"
	@"               \"test_string\":\"A String\""
	@"            },"
	@"            \"has_manys\":["
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 2\""
	@"                  }"
	@"               },"
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 3\""
	@"                  }"
	@"               }"
	@"            ]"
	@"         }"
	@"      }"
	@"]"
	@"";
}

- (NSString*)xmlString {
	NSString* xml = @"<test_serialization_class>"
	@"<date_test type='datetime'>2009-08-17T19:24:40Z</date_test>"
	@"<number_test type='integer'>2</number_test>"
	@"<string_test>SomeString</string_test>"
	@"<has_one>"
	@"<test_string>A String</test_string>"
	@"</has_one>"
	@"<has_manys>"
	@"<has_many>"
	@"<test_string>A String 2</test_string>"
	@"</has_many>"
	@"<has_many>"
	@"<test_string>A String 3</test_string>"
	@"</has_many>"
	@"</has_manys>"
	@"</test_serialization_class>";
	return xml;
}

- (NSString*)xmlCollectionString {
	NSString* xml = @"<test_serialization_classes>"
	@"<test_serialization_class>"
	@"<date_test type='datetime'>2009-08-17T19:24:40Z</date_test>"
	@"<number_test type='integer'>2</number_test>"
	@"<string_test>SomeString</string_test>"
	@"<has_one>"
	@"<test_string>A String</test_string>"
	@"</has_one>"
	@"<has_manys>"
	@"<has_many>"
	@"<test_string>A String 2</test_string>"
	@"</has_many>"
	@"<has_many>"
	@"<test_string>A String 3</test_string>"
	@"</has_many>"
	@"</has_manys>"
	@"</test_serialization_class>"
	@"<test_serialization_class>"
	@"<date_test type='datetime'>2009-08-17T19:24:40Z</date_test>"
	@"<number_test type='integer'>2</number_test>"
	@"<string_test>SomeString</string_test>"
	@"<has_one>"
	@"<test_string>A String</test_string>"
	@"</has_one>"
	@"<has_manys>"
	@"<has_many>"
	@"<test_string>A String 2</test_string>"
	@"</has_many>"
	@"<has_many>"
	@"<test_string>A String 3</test_string>"
	@"</has_many>"
	@"</has_manys>"
	@"</test_serialization_class>"
	@"</test_serialization_classes>";
	return xml;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////

// This class is a thin model around
@interface RKPath : RKObject {
@private
    NSNumber* _label;
    NSArray*  _route; // An array of hashes
}

@property (nonatomic, retain) NSNumber* label;
@property (nonatomic, retain) NSArray* route;
@end

@implementation RKPath

@synthesize label = _label;
@synthesize route = _route;

+ (NSDictionary*)elementToPropertyMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:            
            @"label", @"label",
            @"route", @"route",
            nil];
}

@end

@interface RKModeledPath : RKObject {
@private
    NSNumber* _label;
    NSArray*  _route; // An array of RKPoint objects
}

@property (nonatomic, retain) NSNumber* label;
@property (nonatomic, retain) NSArray* route;
@end

@implementation RKModeledPath

@synthesize label = _label;
@synthesize route = _route;

+ (NSDictionary*)elementToPropertyMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:            
            @"label", @"label",
            nil];
}

+ (NSDictionary*)elementToRelationshipMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:
            @"route", @"route",
            nil];
}

@end

@interface RKPoint : RKObject {
    NSNumber* _latitude;
    NSNumber* _longitude;    
}

@property (nonatomic, retain) NSNumber* latitude;
@property (nonatomic, retain) NSNumber* longitude;

@end


@implementation RKPoint

@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

+ (NSDictionary*) elementToPropertyMappings {    
    return [NSDictionary dictionaryWithKeysAndObjects:            
            @"LATITUDE", @"latitude",            
            @"LONGITUDE", @"longitude",            
            nil];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKPoint : latitude = %@, longitude = %@", self.latitude, self.longitude];
}

@end

@interface RKObjectMapperRegisteredClassWithArraySpec : NSObject <UISpec> {
@private
}
@end

@implementation RKObjectMapperRegisteredClassWithArraySpec

- (NSString*)JSON {
    // TODO: Should create a JSON factory that can read these from a fixtures directory where we can format them nicely.
    return @"[{\"route\":[{\"LATITUDE\":\"32.224519\",\"LONGITUDE\":\"-110.947325\"},{\"LATITUDE\":\"32.224542\",\"LONGITUDE\":\"-110.943861\"},{\"LATITUDE\":\"32.221431\",\"LONGITUDE\":\"-110.943930\"}],\"label\":7174},{\"route\":[{\"LATITUDE\":\"32.224519\",\"LONGITUDE\":\"-110.947325\"},{\"LATITUDE\":\"32.221402\",\"LONGITUDE\":\"-110.947293\"},{\"LATITUDE\":\"32.221431\",\"LONGITUDE\":\"-110.943930\"}],\"label\":7079},{\"route\":[{\"LATITUDE\":\"32.224519\",\"LONGITUDE\":\"-110.947325\"},{\"LATITUDE\":\"32.227820\",\"LONGITUDE\":\"-110.947293\"},{\"LATITUDE\":\"32.227843\",\"LONGITUDE\":\"-110.943865\"},{\"LATITUDE\":\"32.227879\",\"LONGITUDE\":\"-110.939531\"},{\"LATITUDE\":\"32.224599\",\"LONGITUDE\":\"-110.939495\"},{\"LATITUDE\":\"32.221476\",\"LONGITUDE\":\"-110.939496\"},{\"LATITUDE\":\"32.221431\",\"LONGITUDE\":\"-110.943930\"}],\"label\":23775}]";
}

- (void)itShouldMapAnArrayOfRoutes {
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
    
    NSArray* array = (NSArray*) [mapper mapFromString:[self JSON] toClass:[RKPath class] keyPath:nil];
    [expectThat([array isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([array count]) should:be(3)];
    NSLog(@"Array is %@", array);
    NSLog(@"First object is: %@", [array objectAtIndex:0]);
    NSLog(@"Route on first object is: %@", [[array objectAtIndex:0] route]);
}

- (void)itShouldMapRouteToAnArrayOfPoints {
    RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
    [mapper registerClass:[RKPoint class] forElementNamed:@"route"];
    
    NSArray* array = (NSArray*) [mapper mapFromString:[self JSON] toClass:[RKModeledPath class] keyPath:nil];
    [expectThat([array isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([array count]) should:be(3)];
    NSLog(@"[Modeled] Array is %@", array);
    NSLog(@"[Modeled] First object is: %@", [array objectAtIndex:0]);
    NSLog(@"[Modeled] Route on first object is: %@", [[array objectAtIndex:0] route]);
}

@end
