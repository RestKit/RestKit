//
//  RKObjectSerializer.m
//  RestKit
//
//  Created by Blake Watters on 5/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKRequestSerialization.h"
#import "RKMIMETypes.h"
#import "RKParser.h"
#import "RKObjectSerializer.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKParserRegistry.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitObjectMapping

@interface RKObjectSerializer ()
@property (nonatomic, readwrite, strong) id object;
@property (nonatomic, readwrite, strong) RKObjectMapping *mapping;
@property (nonatomic, readwrite, strong) NSString *rootKeyPath;
@end

@implementation RKObjectSerializer

- (id)initWithObject:(id)object mapping:(RKObjectMapping *)mapping rootKeyPath:(NSString *)rootKeyPath;
{
    self = [super init];
    if (self) {
        self.object = object;
        self.mapping = mapping;
        self.rootKeyPath = rootKeyPath;
    }
    return self;
}

- (id)serializeObjectToDictionary:(NSError **)error
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    RKMappingOperation *operation = [RKMappingOperation mappingOperationFromObject:self.object toObject:dictionary withMapping:self.mapping];
    operation.delegate = self;
    BOOL success = [operation performMapping:error];
    if (!success) {
        return nil;
    }

    // Optionally enclose the serialized object within a container...
    return self.rootKeyPath ? [NSMutableDictionary dictionaryWithObject:dictionary forKey:self.rootKeyPath] : dictionary;
}

- (id)serializeObjectToMIMEType:(NSString *)MIMEType error:(NSError **)error
{
    // TODO: This will fail for form encoded...
    id serializedObject = [self serializeObjectToDictionary:error];
    if (serializedObject) {
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
        NSString *string = [parser stringFromObject:serializedObject error:error];
        if (string == nil) {
            return nil;
        }

        return string;
    }

    return nil;
}

- (id<RKRequestSerializable>)serializationForMIMEType:(NSString *)MIMEType error:(NSError **)error
{
    if ([MIMEType isEqualToString:RKMIMETypeFormURLEncoded]) {
        // Dictionaries are natively RKRequestSerializable as Form Encoded
        return [self serializeObjectToDictionary:error];
    } else {
        NSString *string = [self serializeObjectToMIMEType:MIMEType error:error];
        if (string) {
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            return [RKRequestSerialization serializationWithData:data MIMEType:MIMEType];
        }
    }

    return nil;
}

#pragma mark - RKObjectMappingOperationDelegate

- (void)mappingOperation:(RKMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping
{
    id transformedValue = nil;
    Class orderedSetClass = NSClassFromString(@"NSOrderedSet");

    if ([value isKindOfClass:[NSDate class]]) {
        // Date's are not natively serializable, must be encoded as a string
        @synchronized(self.mapping.preferredDateFormatter) {
            transformedValue = [self.mapping.preferredDateFormatter stringForObjectValue:value];
        }
    } else if ([value isKindOfClass:[NSDecimalNumber class]]) {
        // Precision numbers are serialized as strings to work around Javascript notation limits
        transformedValue = [(NSDecimalNumber *)value stringValue];
    } else if ([value isKindOfClass:orderedSetClass]) {
        // NSOrderedSets are not natively serializable, so let's just turn it into an NSArray
        transformedValue = [value array];
    }

    if (transformedValue) {
        RKLogDebug(@"Serialized %@ value at keyPath to %@ (%@)", NSStringFromClass([value class]), NSStringFromClass([transformedValue class]), value);
        [operation.destinationObject setValue:transformedValue forKey:keyPath];
    }
}

@end
