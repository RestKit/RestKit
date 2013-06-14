//
//  RKValueTransformers.m
//  RestKit
//
//  Created by Blake Watters on 11/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKValueTransformers.h"
#import "RKMacros.h"

#import <objc/runtime.h> // needed for associative references

#import "RKLog.h"

@interface RKValueTransformer ()

@property (nonatomic, copy) RKValueTransformationBlock transformationBlock;
@property (nonatomic, copy) RKValueTransformationBlock reverseTransformationBlock;

@property (readwrite) Class sourceClass;
@property (readwrite) Class destinationClass;

@end

@interface RKIdentityValueTransformer : RKValueTransformer
@end

@interface RKStringValueTransformer : RKValueTransformer
@end

@implementation RKValueTransformer

+ (Class)transformedValueClass {
    return [NSObject class];
}

+ (instancetype)valueTransformerWithSourceClass:(Class)sourceClass
                               destinationClass:(Class)destinationClass
                            transformationBlock:(RKValueTransformationBlock)transformationBlock
                     reverseTransformationBlock:(RKValueTransformationBlock)reverseTransformationBlock
{
    if (! sourceClass) [NSException raise:NSInvalidArgumentException format:@"`sourceClass` cannot be `Nil`."];
    if (! destinationClass) [NSException raise:NSInvalidArgumentException format:@"`destinationClass` cannot be `Nil`."];
    if (!transformationBlock) [NSException raise:NSInvalidArgumentException format:@"`transformationBlock` cannot be `nil`."];
    RKValueTransformer *transformer = [[self alloc] initWithSourceClass:sourceClass
                                                       destinationClass:destinationClass
                                                    transformationBlock:transformationBlock
                                             reverseTransformationBlock:reverseTransformationBlock];
    return transformer;
}

- (instancetype)initWithSourceClass:(Class)sourceClass destinationClass:(Class)destinationClass transformationBlock:(RKValueTransformationBlock)transformationBlock reverseTransformationBlock:(RKValueTransformationBlock)reverseTransformationBlock
{
    if (self = [super init]) {
        self.sourceClass = sourceClass;
        self.destinationClass = destinationClass;
        self.transformationBlock = transformationBlock;
        self.reverseTransformationBlock = reverseTransformationBlock;
    }
    return self;
}

- (id)transformedValue:(id)value
{
    // Call our transformation block. If it returns `NO`, then return original `value`
    id retVal;
    NSError *error;
    BOOL success = self.transformationBlock(value, &retVal, &error);
    if (error) RKLogError(@"Error transforming %@ to %@ class: %@", value, self.destinationClass, error);
    if (!success) {
        return value;
    }
    return retVal;
}

- (id)reverseTransformedValue:(id)value
{
    // If transformation block is non-nil, invoke it: If it returns `NO`, then return original `value`
    // If transformation block is nil, call super (which will t)
    id retVal;
    NSError *error;
    if (!self.reverseTransformationBlock) return nil;
    BOOL success = self.reverseTransformationBlock(value, &retVal, &error);
    if (error) RKLogError(@"Error transforming %@ to %@ class: %@", value, self.destinationClass, error);
    if (!success) {
        return value;
    }
    return retVal;
}

+ (NSArray *)valueTransformersForTransformingFromClass:(Class)sourceClass toClass:(Class)destinationClass
{
    NSMutableArray *transformers = [NSMutableArray array];
    for (RKValueTransformer *transformer in [self registeredValueTransformers]) {
        if ([transformer canTransformClass:sourceClass toClass:destinationClass]) {
            [transformers addObject:transformer];
        }
    }
    
    return transformers;
    
//    array = [array filteredArrayUsingPredicate:predicate];
//    reverseArray = [reverseArray filteredArrayUsingPredicate:reversePredicate];
//    array = [array arrayByAddingObjectsFromArray:reverseArray];
//    if ([sourceClass isSubclassOfClass:destinationClass]) {
//        array = [array arrayByAddingObject:[self identityTransformer]];
//    }
//    if (destinationClass == [NSString class] && [sourceClass instancesRespondToSelector:@selector(stringValue)]) {
//        array = [array arrayByAddingObject:[self stringValueTransformer]];
//    }
//    if ([sourceClass isSubclassOfClass:[NSNull class]]) {
//        array = [array arrayByAddingObject:[self defaultNullTransformer]];
//    }
//    return array;
}

- (BOOL)canTransformClass:(Class)sourceClass toClass:(Class)destinationClass
{
    if ([sourceClass isSubclassOfClass:self.sourceClass] && [destinationClass isSubclassOfClass:self.destinationClass]) return YES;
    else if ([destinationClass isSubclassOfClass:self.sourceClass] && [sourceClass isSubclassOfClass:self.destinationClass]) return YES;
    else return NO;
}

- (BOOL)transformValue:(id)inputValue toValue:(id *)outputValue error:(NSError **)error
{
    id outValue;
    BOOL success = FALSE;
    if ([inputValue isKindOfClass:self.sourceClass]) {
        success = self.transformationBlock(inputValue, &outValue, error);
    }
    if (!success && self.reverseTransformationBlock != nil && [inputValue isKindOfClass:self.destinationClass]) {
        outValue = nil;
        success = self.reverseTransformationBlock(inputValue, &outValue, error);
    }
    if (success) {
        *outputValue = outValue;
    }
    return success;
}

- (void)_register
{
    [RKValueTransformer registerValueTransformer:self];
}

+ (NSMutableArray *)registeredValueTransformers
{
    static NSMutableArray *transformers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformers = [NSMutableArray array];
    });
    return transformers;
}

+ (void)registerValueTransformer:(RKValueTransformer *)valueTransformer
{
    if (![valueTransformer isKindOfClass:[RKValueTransformer class]])
        [NSException raise:NSInvalidArgumentException format:@"`valueTransformer` must be a valid `RKValueTransformer`"];
    NSMutableArray *transformers = [self registeredValueTransformers];
    if ([transformers containsObject:valueTransformer]) return;
    [transformers insertObject:valueTransformer atIndex:0];
}

+ (void)unregisterValueTransformer:(RKValueTransformer *)valueTransformer
{
    NSMutableArray *transformers = [self registeredValueTransformers];
    [transformers removeObject:valueTransformer];
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"RK%@To%@ValueTransformer", NSStringFromClass(self.sourceClass), NSStringFromClass(self.destinationClass)];
}

- (NSString *)description
{
    return self.name;
}

// Set up the built-in transformers
+ (void)initialize
{
    [super initialize];
    if ([RKValueTransformer class] != self) return;
    [[self defaultStringToURLTransformer] _register];
    [[self defaultStringToNumberTransformer] _register];
    [[self defaultNumberToDateTransformer] _register];
    [[self defaultOrderedSetToArrayTransformer] _register];
    [[self defaultSetToArrayTransformer] _register];
    [[self defaultStringToDecimalNumberTransformer] _register];
    [[self defaultNumberToDecimalNumberTransformer] _register];
    [[self defaultObjectToDataTransformer] _register];
    [[self defaultNullTransformer] _register];
    [[self identityTransformer] _register];
}

+ (instancetype)defaultStringToURLTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSString class] destinationClass:[NSURL class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSURL URLWithString:inputValue];
            return YES;
        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [inputValue absoluteString];
            return YES;
        }];
    });
    return transformer;
}

+ (instancetype)defaultStringToNumberTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSString class] destinationClass:[NSNumber class] transformationBlock:^BOOL(NSString* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            NSString *lowercasedString = [inputValue lowercaseString];
            NSSet *trueStrings = [NSSet setWithObjects:@"true", @"t", @"yes", @"y", nil];
            NSSet *booleanStrings = [trueStrings setByAddingObjectsFromSet:[NSSet setWithObjects:@"false", @"f", @"no", @"n", nil]];
            if ([booleanStrings containsObject:lowercasedString]) {
                // Handle booleans encoded as Strings
                *outputValue = [NSNumber numberWithBool:[trueStrings containsObject:lowercasedString]];
                return YES;
            } else if ([lowercasedString rangeOfString:@"."].location != NSNotFound) {
                // String -> Floating Point Number
                // Only use floating point if needed to avoid losing precision
                // on large integers
                *outputValue = [NSNumber numberWithDouble:[lowercasedString doubleValue]];
                return YES;
            } else {
                // String -> Signed Integer
                *outputValue = [NSNumber numberWithLongLong:[lowercasedString longLongValue]];
                return YES;
            }
        } reverseTransformationBlock:^BOOL(NSNumber* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            if (NSClassFromString(@"__NSCFBoolean") && [inputValue isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
                *outputValue = [inputValue boolValue] ? @"true" : @"false";
            } else if (NSClassFromString(@"NSCFBoolean") && [inputValue isKindOfClass:NSClassFromString(@"NSCFBoolean")]) {
                *outputValue = [inputValue boolValue] ? @"true" : @"false";
            } else {
                *outputValue = [inputValue stringValue];
            }
            return YES;
        }];

    });
    return transformer;
}

+ (instancetype)defaultNumberToDateTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSNumber class] destinationClass:[NSDate class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSDate dateWithTimeIntervalSince1970:[inputValue doubleValue]];
            return YES;
        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSNumber numberWithDouble:[inputValue timeIntervalSince1970]];
            return YES;
        }];

    });
    return transformer;
}

+ (instancetype)defaultOrderedSetToArrayTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSOrderedSet class] destinationClass:[NSArray class] transformationBlock:^BOOL(NSOrderedSet* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [inputValue array];
            return YES;
        } reverseTransformationBlock:^BOOL(NSArray* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSOrderedSet orderedSetWithArray:inputValue];
            return YES;
        }];
    });
    return transformer;
}

+ (instancetype)defaultSetToArrayTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSSet class] destinationClass:[NSArray class] transformationBlock:^BOOL(NSSet* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [inputValue allObjects];
            return YES;
        } reverseTransformationBlock:^BOOL(NSArray* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSSet setWithArray:inputValue];
            return YES;
        }];
    });
    return transformer;
}

+ (instancetype)defaultStringToDecimalNumberTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSString class] destinationClass:[NSDecimalNumber class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSDecimalNumber decimalNumberWithString:inputValue];
            return YES;
        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [inputValue stringValue];
            return YES;
        }];
    });
    return transformer;
}

+ (instancetype)defaultNumberToDecimalNumberTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSNumber class] destinationClass:[NSDecimalNumber class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSDecimalNumber decimalNumberWithDecimal:[inputValue decimalValue]];
            return YES;
        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = inputValue;
            return YES;
        }];
    });
    return transformer;
}

+ (instancetype)defaultObjectToDataTransformer
{
    static RKValueTransformer *transformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transformer = [self valueTransformerWithSourceClass:[NSObject class] destinationClass:[NSData class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            if (![inputValue conformsToProtocol:@protocol(NSCoding)]) {
                return NO;
            }
            *outputValue = [NSKeyedArchiver archivedDataWithRootObject:inputValue];
            return YES;
        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [NSKeyedUnarchiver unarchiveObjectWithData:inputValue];
            return YES;
        }];
    });
    return transformer;
}

- (instancetype)reverseTransformer
{
    RKValueTransformer *reverse = [[RKValueTransformer alloc] initWithSourceClass:self.destinationClass destinationClass:self.sourceClass transformationBlock:self.reverseTransformationBlock reverseTransformationBlock:self.transformationBlock];
    return reverse;
}

+ (instancetype)identityTransformer
{
    static RKValueTransformer *identityTransformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        identityTransformer = [RKIdentityValueTransformer valueTransformerWithSourceClass:[NSObject class] destinationClass:[NSObject class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = inputValue;
            return YES;
        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = inputValue;
            return YES;
        }];
    });
    return identityTransformer;
}

+ (instancetype)stringValueTransformer
{
    static RKValueTransformer *stringValueTransformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stringValueTransformer = [RKStringValueTransformer valueTransformerWithSourceClass:[NSObject class] destinationClass:[NSString class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [inputValue stringValue];
            return YES;
        } reverseTransformationBlock:nil];
    });
    return stringValueTransformer;
}

+ (instancetype)defaultNullTransformer
{
    static RKValueTransformer *nullTransformer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nullTransformer = [RKValueTransformer valueTransformerWithSourceClass:[NSNull class] destinationClass:[NSObject class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            if ([NSNull null] == inputValue) {
                *outputValue = nil;
            } else {
                *outputValue = inputValue;
            }
            return YES;
        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            if (nil == inputValue) {
                *outputValue = [NSNull null];
            } else {
                *outputValue = inputValue;
            }
            return YES;
        }];
    });
    return nullTransformer;
}

@end

// Implementation lives in RKObjectMapping.m at the moment
NSDate *RKDateFromStringWithFormatters(NSString *dateString, NSArray *formatters);

@implementation RKDateToStringValueTransformer

+ (Class)transformedValueClass
{
    return [NSDate class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (instancetype)dateToStringValueTransformerWithDateToStringFormatter:(NSFormatter *)dateToStringFormatter stringToDateFormatters:(NSArray *)stringToDateFormatters
{
    return [[self alloc] initWithDateToStringFormatter:dateToStringFormatter stringToDateFormatters:stringToDateFormatters];
}

- (id)initWithDateToStringFormatter:(NSFormatter *)dateToStringFormatter stringToDateFormatters:(NSArray *)stringToDateFormatters
{
    self = [super initWithSourceClass:[NSDate class] destinationClass:[NSString class] transformationBlock:nil reverseTransformationBlock:nil];
    if (self) {
        self.dateToStringFormatter = dateToStringFormatter;
        self.stringToDateFormatters = stringToDateFormatters;
        __weak id weakSelf = self;
        self.transformationBlock = ^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            RKDateToStringValueTransformer *strongSelf = weakSelf;
            NSCAssert(strongSelf.dateToStringFormatter, @"Cannot transform an `NSDate` to an `NSString`: dateToStringFormatter is nil");
            if (!strongSelf.dateToStringFormatter) return NO;
            @synchronized(strongSelf.dateToStringFormatter) {
                *outputValue = [strongSelf.dateToStringFormatter stringForObjectValue:inputValue];
            }
            return YES;
        };
        self.reverseTransformationBlock = ^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            RKDateToStringValueTransformer *strongSelf = weakSelf;
            NSCAssert(strongSelf.stringToDateFormatters, @"Cannot transform an `NSDate` to an `NSString`: stringToDateFormatters is nil");
            if (strongSelf.stringToDateFormatters.count <= 0) return NO;
            *outputValue = RKDateFromStringWithFormatters(inputValue, strongSelf.stringToDateFormatters);
            return YES;
        };
    }
    return self;
}

- (instancetype)reverseTransformer
{
    RKDateToStringValueTransformer *reverse = [[RKDateToStringValueTransformer alloc] initWithDateToStringFormatter:self.dateToStringFormatter stringToDateFormatters:self.stringToDateFormatters];
    reverse.destinationClass = self.sourceClass;
    reverse.sourceClass = self.destinationClass;
    reverse.transformationBlock = self.reverseTransformationBlock;
    reverse.reverseTransformationBlock = self.transformationBlock;
    return reverse;
}

- (id)init
{
    return [self initWithDateToStringFormatter:nil stringToDateFormatters:nil];
}

@end

BOOL RKIsMutableTypeTransformation(id value, Class destinationType);

@implementation RKIdentityValueTransformer

- (BOOL)canTransformClass:(Class)sourceClass toClass:(Class)destinationClass
{
    if (RKIsMutableTypeTransformation(nil, destinationClass)) {
        return [self canTransformClass:sourceClass toClass:[destinationClass superclass]];
    }
    if ([sourceClass isSubclassOfClass:destinationClass] || [destinationClass isSubclassOfClass:sourceClass]) return YES;
    else return NO;
}

@end

@implementation RKStringValueTransformer

- (BOOL)canTransformClass:(Class)sourceClass toClass:(Class)destinationClass
{
    if ([sourceClass instancesRespondToSelector:@selector(stringValue)]) return YES;
    return NO;
}

@end

static char const * const RKObjectMappingValueTransformersKey = "RKObjectMappingValueTransformersKey";

@implementation RKObjectMapping (ValueTransformers)

- (void)setValueTransformers:(NSArray *)valueTransformers
{
    objc_setAssociatedObject(self, RKObjectMappingValueTransformersKey, valueTransformers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)valueTransformers
{
    return objc_getAssociatedObject(self, RKObjectMappingValueTransformersKey);
}

@end

static char const * const RKPropertyMappingValueTransformersKey = "RKObjectMappingValueTransformersKey";

@implementation RKPropertyMapping (ValueTransformers)

- (void)setValueTransformers:(NSArray *)valueTransformers
{
    objc_setAssociatedObject(self, RKPropertyMappingValueTransformersKey, valueTransformers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)valueTransformers
{
    return objc_getAssociatedObject(self, RKPropertyMappingValueTransformersKey);
}

@end
