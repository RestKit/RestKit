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

@interface RKObjectConnectionMapping : NSObject

@property (nonatomic, retain, readonly) NSString * sourceKeyPath;
@property (nonatomic, retain, readonly) NSString * destinationKeyPath;
@property (nonatomic, retain, readonly) RKObjectMappingDefinition * mapping;
@property (nonatomic, retain, readonly) RKDynamicObjectMappingMatcher* matcher;

+ (RKObjectConnectionMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping;
+ (RKObjectConnectionMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath matcher:(RKDynamicObjectMappingMatcher *)matcher withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping;
- (id)initFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath matcher:(RKDynamicObjectMappingMatcher *)matcher withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping;

- (id)findConnected:(NSString *)relationshipName source:(NSManagedObject *)source;
@end
