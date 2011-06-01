//
//  RKObjectMapperError.h
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../Support/Errors.h"

typedef enum RKObjectMapperErrors {
    RKObjectMapperErrorObjectMappingNotFound,       // No mapping found
    RKObjectMapperErrorObjectMappingTypeMismatch,   // Target class and object mapping are in disagreement
    RKObjectMapperErrorUnmappableContent,           // No mappable attributes or relationships were found
    RKObjectMapperErrorFromMappingResult
} RKObjectMapperErrorCode;
