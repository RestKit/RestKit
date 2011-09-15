//
//  RKObjectMapper_Private.h
//  RestKit
//
//  Created by Blake Watters on 5/9/11.
//  Copyright 2011 Two Toasters
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

@interface RKObjectMapper (Private)

- (id)mapObject:(id)mappableObject atKeyPath:keyPath usingMapping:(id<RKObjectMappingDefinition>)mapping;
- (NSArray*)mapCollection:(NSArray*)mappableObjects atKeyPath:(NSString*)keyPath usingMapping:(id<RKObjectMappingDefinition>)mapping;
- (BOOL)mapFromObject:(id)mappableObject toObject:(id)destinationObject atKeyPath:keyPath usingMapping:(id<RKObjectMappingDefinition>)mapping;
- (id)objectWithMapping:(id<RKObjectMappingDefinition>)objectMapping andData:(id)mappableData;

@end
