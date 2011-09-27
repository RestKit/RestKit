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
#import "../Support/RKLog.h"

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
-(id)transformedValue:(id)value ofClass:(Class)destinationType
{
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
