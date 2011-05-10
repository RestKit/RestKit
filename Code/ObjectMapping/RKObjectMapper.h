//
//  RKObjectMapper.h
//  RestKit
//
//  Created by Blake Watters on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectMapping.h"
#import "RKObjectMappingOperation.h"
#import "Logging.h"
#import "RKObjectMappingResult.h"
#import "RKObjectMappingProvider.h"

/*!
 Maps parsed primitive dictionary and arrays into objects. This is the primary entry point
 for an external object mapping operation.
 */
typedef enum RKObjectMapperErrors {
    RKObjectMapperErrorObjectMappingNotFound,       // No mapping found
    RKObjectMapperErrorObjectMappingTypeMismatch,   // Target class and object mapping are in disagreement
    RKObjectMapperErrorUnmappableContent,            // No mappable attributes or relationships were found
    RKObjectMapperErrorFromMappingResult
} RKObjectMapperErrorCode;

@class RKObjectMapper;

@protocol RKObjectMapperDelegate <NSObject>

@optional

- (void)objectMapperWillBeginMapping:(RKObjectMapper*)objectMapper;
- (void)objectMapperDidFinishMapping:(RKObjectMapper*)objectMapper;
- (void)objectMapper:(RKObjectMapper*)objectMapper didAddError:(NSError*)error;
- (void)objectMapper:(RKObjectMapper*)objectMapper didFindMappableObject:(id)object atKeyPath:(NSString*)keyPath withMapping:(RKObjectMapping*)mapping;
- (void)objectMapper:(RKObjectMapper*)objectMapper didNotFindMappableObjectAtKeyPath:(NSString*)keyPath;

- (void)objectMapper:(RKObjectMapper*)objectMapper willMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping;
- (void)objectMapper:(RKObjectMapper*)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping;
- (void)objectMapper:(RKObjectMapper*)objectMapper didFailMappingFromObject:(id)sourceObject toObject:(id)destinationObject withError:(NSError*)error atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping;

@end

@interface RKObjectMapper : NSObject {
    id _sourceObject;
    id _targetObject;
    RKObjectMappingProvider* _mappingProvider;
    id<RKObjectMapperDelegate> _delegate;
    NSMutableArray* _errors;
}

@property (nonatomic, readonly) id sourceObject;
@property (nonatomic, assign) id targetObject;
@property (nonatomic, readonly) RKObjectMappingProvider* mappingProvider;
@property (nonatomic, assign) id<RKObjectMapperDelegate> delegate;
@property (nonatomic, readonly) NSArray* errors;

+ (id)mapperWithObject:(id)object mappingProvider:(RKObjectMappingProvider*)mappingProvider;
- (id)initWithObject:(id)object mappingProvider:(RKObjectMappingProvider*)mappingProvider;

// Primary entry point for the mapper. Examines the type of object and processes it appropriately...
- (RKObjectMappingResult*)performMapping;
- (NSUInteger)errorCount;

@end
