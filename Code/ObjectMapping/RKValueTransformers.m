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

@implementation RKValueTransformer

static NSMutableDictionary *_registry;
static NSMutableDictionary *_reverseRegistry;

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
    NSArray *array = [NSArray array], *reverseArray = [NSArray array];
    Class currentClass = destinationClass;
    do {
       array = [array arrayByAddingObjectsFromArray:_registry[NSStringFromClass(currentClass)]];
       reverseArray = [reverseArray arrayByAddingObjectsFromArray:_reverseRegistry[NSStringFromClass(currentClass)]];
    } while ((currentClass = [currentClass superclass]));
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(RKValueTransformer *evaluatedObject, NSDictionary *bindings) {
        return [sourceClass isSubclassOfClass:evaluatedObject.sourceClass];
    }];
    NSPredicate *reversePredicate = [NSPredicate predicateWithBlock:^BOOL(RKValueTransformer *evaluatedObject, NSDictionary *bindings) {
        return [sourceClass isSubclassOfClass:evaluatedObject.destinationClass];
    }];
    array = [array filteredArrayUsingPredicate:predicate];
    reverseArray = [reverseArray filteredArrayUsingPredicate:reversePredicate];
    array = [array arrayByAddingObjectsFromArray:reverseArray];
    if ([sourceClass isSubclassOfClass:destinationClass]) {
        array = [array arrayByAddingObject:[self identityTransformer]];
    }
    if (destinationClass == [NSString class] && [sourceClass instancesRespondToSelector:@selector(stringValue)]) {
        array = [array arrayByAddingObject:[self stringValueTransformer]];
    }
    if ([sourceClass isSubclassOfClass:[NSNull class]]) {
        array = [array arrayByAddingObject:[self defaultNullTransformer]];
    }
    return array;
}

- (BOOL)transformValue:(id)inputValue toValue:(id *)outputValue error:(NSError **)error
{
    if ([inputValue class] == self.destinationClass && self.reverseTransformationBlock) {
        return self.reverseTransformationBlock(inputValue, outputValue, error);
    }
    return self.transformationBlock(inputValue, outputValue, error);
}

- (void)_register
{
    [RKValueTransformer registerValueTransformer:self];
}

+ (void)registerValueTransformer:(RKValueTransformer *)valueTransformer
{
    NSMutableArray *array = _registry[NSStringFromClass(valueTransformer.destinationClass)];
    NSMutableArray *reverseArray;
    if (valueTransformer.sourceClass && valueTransformer.reverseTransformationBlock) {
        reverseArray = _reverseRegistry[NSStringFromClass(valueTransformer.sourceClass)];
    }
    if (!array) {
        array = [NSMutableArray array];
        _registry[NSStringFromClass(valueTransformer.destinationClass)] = array;
    }
    if (!reverseArray) {
        reverseArray = [NSMutableArray array];
        _reverseRegistry[NSStringFromClass(valueTransformer.sourceClass)] = reverseArray;
    }
    [array insertObject:valueTransformer atIndex:0];
    [reverseArray insertObject:valueTransformer atIndex:0];
}

+ (void)unregisterValueTransformer:(RKValueTransformer *)valueTransformer
{
    NSMutableArray *array = _registry[NSStringFromClass(valueTransformer.destinationClass)];
    NSMutableArray *reverseArray;
    if (valueTransformer.sourceClass) {
        reverseArray = _reverseRegistry[NSStringFromClass(valueTransformer.sourceClass)];
    }
    [array removeObject:valueTransformer];
    [reverseArray removeObject:valueTransformer];
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
    _registry = [NSMutableDictionary dictionary];
    _reverseRegistry = [NSMutableDictionary dictionary];
    [[self defaultStringToURLTransformer] _register];
    for (RKValueTransformer *transformer in [self defaultBooleanToStringTransformers]) {
        [transformer _register];
    }
    [[self defaultStringToNumberTransformer] _register];
    [[self defaultNumberToDateTransformer] _register];
    [[self defaultOrderedSetToArrayTransformer] _register];
    [[self defaultSetToArrayTransformer] _register];
    [[self defaultStringToDecimalNumberTransformer] _register];
    [[self defaultNumberToDecimalNumberTransformer] _register];
    [[self defaultObjectToDataTransformer] _register];
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

+ (NSArray *)defaultBooleanToStringTransformers
{
    static NSArray *transformers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *_transformers;
        RKValueTransformationBlock forwardBool = ^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            *outputValue = [inputValue boolValue] ? @"true" : @"false";
            return YES;
        };
        RKValueTransformer *transformer1;
        if (NSClassFromString(@"NSCFBoolean")) {
            transformer1 = [self valueTransformerWithSourceClass:NSClassFromString(@"NSCFBoolean") destinationClass:[NSString class] transformationBlock:forwardBool reverseTransformationBlock:nil];
            [_transformers addObject:transformer1];
        }
        RKValueTransformer *transformer2;
        if (NSClassFromString(@"__NSCFBoolean")) {
            transformer2 = [self valueTransformerWithSourceClass:NSClassFromString(@"__NSCFBoolean") destinationClass:[NSString class] transformationBlock:forwardBool reverseTransformationBlock:nil];
            [_transformers addObject:transformer2];
        }
        transformers = [NSArray arrayWithArray:_transformers];
    });
    return transformers;
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
            *outputValue = [inputValue stringValue];
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
        identityTransformer = [RKValueTransformer valueTransformerWithSourceClass:[NSObject class] destinationClass:[NSObject class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
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
        stringValueTransformer = [RKValueTransformer valueTransformerWithSourceClass:nil destinationClass:[NSString class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
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
            NSAssert(self.dateToStringFormatter, @"Cannot transform an `NSDate` to an `NSString`: dateToStringFormatter is nil");
            RKAssertValueIsKindOfClass(inputValue, [NSDate class]);
            RKDateToStringValueTransformer *strongSelf = weakSelf;
            if (!strongSelf.dateToStringFormatter) return NO;
            @synchronized(strongSelf.dateToStringFormatter) {
                *outputValue = [strongSelf.dateToStringFormatter stringForObjectValue:inputValue];
            }
            return YES;
        };
        self.reverseTransformationBlock = ^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            NSAssert(self.stringToDateFormatters, @"Cannot transform an `NSDate` to an `NSString`: stringToDateFormatters is nil");
            RKAssertValueIsKindOfClass(inputValue, [NSString class]);
            RKDateToStringValueTransformer *strongSelf = weakSelf;
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
