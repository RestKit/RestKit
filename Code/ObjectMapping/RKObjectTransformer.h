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

#import <Foundation/Foundation.h>

@class RKObjectMapping;

/**
 * Protocol representing a transformation that can be applied during mapping,
 * e.g. to provide an arbitrary string to integer mapping before writing to the
 * database.
 */

@protocol RKObjectTransformer<NSObject>

/**
 * Report whether the transformer supports conversion to the specified type.
 *
 */
-(BOOL)canTransformToClass:(Class)destinationType;

/**
 * Transform a value
 */
-(id)transformedValue:(id)value ofClass:(Class)destinationType error:(NSError**)error;

/**
 * Inverse of this transformer, or nil if the transform is not invertible
 */
-(id<RKObjectTransformer>)inverseTransformer;

@end


/**
 * Simple RKObjectTransformer implementation in which a dictionary is used
 * to define a 1-to-1 object transformation rule. If the transform turns out
 * not to be 1-to-1, this class returns a null inverter
 */

@interface RKOneToOneObjectTransformer : NSObject<RKObjectTransformer>
{
    NSDictionary *_transformDictionary;
}
@property (nonatomic,retain) NSDictionary *transformDictionary;

-(id)initWithDictionary:(NSDictionary*)dictionary;

+(RKOneToOneObjectTransformer*)transformerWithDictionary:(NSDictionary*)dictionary;

@end

@interface RKDefaultTransformer : NSObject<RKObjectTransformer>
{
    RKObjectMapping *_objectMapping;
}
@property (nonatomic,retain) RKObjectMapping *objectMapping;

+(RKDefaultTransformer*)transformerWithObjectMapping:(RKObjectMapping*)mapping;

@end

