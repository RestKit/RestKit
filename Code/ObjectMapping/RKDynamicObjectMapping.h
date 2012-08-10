//
//  RKDynamicObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import "RKObjectMappingDefinition.h"
#import "RKObjectMapping.h"

/**
 Return the appropriate object mapping given a mappable data
 */
@protocol RKDynamicObjectMappingDelegate <NSObject>

@required
- (RKObjectMapping *)objectMappingForData:(id)data;

@end

#ifdef NS_BLOCKS_AVAILABLE
typedef RKObjectMapping *(^RKDynamicObjectMappingDelegateBlock)(id);
#endif

/**
 Defines a dynamic object mapping that determines the appropriate concrete
 object mapping to apply at mapping time. This allows you to map very similar payloads
 differently depending on the type of data contained therein.
 */
@interface RKDynamicObjectMapping : RKObjectMappingDefinition {
    NSMutableArray *_matchers;
}

/**
 A delegate to call back to determine the appropriate concrete object mapping
 to apply to the mappable data.

 @see RKDynamicObjectMappingDelegate
 */
@property (nonatomic, assign) id<RKDynamicObjectMappingDelegate> delegate;

#ifdef NS_BLOCKS_AVAILABLE
/**
 A block to invoke to determine the appropriate concrete object mapping
 to apply to the mappable data.
 */
@property (nonatomic, copy) RKDynamicObjectMappingDelegateBlock objectMappingForDataBlock;
#endif

/**
 Return a new auto-released dynamic object mapping
 */
+ (RKDynamicObjectMapping *)dynamicMapping;

#if NS_BLOCKS_AVAILABLE

/**
 Return a new auto-released dynamic object mapping after yielding it to the block for configuration
 */
+ (RKDynamicObjectMapping *)dynamicMappingUsingBlock:(void(^)(RKDynamicObjectMapping *dynamicMapping))block;
+ (RKDynamicObjectMapping *)dynamicMappingWithBlock:(void(^)(RKDynamicObjectMapping *dynamicMapping))block DEPRECATED_ATTRIBUTE;

#endif

/**
 Defines a dynamic mapping rule stating that when the value of the key property matches the specified
 value, the objectMapping should be used.

 For example, suppose that we have a JSON fragment for a person that we want to map differently based on
 the gender of the person. When the gender is 'male', we want to use the Boy class and when then the gender
 is 'female' we want to use the Girl class. We might define our dynamic mapping like so:

    RKDynamicObjectMapping *mapping = [RKDynamicObjectMapping dynamicMapping];
    [mapping setObjectMapping:boyMapping whenValueOfKeyPath:@"gender" isEqualTo:@"male"];
    [mapping setObjectMapping:boyMapping whenValueOfKeyPath:@"gender" isEqualTo:@"female"];
 */
- (void)setObjectMapping:(RKObjectMapping *)objectMapping whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value;

/**
 Invoked by the RKObjectMapper and RKObjectMappingOperation to determine the appropriate RKObjectMapping to use
 when mapping the specified dictionary of mappable data.
 */
- (RKObjectMapping *)objectMappingForDictionary:(NSDictionary *)dictionary;

@end

/**
 Define an alias for the old class name for compatibility

 @deprecated
 */
@interface RKObjectDynamicMapping : RKDynamicObjectMapping
@end
