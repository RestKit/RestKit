//
//  RKMIMETypeSerialization.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
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

#import "RKMIMETypeSerialization.h"
#import "RKErrors.h"
#import "RKSerialization.h"
#import "RKLog.h"
#import "RKURLEncodedSerialization.h"
#import "RKNSJSONSerialization.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitSupport

@interface RKMIMETypeSerializationRegistration : NSObject

@property (nonatomic, strong) id MIMETypeStringOrRegularExpression;
@property (nonatomic, assign) Class<RKSerialization> serializationClass;

- (instancetype)initWithMIMEType:(id)MIMETypeStringOrRegularExpression serializationClass:(Class<RKSerialization>)serializationClass NS_DESIGNATED_INITIALIZER;
- (BOOL)matchesMIMEType:(NSString *)MIMEType;
@end

@implementation RKMIMETypeSerializationRegistration

- (instancetype)initWithMIMEType:(id)MIMETypeStringOrRegularExpression serializationClass:(Class<RKSerialization>)serializationClass
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
    return RKMIMETypeInSet(MIMEType, [NSSet setWithObject:self.MIMETypeStringOrRegularExpression]);
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

@interface RKMIMETypeSerialization ()
@property (nonatomic, strong) NSMutableArray *registrations;
@end

@implementation RKMIMETypeSerialization

+ (RKMIMETypeSerialization *)sharedSerialization
{
    static RKMIMETypeSerialization *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RKMIMETypeSerialization alloc] init];
        [sharedInstance addRegistrationsForKnownSerializations];
    });
    return sharedInstance;

}

- (instancetype)init
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
    [self.registrations addObject:[[RKMIMETypeSerializationRegistration alloc] initWithMIMEType:RKMIMETypeFormURLEncoded
                                                                             serializationClass:[RKURLEncodedSerialization class]]];
    // JSON
    [self.registrations addObject:[[RKMIMETypeSerializationRegistration alloc] initWithMIMEType:RKMIMETypeJSON
                                                                             serializationClass:[RKNSJSONSerialization class]]];
}

#pragma mark - Public

+ (Class<RKSerialization>)serializationClassForMIMEType:(NSString *)MIMEType
{
    for (RKMIMETypeSerializationRegistration *registration in [[self sharedSerialization].registrations reverseObjectEnumerator]) {
        if ([registration matchesMIMEType:MIMEType]) {
            return registration.serializationClass;
        }
    }
    return nil;
}

+ (void)registerClass:(Class<RKSerialization>)serializationClass forMIMEType:(id)MIMETypeStringOrRegularExpression
{
    RKMIMETypeSerializationRegistration *registration = [[RKMIMETypeSerializationRegistration alloc] initWithMIMEType:MIMETypeStringOrRegularExpression serializationClass:serializationClass];
    [[self sharedSerialization].registrations addObject:registration];
}

+ (void)unregisterClass:(Class<RKSerialization>)serializationClass
{
    NSArray *registrationsCopy = [[self sharedSerialization].registrations copy];
    for (RKMIMETypeSerializationRegistration *registration in registrationsCopy) {
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

    Class<RKSerialization> serializationClass = [self serializationClassForMIMEType:MIMEType];
    if (!serializationClass) {
        if (error) {
            NSString* errorMessage = [NSString stringWithFormat:@"Cannot deserialize data: No serialization registered for MIME Type '%@'", MIMEType];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage, RKMIMETypeErrorKey : MIMEType };
            *error = [NSError errorWithDomain:RKErrorDomain code:RKUnsupportedMIMETypeError userInfo:userInfo];
        }
        return nil;
    }
    
    return [serializationClass objectFromData:data error:error];
}

+ (id)dataFromObject:(id)object MIMEType:(NSString *)MIMEType error:(NSError **)error
{
    NSParameterAssert(object);
    NSParameterAssert(MIMEType);
    Class<RKSerialization> serializationClass = [self serializationClassForMIMEType:MIMEType];
    if (!serializationClass) {
        if (error) {
            NSString* errorMessage = [NSString stringWithFormat:@"Cannot deserialize data: No serialization registered for MIME Type '%@'", MIMEType];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage, RKMIMETypeErrorKey : MIMEType };
            *error = [NSError errorWithDomain:RKErrorDomain code:RKUnsupportedMIMETypeError userInfo:userInfo];
        }
        return nil;
    }
    
    return [serializationClass dataFromObject:object error:error];
}

@end
