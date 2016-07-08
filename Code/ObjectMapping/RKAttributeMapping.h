//
//  RKAttributeMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import "RKPropertyMapping.h"

/**
 Instances of `RKAttributeMapping` define a transformation of data between an attribute value on source object and an attribute value on a destination object within an object mapping.
 */
@interface RKAttributeMapping : RKPropertyMapping

/**
 Creates and returns a new attribute mapping specifying that data is to be read from a given key path on a source object
 and set to a given key path on a destination object.

 Attribute mappings define transformation between key paths in the source and destination object beings mapped. In the simplest
 case, an attribute mapping may simply specify that data from one object is to be copied to another. A common example of this
 type of transformation is copying the `name` key from a JSON payload onto a local object. In this case, the source and
 destination key paths are identical, as are the source and destination types (`NSString`), so a simple get and set operation
 has been defined.

 The next most common use-case is the transformation of identical data between two different key paths in the
 source and destination objects. This is typically encountered when you wish to transform inbound data to conform with the naming
 conventions of the platform or the data model of your application. An example of this type of transformation would be from the
 source key path of `first_name` to the destination key path of `firstName`. In this transformation, the key paths have diverged
 but both sides of the mapping correspond to NSString properties.

 The final type of transformation to be specified via an attribute mapping involves the transformation between types in the mapping.
 By far, the most common example of this use-case is the transformation of a inbound string or numeric property into a date on
 the target object. For example, consider a backend system that returns the creation date of a piece of content in a JSON payload.
 This data might be returned in JSON as `{"created_on": "2012-08-27"}`. In a given application, the developer may wish to model this
 data as an NSDate `createdOn` property on the target object. An attribute mapping to support this mapping would specify a source
 key path of `created_on` and a destination key path of `createdOn`. On the destination object, the `createdOn` property would be defined
 as `@property (nonatomic, strong) NSDate *createdOn;`. At mapping time, the mapping operation inspects the type of the content being
 mapped and attempts to transform the source content into the type of the desination property specified by the mapping. In this case,
 an NSDateFormatter object would be used to process the inbound `NSString` into an outbound `NSDate` object.

 @param sourceKeyPath The key path on the source object from which to read the data being mapped. If `nil`, then the entire source object representation is mapped to the specified destination attribute.
 @param destinationKeyPath The key path on the destination object on which to set the mapped data.
 @return A newly created attribute mapping object that is ready to be added to an object mapping.
 */
+ (instancetype)attributeMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath;

@end
