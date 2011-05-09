//
//  RKObjectSerializerSpec.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/9/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectSerializer.h"

@interface RKObjectSerializerSpec : NSObject <UISpec> {
}

@end

@implementation RKObjectSerializerSpec

- (void)itShouldSerializeShitToFormEncodedData {
    NSDictionary* object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError* error = nil;
    id<RKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];
    NSString* data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    // TODO: it probably isn't guarenteed to come back in this order, but it seems to every time...
    [expectThat(error) should:be(nil)];
    [expectThat(data) should:be(@"key2-form-name=value2&key1-form-name=value1")];
}

- (void)itShouldSerializeADateToFormEncodedData {
    NSDictionary* object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError* error = nil;
    id<RKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];
    NSString* data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    // TODO: it probably isn't guarenteed to come back in this order, but it seems to every time...
    [expectThat(error) should:be(nil)];
    [expectThat(data) should:be(@"key2-form-name=value2&key1-form-name=value1")];
}

- (void)itShouldSerializeADateToJSON {
    
}

- (void)itShouldSerializeRelationshipsToo {
    NSDictionary* object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2",
                            [NSArray arrayWithObjects:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"relationship1Value1", @"relatioship1Key1", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"relationship1Value2", @"relatioship1Key1", nil], nil], @"relationship1",
                            [NSDictionary dictionaryWithObjectsAndKeys:@"subValue1", @"subKey1", nil], @"relationship2",
                            nil];
    RKObjectMapping* relationship1Mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [relationship1Mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"relationship1Key1" toKeyPath:@"r1k1-form-name"]];
     
     RKObjectMapping* relationship2Mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
     [relationship2Mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"subKey1" toKeyPath:@"subKey1-form-name"]]; 
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    [mapping addRelationshipMapping:[RKObjectRelationshipMapping mappingFromKeyPath:@"relationship1" toKeyPath:@"relationship1-form-name" objectMapping:relationship1Mapping]];
    [mapping addRelationshipMapping:[RKObjectRelationshipMapping mappingFromKeyPath:@"relationship2" toKeyPath:@"relationship2-form-name" objectMapping:relationship2Mapping]];
    
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError* error = nil;
    id<RKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/x-www-form-urlencoded" error:&error];
    NSString* data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    
    [expectThat(error) should:be(nil)];
    [expectThat(data) should:be(@"key2-form-name=value2&key1-form-name=value1&blahblahblah")];
}

- (void)itShouldSerializeToJSON {
    NSDictionary* object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:mapping];
    NSError* error = nil;
    id<RKRequestSerializable> serialization = [serializer serializationForMIMEType:@"application/json" error:&error];
    NSString* data = [[[NSString alloc] initWithData:[serialization HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
    // TODO: it probably isn't guarenteed to come back in this order, but it seems to every time...
    [expectThat(error) should:be(nil)];
    [expectThat(data) should:be(@"{\"key2-form-name\":\"value2\",\"key1-form-name\":\"value1\"}")];
}

- (void)itShouldSetAnErrorAndReturnNilIfItCantSerialize {
//    [expectThat(error) shouldNot:be(nil)];
//    [expectThat(data) should:be(nil)];
}


@end
