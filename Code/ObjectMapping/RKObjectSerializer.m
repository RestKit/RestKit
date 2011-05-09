//
//  RKObjectSerializer.m
//  RestKit
//
//  Created by Blake Watters on 5/2/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectSerializer.h"
#import "RKObjectMappingOperation.h"
#import "RKJSONSerialization.h"

@implementation RKObjectSerializer

+ (id)serializerWithObject:(id)object mapping:(RKObjectMapping*)mapping {
    return [[[self alloc] initWithObject:object mapping:mapping] autorelease];
}

- (id)initWithObject:(id)object mapping:(RKObjectMapping*)mapping {
    if ((self = [super init])) {
        _object = [object retain];
        _mapping = [mapping retain];
    }
    return self;
}

- (void)dealloc {
    [_object release];
    [_mapping release];
    [super dealloc];
}

- (id)serializationForMIMEType:(NSString*)mimeType error:(NSError**)error {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:_object toObject:dictionary withObjectMapping:_mapping];
    [operation performMapping:error];
    if ([mimeType isEqualToString:@"application/json"]) {
        return [RKJSONSerialization JSONSerializationWithObject:dictionary];
    } else if ([mimeType isEqualToString:@"application/x-www-form-urlencoded"]) {
        return dictionary;
    }
    return nil;
}


@end
