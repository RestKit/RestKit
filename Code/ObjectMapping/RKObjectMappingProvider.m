//
//  RKObjectMappingProvider.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 RestKit
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
#import "RKObjectMappingProvider+Contexts.h"
#import "RKOrderedDictionary.h"
#import "RKPathMatcher.h"

@implementation RKObjectMappingProvider

+ (RKObjectMappingProvider *)mappingProvider {
    return [[self new] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        mappingContexts = [NSMutableDictionary new];
        [self initializeContext:RKObjectMappingProviderContextObjectsByKeyPath withValue:[NSMutableDictionary dictionary]];
        [self initializeContext:RKObjectMappingProviderContextObjectsByType withValue:[NSMutableArray array]];
        [self initializeContext:RKObjectMappingProviderContextObjectsByResourcePathPattern withValue:[RKOrderedDictionary dictionary]];
        [self initializeContext:RKObjectMappingProviderContextSerialization withValue:[NSMutableDictionary dictionary]];
        [self initializeContext:RKObjectMappingProviderContextErrors withValue:[NSNull null]];
    }
    return self;
}

- (void)dealloc {
    [mappingContexts release];
    [super dealloc];
}

- (void)setObjectMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping forKeyPath:(NSString *)keyPath {
    [self setMapping:objectOrDynamicMapping forKeyPath:keyPath context:RKObjectMappingProviderContextObjectsByKeyPath];
}

- (void)removeObjectMappingForKeyPath:(NSString *)keyPath {
    [self removeMappingForKeyPath:keyPath context:RKObjectMappingProviderContextObjectsByKeyPath];
}

- (id<RKObjectMappingDefinition>)objectMappingForKeyPath:(NSString *)keyPath {
    return [self mappingForKeyPath:keyPath context:RKObjectMappingProviderContextObjectsByKeyPath];
}

- (void)setSerializationMapping:(RKObjectMapping *)mapping forClass:(Class)objectClass {
    [self setMapping:mapping forKeyPath:NSStringFromClass(objectClass) context:RKObjectMappingProviderContextSerialization];
}

- (RKObjectMapping *)serializationMappingForClass:(Class)objectClass {
    return [self mappingForKeyPath:NSStringFromClass(objectClass) context:RKObjectMappingProviderContextSerialization];
}

- (NSDictionary*)objectMappingsByKeyPath {
    return [NSDictionary dictionaryWithDictionary:(NSDictionary *) [self valueForContext:RKObjectMappingProviderContextObjectsByKeyPath]];
}

- (void)registerObjectMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath {
    // TODO: Should generate logs
    objectMapping.rootKeyPath = keyPath;
    [self setMapping:objectMapping forKeyPath:keyPath];
    RKObjectMapping* inverseMapping = [objectMapping inverseMapping];
    inverseMapping.rootKeyPath = keyPath;
    [self setSerializationMapping:inverseMapping forClass:objectMapping.objectClass];
}

- (void)addObjectMapping:(RKObjectMapping *)objectMapping {
    [self addMapping:objectMapping context:RKObjectMappingProviderContextObjectsByType];
}

- (NSArray *)objectMappingsForClass:(Class)theClass {
    NSMutableArray *mappings = [NSMutableArray array];
    NSArray *mappingByType = [self valueForContext:RKObjectMappingProviderContextObjectsByType];
    NSArray *mappingByKeyPath = [[self valueForContext:RKObjectMappingProviderContextObjectsByKeyPath] allValues];
    NSArray *mappingsToSearch = [[NSArray arrayWithArray:mappingByType] arrayByAddingObjectsFromArray:mappingByKeyPath];
    for (NSObject <RKObjectMappingDefinition> *candidateMapping in mappingsToSearch) {
        if ( ![candidateMapping respondsToSelector:@selector(objectClass)] || [mappings containsObject:candidateMapping])
            continue;
        Class mappedClass = [candidateMapping performSelector:@selector(objectClass)];
        if (mappedClass && [NSStringFromClass(mappedClass) isEqualToString:NSStringFromClass(theClass)]) {
            [mappings addObject:candidateMapping];
        }
    }
    return [NSArray arrayWithArray:mappings];
}

- (RKObjectMapping *)objectMappingForClass:(Class)theClass {
    NSArray* objectMappings = [self objectMappingsForClass:theClass];
    return ([objectMappings count] > 0) ? [objectMappings objectAtIndex:0] : nil;
}

#pragma mark - Error Mappings

- (RKObjectMapping *)errorMapping {
    return [self mappingForContext:RKObjectMappingProviderContextErrors];
}

- (void)setErrorMapping:(RKObjectMapping *)errorMapping {
    if (errorMapping) {
        [self setMapping:errorMapping context:RKObjectMappingProviderContextErrors];
    }
}

#pragma mark - Pagination Mapping

- (RKObjectMapping *)paginationMapping {
    return [self mappingForContext:RKObjectMappingProviderContextPagination];
}

- (void)setPaginationMapping:(RKObjectMapping *)paginationMapping {
    [self setMapping:paginationMapping context:RKObjectMappingProviderContextPagination];
}

- (void)setObjectMapping:(id<RKObjectMappingDefinition>)objectMapping forResourcePathPattern:(NSString *)resourcePath {
    [self setMapping:objectMapping forPattern:resourcePath context:RKObjectMappingProviderContextObjectsByResourcePathPattern];
}

- (id<RKObjectMappingDefinition>)objectMappingForResourcePath:(NSString *)resourcePath {
    return [self mappingForPatternMatchingString:resourcePath context:RKObjectMappingProviderContextObjectsByResourcePathPattern];
}

#pragma mark - Mapping Context Primitives

- (void)initializeContext:(RKObjectMappingProviderContext)context withValue:(id)value {
    NSAssert([self valueForContext:context] == nil, @"Attempt to reinitialized an existing mapping provider context.");
    [self setValue:value forContext:context];
}

- (id)valueForContext:(RKObjectMappingProviderContext)context {
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    return [mappingContexts objectForKey:contextNumber];
}

- (void)setValue:(id)value forContext:(RKObjectMappingProviderContext)context {
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    [mappingContexts setObject:value forKey:contextNumber];
}

- (void)assertStorageForContext:(RKObjectMappingProviderContext)context isKindOfClass:(Class)theClass {
    id contextValue = [self valueForContext:context];
    NSAssert([contextValue isKindOfClass:theClass], @"Storage type mismatch for context %d: expected a %@, got %@.", context, theClass, [contextValue class]);
}

- (void)setMapping:(id<RKObjectMappingDefinition>)mapping context:(RKObjectMappingProviderContext)context {
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    [mappingContexts setObject:mapping forKey:contextNumber];
}

- (id<RKObjectMappingDefinition>)mappingForContext:(RKObjectMappingProviderContext)context {
    id contextValue = [self valueForContext:context];
    if ([contextValue isEqual:[NSNull null]]) return nil;
    Protocol *protocol = @protocol(RKObjectMappingDefinition);
    NSAssert([contextValue conformsToProtocol:protocol], @"Storage type mismatch for context %d: expected a %@, got %@.", context, protocol, [contextValue class]);
    return contextValue;
}

- (NSArray *)mappingsForContext:(RKObjectMappingProviderContext)context {
    id contextValue = [self valueForContext:context];
    if (contextValue == nil) return [NSArray array];
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];
    
    return [NSArray arrayWithArray:contextValue];
}

- (void)addMapping:(id<RKObjectMappingDefinition>)mapping context:(RKObjectMappingProviderContext)context {
    NSMutableArray *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [NSMutableArray arrayWithCapacity:1];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];
    [contextValue addObject:mapping];
}

- (void)removeMapping:(id<RKObjectMappingDefinition>)mapping context:(RKObjectMappingProviderContext)context {
    NSMutableArray *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to remove mapping from undefined context: %d", context);
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];
    NSAssert([contextValue containsObject:mapping], @"Attempted to remove mapping from collection that does not include it for context: %d", context);
    [contextValue removeObject:mapping];
}

- (id<RKObjectMappingDefinition>)mappingForKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context {
    NSMutableDictionary *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    return [contextValue valueForKey:keyPath];
}

- (void)setMapping:(id<RKObjectMappingDefinition>)mapping forKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context {
    NSMutableDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [NSMutableDictionary dictionary];
        [self setValue:contextValue forContext:context];      
    }
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    [contextValue setValue:mapping forKey:keyPath];
}
              
- (void)removeMappingForKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context {
    NSMutableDictionary *contextValue = [self valueForContext:context];
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    [contextValue removeObjectForKey:keyPath];
}

- (void)setMapping:(id<RKObjectMappingDefinition>)mapping forPattern:(NSString *)pattern atIndex:(NSUInteger)index context:(RKObjectMappingProviderContext)context {
    RKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [RKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];      
    }
    [self assertStorageForContext:context isKindOfClass:[RKOrderedDictionary class]];
    [contextValue insertObject:mapping forKey:pattern atIndex:index];
}

- (void)setMapping:(id<RKObjectMappingDefinition>)mapping forPattern:(NSString *)pattern context:(RKObjectMappingProviderContext)context {
    RKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [RKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];      
    }
    [self assertStorageForContext:context isKindOfClass:[RKOrderedDictionary class]];
    [contextValue setObject:mapping forKey:pattern];
}

- (id<RKObjectMappingDefinition>)mappingForPatternMatchingString:(NSString *)string context:(RKObjectMappingProviderContext)context {
    RKOrderedDictionary *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    for (NSString *pattern in contextValue) {
        RKPathMatcher *pathMatcher = [RKPathMatcher matcherWithPattern:pattern];
        if ([pathMatcher matchesPath:string tokenizeQueryStrings:NO parsedArguments:nil]) {
            return [contextValue objectForKey:pattern];
        }
    }
    
    return nil;
}

#pragma mark - Aliases

+ (RKObjectMappingProvider *)objectMappingProvider {
    return [self mappingProvider];
}

- (RKObjectMapping *)mappingForKeyPath:(NSString *)keyPath {
    return (RKObjectMapping *) [self objectMappingForKeyPath:keyPath];
}

- (void)setMapping:(RKObjectMapping *)mapping forKeyPath:(NSString *)keyPath {
    [self setObjectMapping:mapping forKeyPath:keyPath];
}

- (NSDictionary *)mappingsByKeyPath {
    return [self objectMappingsByKeyPath];
}

- (void)registerMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath {
    return [self registerObjectMapping:objectMapping withRootKeyPath:keyPath];
}

- (void)removeMappingForKeyPath:(NSString *)keyPath {
    [self removeObjectMappingForKeyPath:keyPath];
}

@end
