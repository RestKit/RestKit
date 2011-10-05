//
//  RKObjectElementMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters
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

@protocol RKObjectTransformer;

// Defines the rules for mapping a particular element
@interface RKObjectAttributeMapping : NSObject <NSCopying> {
    NSString* _sourceKeyPath;
    NSString* _destinationKeyPath;
    id<RKObjectTransformer> _transformer;
}

@property (nonatomic, retain) NSString* sourceKeyPath;
@property (nonatomic, retain) NSString* destinationKeyPath;
@property (nonatomic, retain) id<RKObjectTransformer> transformer;

/**
 Defines a mapping from one keyPath to another within an object mapping
 */
+ (RKObjectAttributeMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath;
+ (RKObjectAttributeMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath transformer:(id<RKObjectTransformer>)transformer;

+ (RKObjectAttributeMapping*)inverseMappingForMapping:(RKObjectAttributeMapping*)forwardMapping;

/**
 * Produce the transformed value extracted from the source object
 */
-(id)valueFromSourceObject:(id)aSourceObject destinationType:(Class)aType defaultTransformer:(id<RKObjectTransformer>)defaultTransform error:(NSError**)error;

@end
