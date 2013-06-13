//
//  RKValueTransformers.h
//  RestKit
//
//  Created by Blake Watters on 11/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKPropertyMapping.h"
#import "RKObjectMapping.h"

typedef BOOL(^RKValueTransformationBlock)(id inputValue, id *outputValue, NSError **error);

@interface RKValueTransformer : NSValueTransformer

/// @name Creating a Value Transformer

+ (instancetype)valueTransformerWithSourceClass:(Class)sourceClass destinationClass:(Class)destinationClass transformationBlock:(RKValueTransformationBlock)transformationBlock reverseTransformationBlock:(RKValueTransformationBlock)reverseTransformationBlock;

/// @name Getting Information About a Transformer

@property (nonatomic, strong, readonly) Class sourceClass;
@property (nonatomic, strong, readonly) Class destinationClass;
@property (nonatomic, readonly) NSString *name; // Built by concatenating the source and destination classes... i.e. `RKNSStringToNSDateValueTransformer`. Useful for registering with the `NSValueTransformer` name based registry.

/// @name Using the Class-based Registry

+ (void)registerValueTransformer:(RKValueTransformer *)valueTransformer;
+ (void)unregisterValueTransformer:(RKValueTransformer *)valueTransformer;
+ (NSArray *)valueTransformersForTransformingFromClass:(Class)sourceClass toClass:(Class)destinationClass; // Returns an array so you can register more than one for a given pair

/// @name Transforming a Value

- (BOOL)transformValue:(id)inputValue toValue:(id *)outputValue error:(NSError **)error; // Mapper will always use this interface instead of NSValueTransformer

/// @name Default Transformers

+ (instancetype)defaultStringToURLTransformer;
+ (NSArray *)defaultBooleanToStringTransformers;
+ (instancetype)defaultStringToNumberTransformer;
+ (instancetype)defaultNumberToDateTransformer;
+ (instancetype)defaultOrderedSetToArrayTransformer;
+ (instancetype)defaultSetToArrayTransformer;
+ (instancetype)defaultStringToDecimalNumberTransformer;
+ (instancetype)defaultNumberToDecimalNumberTransformer;
+ (instancetype)defaultObjectToDataTransformer;
+ (instancetype)defaultNullTransformer;

@end

@interface RKPropertyMapping (ValueTransformers)

/**
 An array of value transformers to consult when mapping the property. `nil` indicates that all transformers registered will be consulted. If set, each one gets a cut at the value, in order.
 */
@property (nonatomic, strong) NSArray *valueTransformers;

@end

@interface RKObjectMapping (ValueTransformers)

@property (nonatomic, strong) NSArray *valueTransformers; // Same as above

@end

@interface RKDateToStringValueTransformer : RKValueTransformer

@property (nonatomic, copy) NSFormatter *dateToStringFormatter;
@property (nonatomic, copy) NSArray *stringToDateFormatters;

+ (instancetype)dateToStringValueTransformerWithDateToStringFormatter:(NSFormatter *)dateToStringFormatter stringToDateFormatters:(NSArray *)stringToDateFormatters;

@end
