//
//  RKObjectSerializer.h
//  RestKit
//
//  Created by Blake Watters on 5/2/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectMapping.h"

/*!
 Performs a serialization of an object and its relationships back into
 a dictionary representation. This i
 */
@interface RKObjectSerializer : NSObject {
    id _object;
    RKObjectMapping* _mapping;
}

+ (id)serializerWithObject:(id)object mapping:(RKObjectMapping*)mapping;
- (id)initWithObject:(id)object mapping:(RKObjectMapping*)mapping;

- (id)serializationForMIMEType:(NSString*)mimeType error:(NSError**)error;

@end
