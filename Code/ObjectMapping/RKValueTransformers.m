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
    NSArray *array = _registry[NSStringFromClass(destinationClass)];
    if (!array) array = [NSArray array];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(RKValueTransformer *evaluatedObject, NSDictionary *bindings) {
        return [sourceClass isSubclassOfClass:evaluatedObject.sourceClass];
    }];
    array = [array filteredArrayUsingPredicate:predicate];
    if ([sourceClass isSubclassOfClass:destinationClass]) {
        array = [array arrayByAddingObject:[self identityTransformer]];
    }
    if ([sourceClass instancesRespondToSelector:@selector(stringValue)]) {
        array = [array arrayByAddingObject:[self stringValueTransformer]];
    }
    if ([sourceClass isSubclassOfClass:[NSNull class]]) {
        array = [array arrayByAddingObject:[self nullTransformer]];
    }
    return array;
}

- (BOOL)transformValue:(id)inputValue toValue:(__autoreleasing id *)outputValue error:(NSError *__autoreleasing *)error
{
    if ([inputValue class] == self.sourceClass && self.reverseTransformationBlock) {
        return self.reverseTransformationBlock(inputValue, outputValue, error);
    }
    return self.transformationBlock(inputValue, outputValue, error);
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
    RKValueTransformer *transformer = [self valueTransformerWithSourceClass:[NSString class] destinationClass:[NSURL class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
        *outputValue = [NSURL URLWithString:inputValue];
        return YES;
    } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
        *outputValue = [inputValue absoluteString];
        return YES;
    }];
    [self registerValueTransformer:transformer];
    RKValueTransformationBlock forwardBool = ^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
        *outputValue = [inputValue boolValue] ? @"true" : @"false";
        return YES;
    };
    transformer = [self valueTransformerWithSourceClass:NSClassFromString(@"NSCFBoolean") destinationClass:[NSString class] transformationBlock:forwardBool reverseTransformationBlock:nil];
    [self registerValueTransformer:transformer];
    transformer = [self valueTransformerWithSourceClass:NSClassFromString(@"__NSCFBoolean") destinationClass:[NSString class] transformationBlock:forwardBool reverseTransformationBlock:nil];
    [self registerValueTransformer:transformer];
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
    [self registerValueTransformer:transformer];
    transformer = [self valueTransformerWithSourceClass:[NSNumber class] destinationClass:[NSDate class] transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
        *outputValue = [NSDate dateWithTimeIntervalSince1970:[inputValue doubleValue]];
        return YES;
    } reverseTransformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
        *outputValue = [NSNumber numberWithDouble:[inputValue timeIntervalSince1970]];
        return YES;
    }];
    [self registerValueTransformer:transformer];
    transformer = [self valueTransformerWithSourceClass:[NSOrderedSet class] destinationClass:[NSArray class] transformationBlock:^BOOL(NSOrderedSet* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
        *outputValue = [inputValue array];
        return YES;
    } reverseTransformationBlock:^BOOL(NSArray* inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
        *outputValue = [NSOrderedSet orderedSetWithArray:inputValue];
        return YES;
    }];
    [self registerValueTransformer:transformer];
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
        identityTransformer = [RKValueTransformer valueTransformerWithSourceClass:nil destinationClass:nil transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
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

+ (instancetype)nullTransformer
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
    self = [super initWithSourceClass:[NSString class] destinationClass:[NSDate class] transformationBlock:nil reverseTransformationBlock:nil];
    if (self) {
        self.dateToStringFormatter = dateToStringFormatter;
        self.stringToDateFormatters = stringToDateFormatters;
        __weak id weakSelf = self;
        self.transformationBlock = ^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            RKDateToStringValueTransformer *strongSelf = weakSelf;
            if (strongSelf.stringToDateFormatters.count <= 0) return NO;
            *outputValue = RKDateFromStringWithFormatters(inputValue, strongSelf.stringToDateFormatters);
            return YES;
        };
        self.reverseTransformationBlock = ^BOOL(id inputValue, __autoreleasing id *outputValue, NSError *__autoreleasing *error) {
            RKDateToStringValueTransformer *strongSelf = weakSelf;
            if (!strongSelf.dateToStringFormatter) return NO;
            @synchronized(strongSelf.dateToStringFormatter) {
                *outputValue = [strongSelf.dateToStringFormatter stringForObjectValue:inputValue];
            }
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
