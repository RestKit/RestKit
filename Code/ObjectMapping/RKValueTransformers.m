//
//  RKValueTransformers.m
//  RestKit
//
//  Created by Blake Watters on 11/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKValueTransformers.h"
#import "RKMacros.h"
#import "RKLog.h"
#import "RKErrors.h"

@interface RKValueTransformer ()
@property (nonatomic, copy) BOOL (^validationBlock)(Class, Class);
@property (nonatomic, copy) BOOL (^transformationBlock)(id, id *, Class, NSError **);
@end

@implementation RKValueTransformer

+ (instancetype)valueTransformerWithValidationBlock:(BOOL (^)(Class sourceClass, Class destinationClass))validationBlock
                                transformationBlock:(BOOL (^)(id inputValue, id *outputValue, Class outputClass, NSError **error))transformationBlock
{
    if (! transformationBlock) [NSException raise:NSInvalidArgumentException format:@"The `transformationBlock` cannot be `nil`."];
    RKValueTransformer *valueTransformer = [self new];
    valueTransformer.validationBlock = validationBlock;
    valueTransformer.transformationBlock = transformationBlock;
    return valueTransformer;
}

- (BOOL)transformValue:(id)inputValue toValue:(__autoreleasing id *)outputValue ofClass:(Class)outputValueClass error:(NSError *__autoreleasing *)error
{
    return self.transformationBlock(inputValue, outputValue, outputValueClass, error);
}

- (BOOL)validateTransformationFromClass:(Class)sourceClass toClass:(Class)destinationClass
{
    if (self.validationBlock) return self.validationBlock(sourceClass, destinationClass);
    else return YES;
}

#pragma mark Default Transformers

+ (instancetype)singletonValueTransformer:(RKValueTransformer * __strong *)valueTransformer
                                onceToken:(dispatch_once_t *)onceToken
                                       validationBlock:(BOOL (^)(Class sourceClass, Class destinationClass))validationBlock
                                   transformationBlock:(BOOL (^)(id inputValue, id *outputValue, Class outputValueClass, NSError **error))transformationBlock
{
    dispatch_once(onceToken, ^{
        *valueTransformer = [RKValueTransformer valueTransformerWithValidationBlock:validationBlock transformationBlock:transformationBlock];
    });
    return *valueTransformer;
}

+ (instancetype)stringToURLValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSURL class]]) ||
                ([sourceClass isSubclassOfClass:[NSURL class]] && [destinationClass isSubclassOfClass:[NSString class]]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSString class], [NSURL class]]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSString class], [NSURL class]]), error);
        if ([inputValue isKindOfClass:[NSString class]]) {
            NSURL *URL = [NSURL URLWithString:inputValue];
            RKValueTransformerTestTransformation(URL != nil, error, @"Failed transformation of '%@' to URL: the string is malformed and cannot be transformed to an `NSURL` representation.", inputValue);
            *outputValue = URL;
        } else if ([inputValue isKindOfClass:[NSURL class]]) {
            *outputValue = [(NSURL *)inputValue absoluteString];
        }
        return YES;
    }];
}

+ (instancetype)numberToStringValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass isSubclassOfClass:[NSNumber class]] && [destinationClass isSubclassOfClass:[NSString class]]) ||
                ([sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSNumber class]]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSNumber class], [NSString class] ]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSNumber class], [NSString class]]), error);
        if ([inputValue isKindOfClass:[NSString class]]) {
            NSString *lowercasedString = [inputValue lowercaseString];
            NSSet *trueStrings = [NSSet setWithObjects:@"true", @"t", @"yes", @"y", nil];
            NSSet *booleanStrings = [trueStrings setByAddingObjectsFromSet:[NSSet setWithObjects:@"false", @"f", @"no", @"n", nil]];
            if ([booleanStrings containsObject:lowercasedString]) {
                // Handle booleans encoded as Strings
                *outputValue = [NSNumber numberWithBool:[trueStrings containsObject:lowercasedString]];
            } else if ([lowercasedString rangeOfString:@"."].location != NSNotFound) {
                // String -> Floating Point Number
                // Only use floating point if needed to avoid losing precision on large integers
                *outputValue = [NSNumber numberWithDouble:[lowercasedString doubleValue]];
            } else {
                // String -> Signed Integer
                *outputValue = [NSNumber numberWithLongLong:[lowercasedString longLongValue]];
            }
        } else if ([inputValue isKindOfClass:[NSNumber class]]) {
            if (NSClassFromString(@"__NSCFBoolean") && [inputValue isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
                *outputValue = [inputValue boolValue] ? @"true" : @"false";
            } else if (NSClassFromString(@"NSCFBoolean") && [inputValue isKindOfClass:NSClassFromString(@"NSCFBoolean")]) {
                *outputValue = [inputValue boolValue] ? @"true" : @"false";
            } else {
                *outputValue = [inputValue stringValue];
            }
        }
        return YES;
    }];
}

+ (instancetype)dateToNumberValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass isSubclassOfClass:[NSNumber class]] && [destinationClass isSubclassOfClass:[NSDate class]]) ||
                ([sourceClass isSubclassOfClass:[NSDate class]] && [destinationClass isSubclassOfClass:[NSNumber class]]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSNumber class], [NSDate class]]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSNumber class], [NSDate class]]), error);
        if ([inputValue isKindOfClass:[NSNumber class]]) {
            *outputValue = [NSDate dateWithTimeIntervalSince1970:[inputValue doubleValue]];
        } else if ([inputValue isKindOfClass:[NSDate class]]) {
            *outputValue = [NSNumber numberWithDouble:[inputValue timeIntervalSince1970]];
        }
        return YES;
    }];
}

+ (instancetype)arrayToOrderedSetValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass isSubclassOfClass:[NSArray class]] && [destinationClass isSubclassOfClass:[NSOrderedSet class]]) ||
                ([sourceClass isSubclassOfClass:[NSOrderedSet class]] && [destinationClass isSubclassOfClass:[NSArray class]]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSArray class], [NSOrderedSet class]]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSArray class], [NSOrderedSet class]]), error);
        if ([inputValue isKindOfClass:[NSArray class]]) {
            *outputValue = [NSOrderedSet orderedSetWithArray:inputValue];
        } else if ([inputValue isKindOfClass:[NSOrderedSet class]]) {
            *outputValue = [inputValue array];
        }
        return YES;
    }];
}

+ (instancetype)arrayToSetValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass isSubclassOfClass:[NSArray class]] && [destinationClass isSubclassOfClass:[NSSet class]]) ||
                ([sourceClass isSubclassOfClass:[NSSet class]] && [destinationClass isSubclassOfClass:[NSArray class]]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSSet class], [NSArray class]]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSSet class], [NSArray class]]), error);
        if ([inputValue isKindOfClass:[NSArray class]]) {
            *outputValue = [NSSet setWithArray:inputValue];
        } else if ([inputValue isKindOfClass:[NSSet class]]) {
            *outputValue = [inputValue allObjects];
        }
        return YES;
    }];
}

+ (instancetype)decimalNumberToStringValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass isSubclassOfClass:[NSDecimalNumber class]] && [destinationClass isSubclassOfClass:[NSString class]]) ||
                ([sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSDecimalNumber class]]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSString class], [NSDecimalNumber class]]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSString class], [NSDecimalNumber class]]), error);
        if ([inputValue isKindOfClass:[NSString class]]) {
            NSDecimalNumber *decimalNumber = [NSDecimalNumber decimalNumberWithString:inputValue];
            RKValueTransformerTestTransformation(! [decimalNumber isEqual:[NSDecimalNumber notANumber]], error, @"Failed transformation of '%@' to `NSDecimalNumber`: the input string was transformed into Not a Number (NaN) value.", inputValue);
            *outputValue = decimalNumber;
        } else if ([inputValue isKindOfClass:[NSDecimalNumber class]]) {
            *outputValue = [inputValue stringValue];
        }
        return YES;
    }];
}

+ (instancetype)decimalNumberToNumberValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass isSubclassOfClass:[NSDecimalNumber class]] && [destinationClass isSubclassOfClass:[NSNumber class]]) ||
                ([sourceClass isSubclassOfClass:[NSNumber class]] && [destinationClass isSubclassOfClass:[NSDecimalNumber class]]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSNumber class], [NSDecimalNumber class]]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSNumber class], [NSDecimalNumber class]]), error);
        if ([inputValue isKindOfClass:[NSNumber class]]) {
            *outputValue = [NSDecimalNumber decimalNumberWithDecimal:[inputValue decimalValue]];
        } else if ([inputValue isKindOfClass:[NSDecimalNumber class]]) {
            *outputValue = inputValue;
        }
        return YES;
    }];
}

+ (instancetype)nullValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:nil transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, [NSNull class], error);
        *outputValue = nil;
        return YES;
    }];
}

+ (instancetype)keyedArchivingValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return (([sourceClass conformsToProtocol:@protocol(NSCoding)] && [destinationClass isSubclassOfClass:[NSData class]]) ||
                ([sourceClass isSubclassOfClass:[NSData class]] && [destinationClass conformsToProtocol:@protocol(NSCoding)]));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        if ([inputValue isKindOfClass:[NSData class]]) {
            id unarchivedValue = nil;
            @try {
                unarchivedValue = [NSKeyedUnarchiver unarchiveObjectWithData:inputValue];
            }
            @catch (NSException *exception) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"An `%@` exception was encountered while attempting to unarchive the given inputValue.", [exception name]], @"exception": exception };
                *error = [NSError errorWithDomain:RKErrorDomain code:RKValueTransformationErrorTransformationFailed userInfo:userInfo];
                return NO;
            }
            if (! [unarchivedValue isKindOfClass:outputValueClass]) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Expected an `outputValueClass` of type `%@`, but the unarchived object is a `%@`.", outputValueClass, [unarchivedValue class]] };
                *error = [NSError errorWithDomain:RKErrorDomain code:RKValueTransformationErrorTransformationFailed userInfo:userInfo]; \
                return NO;
            }
            *outputValue = unarchivedValue;
        } else if ([inputValue conformsToProtocol:@protocol(NSCoding)]) {
            RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, [NSData class], error);
            *outputValue = [NSKeyedArchiver archivedDataWithRootObject:inputValue];
        } else {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Expected an `inputValue` of type `NSData` or conforming to `NSCoding`, but got a `%@` which does not satisfy these expectation.", [inputValue class]] };
            *error = [NSError errorWithDomain:RKErrorDomain code:RKValueTransformationErrorUntransformableInputValue userInfo:userInfo];
            return NO;
        }
        return YES;
    }];
}

+ (instancetype)timeIntervalSince1970ToDateValueTransformer
{
    static dispatch_once_t onceToken;
    static RKValueTransformer *valueTransformer;
    return [self singletonValueTransformer:&valueTransformer onceToken:&onceToken validationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return ((([sourceClass isSubclassOfClass:[NSString class]] || [sourceClass isSubclassOfClass:[NSNumber class]]) && [destinationClass isSubclassOfClass:[NSDate class]]) ||
                ([sourceClass isSubclassOfClass:[NSDate class]] && ([destinationClass isSubclassOfClass:[NSNumber class]] || [destinationClass isSubclassOfClass:[NSString class]])));
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputValueClass, NSError *__autoreleasing *error) {
        static dispatch_once_t onceToken;
        static NSNumberFormatter *numberFormatter;
        dispatch_once(&onceToken, ^{
            numberFormatter = [NSNumberFormatter new];
            numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        });
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSNumber class], [NSString class], [NSDate class] ]), error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSNumber class], [NSString class], [NSDate class] ]), error);
        if ([outputValueClass isSubclassOfClass:[NSDate class]]) {
            if ([inputValue isKindOfClass:[NSNumber class]]) {
                *outputValue = [NSDate dateWithTimeIntervalSince1970:[inputValue doubleValue]];
            } else if ([inputValue isKindOfClass:[NSString class]]) {
                NSString *errorDescription = nil;
                NSNumber *formattedNumber;
                BOOL success = [numberFormatter getObjectValue:&formattedNumber forString:inputValue errorDescription:&errorDescription];
                RKValueTransformerTestTransformation(success, error, @"%@", errorDescription);
                *outputValue = [NSDate dateWithTimeIntervalSince1970:[formattedNumber doubleValue]];
            }
        } else if ([outputValueClass isSubclassOfClass:[NSNumber class]]) {
            *outputValue = @([inputValue timeIntervalSince1970]);
        } else if ([outputValueClass isSubclassOfClass:[NSString class]]) {
            *outputValue = [numberFormatter stringForObjectValue:@([inputValue timeIntervalSince1970])];
        }
        return YES;
    }];
}

+ (RKCompoundValueTransformer *)defaultValueTransformer
{
    return nil;
}

@end

@interface RKCompoundValueTransformer ()
@property (nonatomic, strong) NSMutableArray *valueTransformers;
@end

@implementation RKCompoundValueTransformer

+ (instancetype)compoundValueTransformerWithValueTransformers:(NSArray *)valueTransformers
{
    for (id<RKValueTransforming> valueTransformer in valueTransformers) {
        if (! [valueTransformer conformsToProtocol:@protocol(RKValueTransforming)]) {
            [NSException raise:NSInvalidArgumentException format:@"All objects in the given `valueTransformers` collection must conform to the `RKValueTransforming` protocol."];
        }
    }
    RKCompoundValueTransformer *valueTransformer = [self new];
    valueTransformer.valueTransformers = [valueTransformers mutableCopy];
    return valueTransformer;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.valueTransformers = [NSMutableArray new];
    }
    return self;
}

- (void)addValueTransformer:(id<RKValueTransforming>)valueTransformer
{
    if (! valueTransformer) [NSException raise:NSInvalidArgumentException format:@"Cannot add `nil` to a compound transformer."];
    [self.valueTransformers addObject:valueTransformer];
}

- (void)removeValueTransformer:(id<RKValueTransforming>)valueTransformer
{
    if (! valueTransformer) [NSException raise:NSInvalidArgumentException format:@"Cannot remove `nil` from a compound transformer."];
    [self.valueTransformers removeObject:valueTransformer];
}

- (void)insertValueTransformer:(id<RKValueTransforming>)valueTransformer atIndex:(NSUInteger)index
{
    if (! valueTransformer) [NSException raise:NSInvalidArgumentException format:@"Cannot insert `nil` into a compound transformer."];
    [self.valueTransformers insertObject:valueTransformer atIndex:index];
}

- (NSUInteger)numberOfValueTransformers
{
    return [self.valueTransformers count];
}

- (NSArray *)valueTransformersForTransformingFromClass:(Class)sourceClass toClass:(Class)destinationClass
{
    if (sourceClass == Nil && destinationClass == Nil) return [self.valueTransformers copy];
    else if (sourceClass == Nil || destinationClass == Nil) [NSException raise:NSInvalidArgumentException format:@"If you specify a source or destination class then you must specify both."];
    NSMutableArray *matchingTransformers = [NSMutableArray arrayWithCapacity:[self.valueTransformers count]];
    for (RKValueTransformer *valueTransformer in self) {
        if (! [valueTransformer respondsToSelector:@selector(validateTransformationFromClass:toClass:)]
            || [valueTransformer validateTransformationFromClass:sourceClass toClass:destinationClass]) {
            [matchingTransformers addObject:valueTransformer];
        }
    }
    return [matchingTransformers copy];
}

#pragma mark RKValueTransforming

- (BOOL)transformValue:(id)inputValue toValue:(__autoreleasing id *)outputValue ofClass:(__unsafe_unretained Class)outputValueClass error:(NSError *__autoreleasing *)error
{
    NSArray *matchingTransformers = [self valueTransformersForTransformingFromClass:[inputValue class] toClass:outputValueClass];
    NSMutableArray *errors = [NSMutableArray array];
    NSError *underlyingError = nil;
    for (id<RKValueTransforming> valueTransformer in matchingTransformers) {
        BOOL success = [valueTransformer transformValue:inputValue toValue:outputValue ofClass:outputValueClass error:&underlyingError];
        if (success) return YES;
        else [errors addObject:underlyingError];
    }
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed transformation of value '%@' to %@: none of the %d value transformers consulted were successful.", inputValue, outputValueClass, [matchingTransformers count]], RKDetailedErrorsKey: errors };
    *error = [NSError errorWithDomain:RKErrorDomain code:RKValueTransformationErrorTransformationFailed userInfo:userInfo];
    return NO;
}

- (BOOL)validateTransformationFromClass:(Class)sourceClass toClass:(Class)destinationClass
{
    return [[self valueTransformersForTransformingFromClass:sourceClass toClass:destinationClass] count] > 0;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    RKCompoundValueTransformer *compoundValueTransformer = [[[self class] allocWithZone:zone] init];
    compoundValueTransformer.valueTransformers = [self.valueTransformers mutableCopy];
    return compoundValueTransformer;
}

#pragma mark NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [self.valueTransformers countByEnumeratingWithState:state objects:buffer count:len];
}

@end

//
//// Set up the built-in transformers
//+ (void)initialize
//{
//    [super initialize];
//    if ([RKValueTransformer class] != self) return;
//    [[self defaultStringToURLTransformer] _register];
//    [[self defaultStringToNumberTransformer] _register];


//    [[self defaultNumberToDateTransformer] _register];
//    [[self defaultOrderedSetToArrayTransformer] _register];
//    [[self defaultSetToArrayTransformer] _register];
//    [[self defaultStringToDecimalNumberTransformer] _register];
//    [[self defaultNumberToDecimalNumberTransformer] _register];
//    [[self defaultObjectToDataTransformer] _register];
//    [[self defaultNullTransformer] _register];
//    [[self identityTransformer] _register];
//}
//
//
//+ (instancetype)identityTransformer
//{
//    static RKValueTransformer *identityTransformer;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        identityTransformer = [RKIdentityValueTransformer valueTransformerWithSourceClass:[NSObject class] destinationClass:[NSObject class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
//            *outputValue = inputValue;
//            return YES;
//        } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
//            *outputValue = inputValue;
//            return YES;
//        }];
//    });
//    return identityTransformer;
//}
//
//+ (instancetype)stringValueTransformer
//{
//    static RKValueTransformer *stringValueTransformer;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        stringValueTransformer = [RKStringValueTransformer valueTransformerWithSourceClass:[NSObject class] destinationClass:[NSString class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
//            *outputValue = [inputValue stringValue];
//            return YES;
//        } reverseTransformationBlock:nil];
//    });
//    return stringValueTransformer;
//}
//
//@end

@implementation NSNumberFormatter (RKValueTransformers)

- (BOOL)validateTransformationFromClass:(Class)inputValueClass toClass:(Class)outputValueClass
{
    return (([inputValueClass isSubclassOfClass:[NSNumber class]] && [outputValueClass isSubclassOfClass:[NSString class]]) ||
            ([inputValueClass isSubclassOfClass:[NSString class]] && [outputValueClass isSubclassOfClass:[NSNumber class]]));
}

- (BOOL)transformValue:(id)inputValue toValue:(id *)outputValue ofClass:(Class)outputValueClass error:(NSError **)error
{
    RKValueTransformerTestInputValueIsKindOfClass(inputValue, (@[ [NSString class], [NSNumber class] ]), error);
    RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, (@[ [NSString class], [NSNumber class] ]), error);
    if ([inputValue isKindOfClass:[NSString class]]) {
        NSString *errorDescription = nil;
        BOOL success = [self getObjectValue:outputValue forString:inputValue errorDescription:&errorDescription];
        RKValueTransformerTestTransformation(success, error, @"%@", errorDescription);
    } else if ([inputValue isKindOfClass:[NSNumber class]]) {
        *outputValue = [self stringFromNumber:inputValue];
    }
    return YES;
}

@end

@implementation RKDateToStringValueTransformer
@end
