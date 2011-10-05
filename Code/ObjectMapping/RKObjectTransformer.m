//
//  RKObjectTransformer.m
//  RestKit
//
//  Created by John Earl on 26/09/2011.
//  Copyright 2011 Airsource Ltd. All rights reserved.
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

#import "RKObjectTransformer.h"
#import "RKObjectMapping.h"
#import "../Support/RKLog.h"
#import "../Support/Errors.h"

@implementation RKDefaultTransformer
@synthesize objectMapping=_objectMapping;


+(RKDefaultTransformer*)transformerWithObjectMapping:(RKObjectMapping*)mapping
{
    RKDefaultTransformer* t = [[self new] autorelease];
    t.objectMapping = mapping;
    return t;
}

- (NSDate*)parseDateFromString:(NSString*)string {
    RKLogTrace(@"Transforming string value '%@' to NSDate...", string);
    
	NSDate* date = nil;
    for (NSDateFormatter *dateFormatter in self.objectMapping.dateFormatters) {
        @synchronized(dateFormatter) {
            date = [dateFormatter dateFromString:string];
        }
        if (date) {
			break;
		}
    }
    
    return date;
}


/**
 * Report whether the transformer supports conversion to the specified type.
 *
 */
-(BOOL)canTransformToClass:(Class)destinationType
{
    return ([destinationType isSubclassOfClass:[NSDate class]] ||
            [destinationType isSubclassOfClass:[NSURL class]] ||
            [destinationType isSubclassOfClass:[NSNumber class]] ||
            [destinationType isSubclassOfClass:[NSSet class]] ||
            [destinationType isSubclassOfClass:[NSArray class]] ||
            [destinationType isSubclassOfClass:[NSString class]]);
}

-(id)transformedValue:(id)value ofClass:(Class)destinationType error:(NSError**)error
{
    Class sourceType = [value class];
    
    if (error)
    {
        *error = nil;
    }
    if ([sourceType isSubclassOfClass:[NSString class]]) {
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            // String -> Date
            return [self parseDateFromString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSURL class]]) {
            // String -> URL
            return [NSURL URLWithString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSDecimalNumber class]]) {
            // String -> Decimal Number
            return [NSDecimalNumber decimalNumberWithString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSNumber class]]) {
            // String -> Number
            NSString* lowercasedString = [(NSString*)value lowercaseString];
            NSSet* trueStrings = [NSSet setWithObjects:@"true", @"t", @"yes", nil];
            NSSet* booleanStrings = [trueStrings setByAddingObjectsFromSet:[NSSet setWithObjects:@"false", @"f", @"no", nil]];
            if ([booleanStrings containsObject:lowercasedString]) {
                // Handle booleans encoded as Strings
                return [NSNumber numberWithBool:[trueStrings containsObject:lowercasedString]];
            } else {
                return [NSNumber numberWithDouble:[(NSString*)value doubleValue]];
            }
        }
    } else if (value == [NSNull null] || [value isEqual:[NSNull null]]) {
        // Transform NSNull -> nil for simplicity
        return nil;
    } else if ([sourceType isSubclassOfClass:[NSSet class]]) {
        // Set -> Array
        if ([destinationType isSubclassOfClass:[NSArray class]]) {
            return [(NSSet*)value allObjects];
        }
    } else if ([sourceType isSubclassOfClass:[NSArray class]]) {
        // Array -> Set
        if ([destinationType isSubclassOfClass:[NSSet class]]) {
            return [NSSet setWithArray:value];
        }
    } else if ([sourceType isSubclassOfClass:[NSNumber class]] && [destinationType isSubclassOfClass:[NSDate class]]) {
        // Number -> Date
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber*)value intValue]];
    } else if ([sourceType isSubclassOfClass:[NSNumber class]] && [destinationType isSubclassOfClass:[NSDecimalNumber class]]) {
        // Number -> Decimal Number
        return [NSDecimalNumber decimalNumberWithDecimal:[value decimalValue]];
    } else if ( ([sourceType isSubclassOfClass:NSClassFromString(@"__NSCFBoolean")] ||
                 [sourceType isSubclassOfClass:NSClassFromString(@"NSCFBoolean")] ) &&
               [destinationType isSubclassOfClass:[NSString class]]) {
        return ([value boolValue] ? @"true" : @"false");
    } else if ([destinationType isSubclassOfClass:[NSString class]] && [value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    } else if ([destinationType isSubclassOfClass:[NSString class]] && [value isKindOfClass:[NSDate class]]) {
        // NSDate -> NSString
        // Transform using the preferred date formatter
        NSString* dateString = nil;
        @synchronized(self.objectMapping.preferredDateFormatter) {
            dateString = [self.objectMapping.preferredDateFormatter stringFromDate:value];
        }
        return dateString;
    }
    
    if (error)
    {
        *error = [NSError errorWithDomain:RKRestKitErrorDomain 
                                     code:RKObjectLoaderNoValidValueTransformationError
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSString stringWithFormat:@"No strategy for transforming from '%@' to '%@'", 
                                            NSStringFromClass([value class]),
                                            NSStringFromClass(destinationType)], NSLocalizedDescriptionKey, nil]];
    }
    return nil;
}


/**
 * Inverse of this transformer, or nil if the transform is not invertible
 */
-(id<RKObjectTransformer>)inverseTransformer
{
    return self;
}

-(void)dealloc
{
    self.objectMapping = nil;
    [super dealloc];
}

@end

@implementation RKOneToOneObjectTransformer
@synthesize transformDictionary = _transformDictionary;

-(id)initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    self.transformDictionary = dictionary;
    return self;
}


-(void)dealloc
{
    self.transformDictionary = nil;
    [super dealloc];
}

/**
 * Report whether the transformer supports conversion to the specified type.
 *
 */
-(BOOL)canTransformToClass:(Class)destinationType
{
    return YES;
}

/**
 * Transform a value
 */
-(id)transformedValue:(id)value ofClass:(Class)destinationType error:(NSError**)error
{
    if (error)
    {
        *error = nil;
    }
    id obj = [_transformDictionary objectForKey:value];
    if ([obj isKindOfClass:destinationType])
    {
        return obj;
    }
    return nil;
}

/**
 * Provide a transformer object that supports the inverse operation
 */
-(id<RKObjectTransformer>)inverseTransformer
{
    NSDictionary *d = [self transformDictionary];
    NSArray *keys = [d allKeys];
    NSMutableDictionary *inverseDictionary = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
    for (id k in keys)
    {
        id v = [d objectForKey:k];
        if ([inverseDictionary objectForKey:v])
        {
            // Non-invertible transform
            RKLogWarning(@"Not able to invert transform with duplicate value: %@", v);
            return nil;
        }
        [inverseDictionary setObject:k forKey:v];
    }
    return [RKOneToOneObjectTransformer transformerWithDictionary:inverseDictionary];
}


+(RKOneToOneObjectTransformer*)transformerWithDictionary:(NSDictionary*)dictionary
{
    return [[[self alloc] initWithDictionary:dictionary] autorelease];
}

@end
