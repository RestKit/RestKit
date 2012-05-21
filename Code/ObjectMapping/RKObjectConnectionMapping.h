//
//  RKObjectConnectionMapping.h
//  RestKit
//
//  Created by Charlie Savage on 5/15/12.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKObjectMappingDefinition.h"

@class RKObjectConnectionMapping;
@class RKDynamicObjectMappingMatcher;

typedef id(^RKObjectConnectionBlock)(RKObjectConnectionMapping * mapping, id source);

// Defines the rules for connecting relationsips
@interface RKObjectConnectionMapping : NSObject

@property (nonatomic, retain, readonly) NSString * relationshipName;
@property (nonatomic, retain, readonly) NSString * sourceKeyPath;
@property (nonatomic, retain, readonly) NSString * destinationKeyPath;
@property (nonatomic, retain, readonly) RKObjectMappingDefinition * mapping;
@property (nonatomic, retain, readonly) RKDynamicObjectMappingMatcher* matcher;

/**
 Defines a mapping that is used to connect a source object relationship to
 the appropriate target object(s).

 @param relationshipName The name of the relationship on the source object.
 @param sourceKeyPath Specifies the path to an attribute on the source object that
 contains the value that should be used to connect the relationship.  This will generally
 be a primary key or a foreign key value.
 @param targetKeyPath Specifies the path to an attribute on the target object(s) that
 must match the value of the sourceKeyPath attribute.
 @param withMapping The mapping for the target object.

 @return A new instance of a RKObjectConnectionMapping.
 */
+ (RKObjectConnectionMapping*)mapping:(NSString *)relationshipName fromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping;

/**
 Defines a mapping that is used to connect a source object relationship to
 the appropriate target object(s).  This is similar to mapping:fromKeyPath:toKeyPath:withMapping:
 (@see mapping:fromKeyPath:toKeyPath:withMapping:) but adds in an additional matcher parameter
 that can be used to filter source objects.

 @return A new instance of a RKObjectConnectionMapping.
 */
+ (RKObjectConnectionMapping*)mapping:(NSString *)relationshipName fromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath matcher:(RKDynamicObjectMappingMatcher *)matcher withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping;

- (id)init:(NSString *)relationshipName fromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath matcher:(RKDynamicObjectMappingMatcher *)matcher withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping;

/**
 Finds the connected objects for this relationship mapping.

 @return A single object, a set of 0 or more objects or nil.
 */
- (id)findConnected:(NSManagedObject *)source;
@end
