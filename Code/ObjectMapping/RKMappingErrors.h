//
//  RKMappingErrors.h
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
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

#import "RKErrors.h"

typedef UInt32 RKMappingErrorCode;
enum {
    RKMappingErrorNotFound                     = 1001,     // No mapping found
    RKMappingErrorTypeMismatch                 = 1002,     // Target class and object mapping are in disagreement
    RKMappingErrorUnmappableRepresentation     = 1003,     // No values were found at the key paths of any attribute or relationship mappings in the given representation
    RKMappingErrorFromMappingResult            = 1004,     // The error was returned from the mapping result
    RKMappingErrorValidationFailure            = 1005,     // Generic error code for use when constructing validation errors
    RKMappingErrorUnableToDetermineMapping     = 1006,     // The mapping operation was unable to obtain a concrete object mapping from a given dynamic mapping
    RKMappingErrorNilDestinationObject         = 1007,     // The mapping operation failed due to a nil destination object.
    RKMappingErrorNilManagedObjectCache        = 1008,     // A managed object cache is required to satisfy the mapping, but none was given.
    RKMappingErrorMappingDeclined              = 1009,     // Mapping was declined by a callback.
    RKMappingErrorInvalidAssignmentPolicy      = 1010,     // The assignment policy for the relationship is invalid.
};

extern NSString * const RKMappingErrorKeyPathErrorKey; // The key path the error is associated with
