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

#define RKFAILMAPPING() NSAssert(nil != nil, @"Failed mapping operation!!!")

/*!
 Maps parsed primitive dictionary and arrays into objects. This is the primary entry point
 for an external object mapping operation.
 */
typedef enum RKObjectMapperErrors {
    RKObjectMapperErrorObjectMappingNotFound,       // No mapping found
    RKObjectMapperErrorObjectMappingTypeMismatch,   // Target class and object mapping are in disagreement
    RKObjectMapperErrorUnmappableContent            // No mappable attributes or relationships were found
} RKObjectMapperErrorCode;

@class RKObjectMapper;

@protocol RKObjectMapperDelegate <NSObject>

@optional

- (void)objectMapperWillBeginMapping:(RKObjectMapper*)objectMapper;
- (void)objectMapperDidFinishMapping:(RKObjectMapper*)objectMapper;

- (void)objectMapper:(RKObjectMapper*)objectMapper didAddError:(NSError*)error;
- (void)objectMapper:(RKObjectMapper*)objectMapper willAttemptMappingForKeyPath:(NSString*)keyPath;
- (void)objectMapper:(RKObjectMapper*)objectMapper didFindMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath;
- (void)objectMapper:(RKObjectMapper*)objectMapper didNotFindMappingForKeyPath:(NSString*)keyPath;

// TODO: Should this be fromObject:toObject:
- (void)objectMapper:(RKObjectMapper*)objectMapper willMapObject:(id)destinationObject fromObject:(id)sourceObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping;
- (void)objectMapper:(RKObjectMapper*)objectMapper didMapObject:(id)destinationObject fromObject:(id)sourceObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping;
- (void)objectMapper:(RKObjectMapper*)objectMapper didFailMappingObject:(id)object withError:(NSError*)error fromObject:(id)sourceObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping;

@end

/*!
 An object mapper delegate for tracing the object mapper operations
 */
@interface RKObjectMapperTracingDelegate : NSObject <RKObjectMapperDelegate, RKObjectMappingOperationDelegate> {
}
@end

@interface RKObjectMapper : NSObject {
    id _object;
//    NSString* _keyPath;
    id _targetObject;
    RKObjectMappingProvider* _mappingProvider;
    id<RKObjectMapperDelegate> _delegate;
    NSMutableArray* _errors;
    RKObjectMapperTracingDelegate* _tracer;
    // TODO: i think this goes away. jbe.
    BOOL _tracingEnabled;
}

@property (nonatomic, readonly) id object;
//@property (nonatomic, readonly) NSString* keyPath;
@property (nonatomic, readonly) RKObjectMappingProvider* mappingProvider;

/*!
 When YES, the mapper will log tracing information about the mapping operations performed
 */
@property (nonatomic, assign) BOOL tracingEnabled;
@property (nonatomic, assign) id targetObject;
@property (nonatomic, assign) id<RKObjectMapperDelegate> delegate;

@property (nonatomic, readonly) NSArray* errors;

+ (id)mapperForObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(RKObjectMappingProvider*)mappingProvider;
- (id)initWithObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(RKObjectMappingProvider*)mappingProvider;

// Primary entry point for the mapper. Examines the type of object and processes it appropriately...
- (RKObjectMappingResult*)performMapping;
- (NSUInteger)errorCount;

@end
