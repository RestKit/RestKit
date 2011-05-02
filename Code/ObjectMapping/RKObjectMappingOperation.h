//
//  RKObjectMappingOperation.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"
#import "RKObjectKeyPathMapping.h"

@class RKObjectMappingOperation;

@protocol RKObjectMappingOperationDelegate  <NSObject>

@required
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectKeyPathMapping *)elementMapping forKeyPath:(NSString *)keyPath;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath;
- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forProperty:(NSString *)property;

@end

/*!
 Performs an object mapping operation by mapping values from a dictinary of elements
 and setting the mapped values onto a target object.
 */
@interface RKObjectMappingOperation : NSObject {
    id _object;
    NSString* _keyPath;
    NSDictionary* _dictionary;
    RKObjectMapping* _objectMapping;
    
    id<RKObjectMappingOperationDelegate> _delegate;
}

/*!
 The target object for this operation. Mappable values in elements will be applied to object
 using key-value coding.
 */
@property (nonatomic, readonly) id object;

/*!
 The current keyPath this operation is occuring at. This our current scope in
 a larger object mapping context.
 */
@property (nonatomic, readonly) NSString* keyPath;

/*!
 A dictionary of mappable elements containing simple values or nested object structures.
 */
@property (nonatomic, readonly) NSDictionary* dictionary;

/*!
 The object mapping defining how values contained in elements should be applied to the target object via key-value coding
 */
@property (nonatomic, readonly) RKObjectMapping* objectMapping;

/*!
 The delegate to inform of 
 */
@property (nonatomic, assign) id<RKObjectMappingOperationDelegate> delegate;

/*!
 Initialize a mapping operation for an object and set of data at a particular key path with an object mapping definition
 */
- (id)initWithObject:(id)object andDictionary:(NSDictionary*)dictionary atKeyPath:(NSString*)keyPath usingObjectMapping:(RKObjectMapping*)objectMapping;

/*!
 Process all mappable values from the element dictionary and assign them to the target object
 according to the rules expressed in the object mapping definition
 */
- (void)performMapping;

@end
