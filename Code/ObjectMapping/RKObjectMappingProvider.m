//
//  RKObjectMappingProvider.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
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
#import "RKObjectMappingProvider+Contexts.h"
#import "RKOrderedDictionary.h"
#import "RKPathMatcher.h"
#import "RKObjectMappingProviderContextEntry.h"
#import "RKErrorMessage.h"

@implementation RKObjectMappingProvider

+ (RKObjectMappingProvider *)mappingProvider
{
    return [[self new] autorelease];
}

+ (RKObjectMappingProvider *)mappingProviderUsingBlock:(void (^)(RKObjectMappingProvider *mappingProvider))block
{
    RKObjectMappingProvider *mappingProvider = [self mappingProvider];
    block(mappingProvider);
    return mappingProvider;
}

- (id)init
{
    self = [super init];
    if (self) {
        mappingContexts = [NSMutableDictionary new];
        [self initializeContext:RKObjectMappingProviderContextObjectsByKeyPath withValue:[NSMutableDictionary dictionary]];
        [self initializeContext:RKObjectMappingProviderContextObjectsByType withValue:[NSMutableArray array]];
        [self initializeContext:RKObjectMappingProviderContextObjectsByResourcePathPattern withValue:[RKOrderedDictionary dictionary]];
        [self initializeContext:RKObjectMappingProviderContextSerialization withValue:[NSMutableDictionary dictionary]];
        [self initializeContext:RKObjectMappingProviderContextErrors withValue:[NSNull null]];

        // Setup default error message mappings
        RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
        errorMapping.rootKeyPath = @"errors";
        [errorMapping mapKeyPath:@"" toAttribute:@"errorMessage"];
        self.errorMapping = errorMapping;
    }
    return self;
}

- (void)dealloc
{
    [mappingContexts release];
    [super dealloc];
}

- (void)setObjectMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping forKeyPath:(NSString *)keyPath
{
    [self setMapping:objectOrDynamicMapping forKeyPath:keyPath context:RKObjectMappingProviderContextObjectsByKeyPath];
}

- (void)removeObjectMappingForKeyPath:(NSString *)keyPath
{
    [self removeMappingForKeyPath:keyPath context:RKObjectMappingProviderContextObjectsByKeyPath];
}

- (RKObjectMappingDefinition *)objectMappingForKeyPath:(NSString *)keyPath
{
    return [self mappingForKeyPath:keyPath context:RKObjectMappingProviderContextObjectsByKeyPath];
}

- (void)setSerializationMapping:(RKObjectMapping *)mapping forClass:(Class)objectClass
{
    [self setMapping:mapping forKeyPath:NSStringFromClass(objectClass) context:RKObjectMappingProviderContextSerialization];
}

- (RKObjectMapping *)serializationMappingForClass:(Class)objectClass
{
    return (RKObjectMapping *)[self mappingForKeyPath:NSStringFromClass(objectClass) context:RKObjectMappingProviderContextSerialization];
}

- (NSDictionary *)objectMappingsByKeyPath
{
    return [NSDictionary dictionaryWithDictionary:(NSDictionary *)[self valueForContext:RKObjectMappingProviderContextObjectsByKeyPath]];
}

- (void)registerObjectMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath
{
    // TODO: Should generate logs
    objectMapping.rootKeyPath = keyPath;
    [self setMapping:objectMapping forKeyPath:keyPath];
    RKObjectMapping *inverseMapping = [objectMapping inverseMapping];
    inverseMapping.rootKeyPath = keyPath;
    [self setSerializationMapping:inverseMapping forClass:objectMapping.objectClass];
}

- (void)addObjectMapping:(RKObjectMapping *)objectMapping
{
    [self addMapping:objectMapping context:RKObjectMappingProviderContextObjectsByType];
}

- (NSArray *)objectMappingsForClass:(Class)theClass
{
    NSMutableArray *mappings = [NSMutableArray array];
    NSArray *mappingByType = [self valueForContext:RKObjectMappingProviderContextObjectsByType];
    NSArray *mappingByKeyPath = [[self valueForContext:RKObjectMappingProviderContextObjectsByKeyPath] allValues];
    NSArray *mappingsToSearch = [[NSArray arrayWithArray:mappingByType] arrayByAddingObjectsFromArray:mappingByKeyPath];
    for (RKObjectMappingDefinition *candidateMapping in mappingsToSearch) {
        if (![candidateMapping respondsToSelector:@selector(objectClass)] || [mappings containsObject:candidateMapping])
            continue;
        Class mappedClass = [candidateMapping performSelector:@selector(objectClass)];
        if (mappedClass && [NSStringFromClass(mappedClass) isEqualToString:NSStringFromClass(theClass)]) {
            [mappings addObject:candidateMapping];
        }
    }
    return [NSArray arrayWithArray:mappings];
}

- (RKObjectMapping *)objectMappingForClass:(Class)theClass
{
    NSArray *objectMappings = [self objectMappingsForClass:theClass];
    return ([objectMappings count] > 0) ? [objectMappings objectAtIndex:0] : nil;
}

#pragma mark - Error Mappings

- (RKObjectMapping *)errorMapping
{
    return (RKObjectMapping *)[self mappingForContext:RKObjectMappingProviderContextErrors];
}

- (void)setErrorMapping:(RKObjectMapping *)errorMapping
{
    if (errorMapping) {
        [self setMapping:errorMapping context:RKObjectMappingProviderContextErrors];
    }
}

#pragma mark - Pagination Mapping

- (RKObjectMapping *)paginationMapping
{
    return (RKObjectMapping *)[self mappingForContext:RKObjectMappingProviderContextPagination];
}

- (void)setPaginationMapping:(RKObjectMapping *)paginationMapping
{
    [self setMapping:paginationMapping context:RKObjectMappingProviderContextPagination];
}

- (void)setObjectMapping:(RKObjectMappingDefinition *)objectMapping forResourcePathPattern:(NSString *)resourcePath
{
    [self setMapping:objectMapping forPattern:resourcePath context:RKObjectMappingProviderContextObjectsByResourcePathPattern];
}

- (RKObjectMappingDefinition *)objectMappingForResourcePath:(NSString *)resourcePath
{
    return [self mappingForPatternMatchingString:resourcePath context:RKObjectMappingProviderContextObjectsByResourcePathPattern];
}

- (void)setEntry:(RKObjectMappingProviderContextEntry *)entry forResourcePathPattern:(NSString *)resourcePath
{
    [self setEntry:entry forPattern:resourcePath context:RKObjectMappingProviderContextObjectsByResourcePathPattern];
}

- (RKObjectMappingProviderContextEntry *)entryForResourcePath:(NSString *)resourcePath
{
    return [self entryForPatternMatchingString:resourcePath context:RKObjectMappingProviderContextObjectsByResourcePathPattern];
}

#pragma mark - Mapping Context Primitives

- (void)initializeContext:(RKObjectMappingProviderContext)context withValue:(id)value
{
    NSAssert([self valueForContext:context] == nil, @"Attempt to reinitialized an existing mapping provider context.");
    [self setValue:value forContext:context];
}

- (id)valueForContext:(RKObjectMappingProviderContext)context
{
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    return [mappingContexts objectForKey:contextNumber];
}

- (void)setValue:(id)value forContext:(RKObjectMappingProviderContext)context
{
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    [mappingContexts setObject:value forKey:contextNumber];
}

- (void)assertStorageForContext:(RKObjectMappingProviderContext)context isKindOfClass:(Class)theClass
{
    id contextValue = [self valueForContext:context];
    NSAssert([contextValue isKindOfClass:theClass], @"Storage type mismatch for context %d: expected a %@, got %@.", context, theClass, [contextValue class]);
}

- (void)setMapping:(RKObjectMappingDefinition *)mapping context:(RKObjectMappingProviderContext)context
{
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    [mappingContexts setObject:mapping forKey:contextNumber];
}

- (RKObjectMappingDefinition *)mappingForContext:(RKObjectMappingProviderContext)context
{
    id contextValue = [self valueForContext:context];
    if ([contextValue isEqual:[NSNull null]]) return nil;
    Class class = [RKObjectMappingDefinition class];
    NSAssert([contextValue isKindOfClass:class], @"Storage type mismatch for context %d: expected a %@, got %@.", context, class, [contextValue class]);
    return contextValue;
}

- (NSArray *)mappingsForContext:(RKObjectMappingProviderContext)context
{
    id contextValue = [self valueForContext:context];
    if (contextValue == nil) return [NSArray array];
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];

    return [NSArray arrayWithArray:contextValue];
}

- (void)addMapping:(RKObjectMappingDefinition *)mapping context:(RKObjectMappingProviderContext)context
{
    NSMutableArray *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [NSMutableArray arrayWithCapacity:1];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];
    [contextValue addObject:mapping];
}

- (void)removeMapping:(RKObjectMappingDefinition *)mapping context:(RKObjectMappingProviderContext)context
{
    NSMutableArray *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to remove mapping from undefined context: %d", context);
    [self assertStorageForContext:context isKindOfClass:[NSArray class]];
    NSAssert([contextValue containsObject:mapping], @"Attempted to remove mapping from collection that does not include it for context: %d", context);
    [contextValue removeObject:mapping];
}

- (RKObjectMappingDefinition *)mappingForKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context
{
    NSMutableDictionary *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    return [contextValue valueForKey:keyPath];
}

- (void)setMapping:(RKObjectMappingDefinition *)mapping forKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context
{
    NSMutableDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [NSMutableDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    [contextValue setValue:mapping forKey:keyPath];
}

- (void)removeMappingForKeyPath:(NSString *)keyPath context:(RKObjectMappingProviderContext)context
{
    NSMutableDictionary *contextValue = [self valueForContext:context];
    [self assertStorageForContext:context isKindOfClass:[NSDictionary class]];
    [contextValue removeObjectForKey:keyPath];
}

- (void)setMapping:(RKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern atIndex:(NSUInteger)index context:(RKObjectMappingProviderContext)context
{
    RKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [RKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[RKOrderedDictionary class]];
    [contextValue insertObject:[RKObjectMappingProviderContextEntry contextEntryWithMapping:mapping]
                        forKey:pattern
                       atIndex:index];
}

- (void)setMapping:(RKObjectMappingDefinition *)mapping forPattern:(NSString *)pattern context:(RKObjectMappingProviderContext)context
{
    RKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [RKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[RKOrderedDictionary class]];
    [contextValue setObject:[RKObjectMappingProviderContextEntry contextEntryWithMapping:mapping]
                     forKey:pattern];
}

- (RKObjectMappingDefinition *)mappingForPatternMatchingString:(NSString *)string context:(RKObjectMappingProviderContext)context
{
    NSAssert(string, @"Cannot look up mapping matching nil pattern string.");
    RKOrderedDictionary *contextValue = [self valueForContext:context];
    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    for (NSString *pattern in contextValue) {
        RKPathMatcher *pathMatcher = [RKPathMatcher matcherWithPattern:pattern];
        if ([pathMatcher matchesPath:string tokenizeQueryStrings:NO parsedArguments:nil]) {
            RKObjectMappingProviderContextEntry *entry = [contextValue objectForKey:pattern];
            return entry.mapping;
        }
    }

    return nil;
}

- (void)setEntry:(RKObjectMappingProviderContextEntry *)entry forPattern:(NSString *)pattern context:(RKObjectMappingProviderContext)context
{
    RKOrderedDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [RKOrderedDictionary dictionary];
        [self setValue:contextValue forContext:context];
    }
    [self assertStorageForContext:context isKindOfClass:[RKOrderedDictionary class]];
    [contextValue setObject:entry
                     forKey:pattern];
}

- (RKObjectMappingProviderContextEntry *)entryForPatternMatchingString:(NSString *)string context:(RKObjectMappingProviderContext)context
{
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

+ (RKObjectMappingProvider *)objectMappingProvider
{
    return [self mappingProvider];
}

- (RKObjectMapping *)mappingForKeyPath:(NSString *)keyPath
{
    return (RKObjectMapping *)[self objectMappingForKeyPath:keyPath];
}

- (void)setMapping:(RKObjectMapping *)mapping forKeyPath:(NSString *)keyPath
{
    [self setObjectMapping:mapping forKeyPath:keyPath];
}

- (NSDictionary *)mappingsByKeyPath
{
    return [self objectMappingsByKeyPath];
}

- (void)registerMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath
{
    return [self registerObjectMapping:objectMapping withRootKeyPath:keyPath];
}

- (void)removeMappingForKeyPath:(NSString *)keyPath
{
    [self removeObjectMappingForKeyPath:keyPath];
}

// Deprecated
+ (id)mappingProviderWithBlock:(void (^)(RKObjectMappingProvider *))block
{
    return [self mappingProviderUsingBlock:block];
}

@end
