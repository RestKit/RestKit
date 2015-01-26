//
//  RKDynamicMappingMatcher.m
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectMappingMatcher.h"
#import "RKObjectUtilities.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface RKObjectMappingMatcher ()
@property (nonatomic, strong, readwrite) RKObjectMapping *objectMapping;
@end

@interface RKKeyPathObjectMappingMatcher : RKObjectMappingMatcher
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong, readwrite) id expectedValue;

- (id)initWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping;
@end

@interface RKKeyPathClassObjectMappingMatcher : RKObjectMappingMatcher

@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, readwrite) Class expectedClass;

- (id)initWithKeyPath:(NSString *)keyPath expectedClass:(Class)expectedClass objectMapping:(RKObjectMapping *)objectMapping;

@end

@interface RKKeyPathValueMapObjectMappingMatcher : RKObjectMappingMatcher
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) NSDictionary *valueMap;

- (instancetype)initWithKeyPath:(NSString *)keyPath expectedValueMap:(NSDictionary *)valueToObjectMapping;
@end

@interface RKPredicateObjectMappingMatcher : RKObjectMappingMatcher
@property (nonatomic, strong) NSPredicate *predicate;

- (id)initWithPredicate:(NSPredicate *)predicate objectMapping:(RKObjectMapping *)objectMapping;
@end

@interface RKBlockObjectMatchingMatcher : RKObjectMappingMatcher
@property (nonatomic, copy) NSArray *possibleMappings;
@property (nonatomic, copy) RKObjectMapping *(^block)(id representation);
- (instancetype)initWithPossibleMappings:(NSArray *)mappings block:(RKObjectMapping *(^)(id representation))block;
@end


///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKObjectMappingMatcher

+ (instancetype)matcherWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping
{
    return [[RKKeyPathObjectMappingMatcher alloc] initWithKeyPath:keyPath expectedValue:expectedValue objectMapping:objectMapping];
}

+ (instancetype)matcherWithKeyPath:(NSString *)keyPath expectedClass:(Class)expectedClass objectMapping:(RKObjectMapping *)objectMapping
{
    return [[RKKeyPathClassObjectMappingMatcher alloc] initWithKeyPath:keyPath expectedClass:expectedClass objectMapping:objectMapping];
}

+ (instancetype)matcherWithKeyPath:(NSString *)keyPath expectedValueMap:(NSDictionary *)valueToObjectMapping
{
    return [[RKKeyPathValueMapObjectMappingMatcher alloc] initWithKeyPath:keyPath expectedValueMap:valueToObjectMapping];
}

+ (instancetype)matcherWithPredicate:(NSPredicate *)predicate objectMapping:(RKObjectMapping *)objectMapping
{
    return [[RKPredicateObjectMappingMatcher alloc] initWithPredicate:predicate objectMapping:objectMapping];
}

+ (instancetype)matcherWithPossibleMappings:(NSArray *)mappings block:(RKObjectMapping *(^)(id representation))block
{
    return [[RKBlockObjectMatchingMatcher alloc] initWithPossibleMappings:mappings block:block];
}

- (id)init
{
    self = [super init];
    if (self) {
        if ([self isMemberOfClass:[RKObjectMappingMatcher class]]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"%@ is not meant to be directly instantiated. Use one of the initializer methods instead.",
                                                   NSStringFromClass([self class])]
                                         userInfo:nil];
        }
    }

    return self;
}

- (NSArray *)possibleObjectMappings
{
    RKObjectMapping *mapping = self.objectMapping;
    return mapping ? @[mapping] : nil;
}

- (BOOL)matches:(id)object
{
    return NO;
}

@end

@implementation RKKeyPathObjectMappingMatcher

- (id)initWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping
{
    NSParameterAssert(keyPath);
    NSParameterAssert(expectedValue);
    NSParameterAssert(objectMapping);
    self = [super init];
    if (self) {
        self.keyPath = keyPath;
        self.expectedValue = expectedValue;
        self.objectMapping = objectMapping;
    }

    return self;
}

- (BOOL)matches:(id)object
{
    id value = [object valueForKeyPath:self.keyPath];
    if (value == nil) return NO;
    return RKObjectIsEqualToObject(value, self.expectedValue);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when `%@` == '%@' objectMapping: %@>", NSStringFromClass([self class]), self, self.keyPath, self.expectedValue, self.objectMapping];
}

@end

@implementation RKKeyPathClassObjectMappingMatcher

- (id)initWithKeyPath:(NSString *)keyPath expectedClass:(Class)expectedClass objectMapping:(RKObjectMapping *)objectMapping
{
    NSParameterAssert(keyPath);
    NSParameterAssert(expectedClass);
    NSParameterAssert(objectMapping);
    self = [super init];
    if (self) {
        self.keyPath = keyPath;
        self.expectedClass = expectedClass;
        self.objectMapping = objectMapping;
    }
    
    return self;
}

- (BOOL)matches:(id)object
{
    id value = [object valueForKeyPath:self.keyPath];
    return [[value class] isSubclassOfClass:self.expectedClass];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when `%@` == '%@' objectMapping: %@>", NSStringFromClass([self class]), self, self.keyPath, self.expectedClass, self.objectMapping];
}

@end

@implementation RKKeyPathValueMapObjectMappingMatcher

- (instancetype)initWithKeyPath:(NSString *)keyPath expectedValueMap:(NSDictionary *)valueToObjectMapping
{
    NSParameterAssert(keyPath);
    NSParameterAssert(valueToObjectMapping.count > 0);
    self = [super init];
    if (self) {
        self.keyPath = keyPath;
        self.valueMap = valueToObjectMapping;
    }
    
    return self;
}

- (NSArray *)possibleObjectMappings
{
    return [self.valueMap allValues];
}

- (BOOL)matches:(id)object
{
    id value = [object valueForKeyPath:self.keyPath];
    RKObjectMapping *mapping = [self.valueMap objectForKey:value];
    if (mapping) {
        self.objectMapping = mapping;
        return YES;
    }
    
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when `%@` in '%@'>", NSStringFromClass([self class]), self, self.keyPath, [self.valueMap allKeys]];
}

@end

@implementation RKPredicateObjectMappingMatcher

- (id)initWithPredicate:(NSPredicate *)predicate objectMapping:(RKObjectMapping *)objectMapping
{
    NSParameterAssert(predicate);
    NSParameterAssert(objectMapping);
    self = [super init];
    if (self) {
        self.predicate = predicate;
        self.objectMapping = objectMapping;
    }

    return self;
}

- (BOOL)matches:(id)object
{
    return [self.predicate evaluateWithObject:object];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when '%@' objectMapping: %@>", NSStringFromClass([self class]), self, self.predicate, self.objectMapping];
}

@end

@implementation RKBlockObjectMatchingMatcher

- (instancetype)initWithPossibleMappings:(NSArray *)mappings block:(RKObjectMapping *(^)(id representation))block
{
    NSParameterAssert(block);
    self = [super init];
    if (self) {
        self.block = block;
        self.possibleMappings = mappings;
    }
    
    return self;
}

- (NSArray *)possibleObjectMappings
{
    return self.possibleMappings;
}

- (BOOL)matches:(id)object
{
    RKObjectMapping *mapping = self.block(object);
    if (mapping) {
        self.objectMapping = mapping;
        return YES;
    }
    
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when '%@'>", NSStringFromClass([self class]), self, self.block];
}

@end
