//
//  RKObjectSerializer.m
//  RestKit
//
//  Created by Blake Watters on 5/2/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../Network/RKRequestSerialization.h"
#import "../Support/RKMIMETypes.h"
#import "../Support/RKParser.h"
#import "RKObjectSerializer.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKParserRegistry.h"

@implementation RKObjectSerializer

@synthesize object = _object;
@synthesize mapping = _mapping;

+ (id)serializerWithObject:(id)object mapping:(RKObjectMapping*)mapping {
    return [[[self alloc] initWithObject:object mapping:mapping] autorelease];
}

- (id)initWithObject:(id)object mapping:(RKObjectMapping*)mapping {
    self = [super init];
    if (self) {
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

- (id<RKRequestSerializable>)serializationForMIMEType:(NSString*)MIMEType error:(NSError**)error {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:_object toObject:dictionary withObjectMapping:_mapping];
    operation.delegate = self;
    operation.objectFactory = self;
    BOOL success = [operation performMapping:error];
    if (!success) {
        return nil;
    }
    
    // Optionally enclose the serialized object within a container...
    if (_mapping.rootKeyPath) {
        // TODO: Should log this...
        dictionary = [NSMutableDictionary dictionaryWithObject:dictionary forKey:_mapping.rootKeyPath];
    }
    
    if ([MIMEType isEqualToString:RKMIMETypeFormURLEncoded]) {
        // Dictionaries are natively RKRequestSerializable as Form Encoded
        return dictionary;
    } else {
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
        NSString* string = [parser stringFromObject:dictionary error:error];
        if (string == nil) {
            return nil;
        }
        
        NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
        return [RKRequestSerialization serializationWithData:data MIMEType:MIMEType];
    }
    
    return nil;
}

#pragma mark - RKObjectMappingOperationDelegate

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping *)mapping {
    
    // Date's are not natively serializable, must be encoded as a string
    if ([value isKindOfClass:[NSDate class]]) {
        // TODO: Log transformation from NSDate to string...
        NSString* dateAsString = [value description];
        [operation.destinationObject setValue:dateAsString forKey:keyPath];
    }
}

#pragma mark - RKObjectFactory

// We always serialize back to a dictionary
- (id)objectWithMapping:(RKObjectMapping*)objectMapping andData:(id)mappableData {
    return [NSMutableDictionary dictionary];
}

@end
