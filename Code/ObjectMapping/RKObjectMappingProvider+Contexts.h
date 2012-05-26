//
//  RKObjectMappingProvider.m
//  RestKit
//
//  Created by Blake Watters on 1/17/12.
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

#import "RKObjectMappingProvider.h"

// Contexts provide primitives for managing collections of object mappings namespaced
// within a single mapping provider. This enables easy reuse and extension via categories.
@interface RKObjectMappingProvider (Contexts)

- (void)initializeContext:(RKObjectMappingProviderContext)context withValue:(id)value;
- (id)valueForContext:(RKObjectMappingProviderContext)context;
- (void)setValue:(id)value forContext:(RKObjectMappingProviderContext)context;

- (RKObjectMappingDefinition *)mappingForContext:(RKObjectMappingProviderContext)context;
/**
 Stores a single object mapping for a given context. Useful when a component needs to enable
 configuration via one (and only one) object mapping.
 */
- (void)setMapping:(RKObjectMappingDefinition *)mapping context:(RKObjectMappingProviderContext)context;
- (NSArray *)mappingsForContext:(RKObjectMappingProviderContext)context;
- (void)addMapping:(RKObjectMappingDefinition *)mapping context:(RKObjectMappingProviderContext)context;
- (void)removeMapping:(RKObjectMappingDefinition *)mapping context:(RKObjectMappingProviderContext)context;
- (RKObjectMappingDefinition *)mappingForKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context;
- (void)setMapping:(RKObjectMappingDefinition *)mapping forKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context;
- (void)removeMappingForKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context;

- (void)setMapping:(RKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern atIndex:(NSUInteger)index context:(RKObjectMappingProviderContext)context;
- (void)setMapping:(RKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern context:(RKObjectMappingProviderContext)context;
- (RKObjectMappingDefinition *)mappingForPatternMatchingString:(NSString *)string context:(RKObjectMappingProviderContext)context;
- (void)setEntry:(RKObjectMappingProviderContextEntry *)entry forPattern:(NSString *)pattern context:(RKObjectMappingProviderContext)context;
- (RKObjectMappingProviderContextEntry *)entryForPatternMatchingString:(NSString *)string context:(RKObjectMappingProviderContext)context;

@end
