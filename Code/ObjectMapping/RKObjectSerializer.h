//
//  RKObjectSerializer.h
//  RestKit
//
//  Created by Blake Watters on 5/2/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"
#import "RKObjectMappingOperation.h"
#import "../Network/RKRequestSerializable.h"

/**
 Performs a serialization of an object and its relationships back into
 a dictionary representation according to the mappings specified. The
 transformed object is then enclosed in an RKRequestSerializable representation
 that is suitable for inclusion in an RKRequest.
 */
@interface RKObjectSerializer : NSObject <RKObjectMappingOperationDelegate, RKObjectFactory> {
    id _object;
    RKObjectMapping* _mapping;
}

@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) RKObjectMapping* mapping;

+ (id)serializerWithObject:(id)object mapping:(RKObjectMapping*)mapping;
- (id)initWithObject:(id)object mapping:(RKObjectMapping*)mapping;
- (id<RKRequestSerializable>)serializationForMIMEType:(NSString*)mimeType error:(NSError**)error;

@end
