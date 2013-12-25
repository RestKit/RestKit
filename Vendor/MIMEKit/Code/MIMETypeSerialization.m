//
//  MIMETypeSerialization.m
//  MIMEKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright (c) 2009-2013 Blake Watters. All rights reserved.
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

#import "MIMETypeSerialization.h"
#import "MIMESerializing.h"
#import "MIMEURLEncodedSerialization.h"
#import "MIMEJSONSerialization.h"

@interface MIMETypeSerializationRegistration : NSObject

@property (nonatomic, strong) id MIMETypeStringOrRegularExpression;
@property (nonatomic, assign) Class<MIMESerializing> serializationClass;

- (id)initWithMIMEType:(id)MIMETypeStringOrRegularExpression serializationClass:(Class<MIMESerializing>)serializationClass;
- (BOOL)matchesMIMEType:(NSString *)MIMEType;
@end

@implementation MIMETypeSerializationRegistration

- (id)initWithMIMEType:(id)MIMETypeStringOrRegularExpression serializationClass:(Class<MIMESerializing>)serializationClass
{
    NSParameterAssert(MIMETypeStringOrRegularExpression);
    NSParameterAssert(serializationClass);
    NSAssert([MIMETypeStringOrRegularExpression isKindOfClass:[NSString class]]
             || [MIMETypeStringOrRegularExpression isKindOfClass:[NSRegularExpression class]],
             @"Can only register a serialization class for a MIME Type by string or regular expression.");
    
    self = [super init];
    if (self) {
        self.MIMETypeStringOrRegularExpression = MIMETypeStringOrRegularExpression;
        self.serializationClass = serializationClass;
    }
    
    return self;
}

- (BOOL)matchesMIMEType:(NSString *)MIMEType
{
    return MIMETypeInSet(MIMEType, [NSSet setWithObject:self.MIMETypeStringOrRegularExpression]);
}

- (NSString *)description
{
    NSString *mimeTypeDescription = [self.MIMETypeStringOrRegularExpression isKindOfClass:[NSRegularExpression class]] ?
    [NSString stringWithFormat:@"MIME Type =~ \"%@\"", self.MIMETypeStringOrRegularExpression] :
    [NSString stringWithFormat:@"MIME Type == \"%@\"", self.MIMETypeStringOrRegularExpression];
    return [NSString stringWithFormat:@"<%@: %p, %@, serializationClass=%@>",
            NSStringFromClass([self class]), self, mimeTypeDescription, NSStringFromClass(self.serializationClass)];
}

@end

@interface MIMETypeSerialization ()
@property (nonatomic, strong) NSMutableArray *registrations;
@end

@implementation MIMETypeSerialization

+ (MIMETypeSerialization *)sharedSerialization
{
    static MIMETypeSerialization *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MIMETypeSerialization alloc] init];
        [sharedInstance addRegistrationsForKnownSerializations];
    });
    return sharedInstance;

}

- (id)init
{
    self = [super init];
    if (self) {
        self.registrations = [NSMutableArray new];
    }
    
    return self;
}

- (void)addRegistrationsForKnownSerializations
{    
    // URL Encoded
    [self.registrations addObject:[[MIMETypeSerializationRegistration alloc] initWithMIMEType:MIMETypeFormURLEncoded
                                                                             serializationClass:[MIMEURLEncodedSerialization class]]];
    // JSON
    [self.registrations addObject:[[MIMETypeSerializationRegistration alloc] initWithMIMEType:MIMETypeJSON
                                                                             serializationClass:[MIMEJSONSerialization class]]];
}

#pragma mark - Public

+ (Class<MIMESerializing>)serializationClassForMIMEType:(NSString *)MIMEType
{
    for (MIMETypeSerializationRegistration *registration in [[self sharedSerialization].registrations reverseObjectEnumerator]) {
        if ([registration matchesMIMEType:MIMEType]) {
            return registration.serializationClass;
        }
    }
    return nil;
}

+ (void)registerClass:(Class<MIMESerializing>)serializationClass forMIMEType:(id)MIMETypeStringOrRegularExpression
{
    MIMETypeSerializationRegistration *registration = [[MIMETypeSerializationRegistration alloc] initWithMIMEType:MIMETypeStringOrRegularExpression serializationClass:serializationClass];
    [[self sharedSerialization].registrations addObject:registration];
}

+ (void)unregisterClass:(Class<MIMESerializing>)serializationClass
{
    NSArray *registrationsCopy = [[self sharedSerialization].registrations copy];
    for (MIMETypeSerializationRegistration *registration in registrationsCopy) {
        if (registration.serializationClass == serializationClass) {
            [[self sharedSerialization].registrations removeObject:registration];
        }
    }
}

+ (NSSet *)registeredMIMETypes
{
    return [NSSet setWithArray:[[self sharedSerialization].registrations valueForKey:@"MIMETypeStringOrRegularExpression"]];
}

+ (id)objectFromData:(NSData *)data MIMEType:(NSString *)MIMEType error:(NSError **)error
{
    NSParameterAssert(data);
    NSParameterAssert(MIMEType);

    Class<MIMESerializing> serializationClass = [self serializationClassForMIMEType:MIMEType];
    if (!serializationClass) {
        if (error) {
            NSString* errorMessage = [NSString stringWithFormat:@"Cannot deserialize data: No serialization registered for MIME Type '%@'", MIMEType];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage, MIMETypeErrorKey : MIMEType };
            *error = [NSError errorWithDomain:MIMEErrorDomain code:MIMEUnsupportedMIMETypeError userInfo:userInfo];
        }
        return nil;
    }
    
    return [serializationClass objectFromData:data error:error];
}

+ (id)dataFromObject:(id)object MIMEType:(NSString *)MIMEType error:(NSError **)error
{
    NSParameterAssert(object);
    NSParameterAssert(MIMEType);
    Class<MIMESerializing> serializationClass = [self serializationClassForMIMEType:MIMEType];
    if (!serializationClass) {
        if (error) {
            NSString* errorMessage = [NSString stringWithFormat:@"Cannot deserialize data: No serialization registered for MIME Type '%@'", MIMEType];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage, MIMETypeErrorKey : MIMEType };
            *error = [NSError errorWithDomain:MIMEErrorDomain code:MIMEUnsupportedMIMETypeError userInfo:userInfo];
        }
        return nil;
    }
    
    return [serializationClass dataFromObject:object error:error];
}

@end
