//
//  RKParameterConstraint.h
//  RestKit
//
//  Created by Blake Watters on 11/25/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const RKRequiredParametersKey;
extern NSString *const RKOptionalParametersKey;

/**
 Values can be:
 1. Exact string
 2. Array|Set of strings specifying values
 3. NSRegularExpression matching values
 */
@interface RKParameterConstraint : NSObject <NSCopying, NSCoding>

/**
 Example:

 NSDictionary *constraintsDictionary = @{ @"action": @[ @"search", @"browse"],
 @"user_id": [NSRegularExpression regularExpressionWithPattern:@"[\d]+" options:0 error:nil]
 RKOptionalParametersKey: @[ @"category_id" ],
 RKRequiredParametersKey: @"store_id" };
 [RKParameterConstraint constraintsWithDictionary:constraintsDictionary];
 */
+ (NSArray *)constraintsWithDictionary:(NSDictionary *)constraintsDictionary;

// parameters must be a dictionary of string keys and values
+ (BOOL)areConstraints:(NSArray *)constraints satisfiedByParameters:(NSDictionary *)parameters;

/**
 The name of the parameter being constrained.
 */
@property (nonatomic, copy, readonly) NSString *parameter;

/**
 A Boolean value indicating if the parameter must be present for
 */
@property (nonatomic, assign, getter = isRequired) BOOL required; // does it make more sense to have optional / isOptional?

/**
 Evaluates the given dictionary of parameters against the receiver and returns a Boolean value indicating if the constraint is satisfied.

 @param parameters A dictionary of parameters to
 */
- (BOOL)satisfiedByParameters:(NSDictionary *)parameters;

@end
