//
//  RKObjectMapper.h
//  RestKit
//
//  Created by Blake Watters on 5/6/11.
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
#import "RKObjectMapping.h"
#import "RKObjectMappingOperation.h"
#import "RKObjectMappingResult.h"
#import "RKObjectMappingProvider.h"
#import "RKMappingOperationQueue.h"
#import "Support.h"

@class RKObjectMapper;

@protocol RKObjectMapperDelegate <NSObject>

@optional

- (void)objectMapperWillBeginMapping:(RKObjectMapper *)objectMapper;
- (void)objectMapperDidFinishMapping:(RKObjectMapper *)objectMapper;
- (void)objectMapper:(RKObjectMapper *)objectMapper didAddError:(NSError *)error;
- (void)objectMapper:(RKObjectMapper *)objectMapper didFindMappableObject:(id)object atKeyPath:(NSString *)keyPath withMapping:(RKObjectMappingDefinition *)mapping;
- (void)objectMapper:(RKObjectMapper *)objectMapper didNotFindMappableObjectAtKeyPath:(NSString *)keyPath;

- (void)objectMapper:(RKObjectMapper *)objectMapper willMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(RKObjectMappingDefinition *)objectMapping;
- (void)objectMapper:(RKObjectMapper *)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(RKObjectMappingDefinition *)objectMapping;
- (void)objectMapper:(RKObjectMapper *)objectMapper didFailMappingFromObject:(id)sourceObject toObject:(id)destinationObject withError:(NSError *)error atKeyPath:(NSString *)keyPath usingMapping:(RKObjectMappingDefinition *)objectMapping;
@end

/**

 */
@interface RKObjectMapper : NSObject {
  @protected
    RKMappingOperationQueue *operationQueue;
    NSMutableArray *errors;
}

@property (nonatomic, readonly) id sourceObject;
@property (nonatomic, assign) id targetObject;
@property (nonatomic, readonly) RKObjectMappingProvider *mappingProvider;
@property (nonatomic, assign) RKObjectMappingProviderContext context;
@property (nonatomic, assign) id<RKObjectMapperDelegate> delegate;
@property (nonatomic, readonly) NSArray *errors;

+ (id)mapperWithObject:(id)object mappingProvider:(RKObjectMappingProvider *)mappingProvider;
- (id)initWithObject:(id)object mappingProvider:(RKObjectMappingProvider *)mappingProvider;

// Primary entry point for the mapper. Examines the type of object and processes it appropriately...
- (RKObjectMappingResult *)performMapping;
- (NSUInteger)errorCount;

@end
