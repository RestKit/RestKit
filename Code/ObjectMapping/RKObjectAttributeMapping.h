//
//  RKObjectElementMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import <Foundation/Foundation.h>

// Defines the rules for mapping a particular element
@interface RKObjectAttributeMapping : NSObject <NSCopying>

@property (nonatomic, retain) NSString *sourceKeyPath;
@property (nonatomic, retain) NSString *destinationKeyPath;

/**
 Defines a mapping from one keyPath to another within an object mapping
 */
+ (RKObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath;

/**
 Returns YES if this attribute mapping targets the key of a nested dictionary.

 When an object mapping is configured to target mapping of nested content via [RKObjectMapping mapKeyOfNestedDictionaryToAttribute:], a special attribute mapping is defined that targets
 the key of the nested dictionary rather than a value within in. This method will return YES if
 this attribute mapping is configured in such a way.

 @see [RKObjectMapping mapKeyOfNestedDictionaryToAttribute:]
 @return YES if this attribute mapping targets a nesting key path
 */
- (BOOL)isMappingForKeyOfNestedDictionary;

@end
