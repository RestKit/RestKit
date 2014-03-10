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

@interface RKKeyPathObjectMappingMatcher : RKObjectMappingMatcher <NSCopying>
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong, readwrite) id expectedValue;

- (id)initWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping;
@end

@interface RKPredicateObjectMappingMatcher : RKObjectMappingMatcher <NSCopying>
@property (nonatomic, strong) NSPredicate *predicate;

- (id)initWithPredicate:(NSPredicate *)predicate objectMapping:(RKObjectMapping *)objectMapping;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKObjectMappingMatcher

+ (instancetype)matcherWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping
{
    return [[RKKeyPathObjectMappingMatcher alloc] initWithKeyPath:keyPath expectedValue:expectedValue objectMapping:objectMapping];
}

+ (instancetype)matcherWithPredicate:(NSPredicate *)predicate objectMapping:(RKObjectMapping *)objectMapping
{
    return [[RKPredicateObjectMappingMatcher alloc] initWithPredicate:predicate objectMapping:objectMapping];
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

- (BOOL)matches:(id)object
{
    return NO;
}

- (instancetype)matcherWithInverseObjectMapping
{
    return nil;
}

- (void)copyPropertiesFromMatcher:(RKObjectMappingMatcher *)mapping
{
    self.objectMapping = [mapping.objectMapping copy];
}

- (id)copyWithZone:(NSZone *)zone
{
    RKObjectMappingMatcher *copy = [[[self class] allocWithZone:zone] init];
    [copy copyPropertiesFromMatcher:self];
    return copy;
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

- (instancetype)matcherWithInverseObjectMapping
{
    return [[RKKeyPathObjectMappingMatcher alloc] initWithKeyPath:self.keyPath expectedValue:self.expectedValue objectMapping:[self.objectMapping inverseMapping]];
}

- (id)copyWithZone:(NSZone *)zone
{
    RKKeyPathObjectMappingMatcher *copy = [[[self class] allocWithZone:zone] initWithKeyPath:self.keyPath expectedValue:self.expectedValue objectMapping:[self.objectMapping copy]];
    [copy copyPropertiesFromMatcher:self];
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when `%@` == '%@' objectMapping: %@>", NSStringFromClass([self class]), self, self.keyPath, self.expectedValue, self.objectMapping];
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

- (instancetype)matcherWithInverseObjectMapping
{
    return [[RKPredicateObjectMappingMatcher alloc] initWithPredicate:self.predicate objectMapping:[self.objectMapping inverseMapping]];
}

- (id)copyWithZone:(NSZone *)zone
{
    RKPredicateObjectMappingMatcher *copy = [[[self class] allocWithZone:zone] initWithPredicate:[self.predicate copy] objectMapping:[self.objectMapping copy]];
    [copy copyPropertiesFromMatcher:self];
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when '%@' objectMapping: %@>", NSStringFromClass([self class]), self, self.predicate, self.objectMapping];
}

@end
