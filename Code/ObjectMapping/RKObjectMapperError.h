//
//  RKObjectMapperError.h
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../Support/Errors.h"

typedef enum RKObjectMapperErrors {
    RKObjectMapperErrorObjectMappingNotFound        = 1001,     // No mapping found
    RKObjectMapperErrorObjectMappingTypeMismatch    = 1002,     // Target class and object mapping are in disagreement
    RKObjectMapperErrorUnmappableContent            = 1003,     // No mappable attributes or relationships were found
    RKObjectMapperErrorFromMappingResult            = 1004,     // The error was returned from the mapping result
    RKObjectMapperErrorValidationFailure            = 1005      // Generic error code for use when constructing validation errors
} RKObjectMapperErrorCode;
