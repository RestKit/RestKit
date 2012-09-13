//
//  RKResponseMapperOperation.h
//  RestKit
//
//  Created by Blake Watters on 8/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RestKit.h"

// Abstract superclass. Provides parsing
@interface RKResponseMapperOperation : NSOperation

- (id)initWithResponse:(NSHTTPURLResponse *)response
                  data:(NSData *)data
    responseDescriptors:(NSArray *)responseDescriptors;

// Response
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, strong, readonly) NSData *data;

// Mapping configuration
@property (nonatomic, strong, readonly) NSArray *responseDescriptors;
@property (nonatomic, strong) id targetObject;
@property (nonatomic, weak) id<RKMappingOperationDataSource> mappingOperationDataSource; // Can be nil
@property (nonatomic, weak) id<RKObjectMapperDelegate> mapperDelegate;

// Results

/**
 A Boolean value that indicates if the receiver should consider empty
 responses as being successfully mapped even though no mapping is actually performed.

 When YES and the response data is empty (see below), a mapping result will be returned containing the
 target object (if any). Otherwise, the response data will be pass through to the parser which may generate
 an error.

 **Default:** YES

 @warning To support the Ruby on Rails behavior of rendering a single space character on invocation of
 `render :nothing => true`, a response body's containing only a single space is treated as empty.
 */
@property (nonatomic, assign) BOOL treatsEmptyResponseAsSuccess;

/**
 Returns a dictionary of key path to RKMapping objects that are applicable to mapping
 the given response. This is determined by evaluating the URL and status codes of the response.

 @see RKMappingDescriptor
 */
@property (nonatomic, strong, readonly) NSDictionary *responseMappingsDictionary;
@property (nonatomic, strong, readonly) RKMappingResult *mappingResult;
@property (nonatomic, strong, readonly) NSError *error;

@end

@interface RKObjectResponseMapperOperation : RKResponseMapperOperation
@end

@interface RKManagedObjectResponseMapperOperation : RKResponseMapperOperation

///-----------------------------------------------------------------------------
/// @name Core Data
///-----------------------------------------------------------------------------

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id<RKManagedObjectCaching> managedObjectCache;
@property (nonatomic, copy) NSManagedObjectID *targetObjectID; // Overrides the value set for targetObject

@end
