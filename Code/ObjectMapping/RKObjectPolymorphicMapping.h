//
//  RKDynamicObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectAbstractMapping.h"
#import "RKObjectMapping.h"

/**
 Return the appropriate object mapping given a mappable data
 */
@protocol RKObjectPolymorphicMappingDelegate <NSObject>

@required
- (RKObjectMapping*)objectMappingForData:(id)data;

@end

#ifdef NS_BLOCKS_AVAILABLE
typedef RKObjectMapping*(^RKObjectPolymorphicMappingDelegateBlock)(id);
#endif

/**
 Defines a polymorphic object mapping that determines the appropriate concrete
 object mapping to apply at mapping time. This allows you to map very similar payloads
 differently depending on the type of data contained therein.
 */
@interface RKObjectPolymorphicMapping : RKObjectAbstractMapping {
    NSMutableArray* _matchers;
    id<RKObjectPolymorphicMappingDelegate> _delegate;
    #ifdef NS_BLOCKS_AVAILABLE
    RKObjectPolymorphicMappingDelegateBlock _delegateBlock;
    #endif
    BOOL _forceCollectionMapping;
}

/**
 A delegate to call back to determine the appropriate concrete object mapping
 to apply to the mappable data.
 
 @see RKDynamicObjectMappingDelegate
 */
@property (nonatomic, assign) id<RKObjectPolymorphicMappingDelegate> delegate;

#ifdef NS_BLOCKS_AVAILABLE
/**
 A block to invoke to determine the appropriate concrete object mapping
 to apply to the mappable data.
 */
@property (nonatomic, copy) RKObjectPolymorphicMappingDelegateBlock delegateBlock;
#endif

/**
 When YES, an NSDictionary encountered by RKObjectMapper will be treated as a collection
 rather than as a single mappable entity. This is used to perform sub-keypath mapping wherein
 the keys of the dictionary are part of the mappable data.
 */
@property (nonatomic, assign) BOOL forceCollectionMapping;

/**
 Return a new auto-released polymorphic object mapping
 */
+ (RKObjectPolymorphicMapping*)polymorphicMapping;

#if NS_BLOCKS_AVAILABLE
    
/**
 Return a new auto-released polymorphic object mapping after yielding it to the block for configuration
 */
+ (RKObjectPolymorphicMapping*)polymorphicMappingWithBlock:(void(^)(RKObjectPolymorphicMapping*))block;

#endif

//+ (id)mappingForClass:(Class)objectClass block:(void(^)(RKObjectMapping*))block {
// TODO: polymorphicMappingWithBlock

/**
 Defines a polymorphic mapping rule stating that when the value of the key property matches the specified
 value, the objectMapping should be used.
 
 For example, suppose that we have a JSON fragment for a person that we want to map differently based on
 the gender of the person. When the gender is 'male', we want to use the Boy class and when then the gender
 is 'female' we want to use the Girl class. We might define our polymorphic mapping like so:
 
    RKObjectPolymorphicMapping* mapping = [RKObjectPolymorphicMapping polymorphicMapping];
    [mapping setObjectMapping:boyMapping whenValueOfKey:@"gender" isEqualTo:@"male"];
    [mapping setObjectMapping:boyMapping whenValueOfKey:@"gender" isEqualTo:@"female"];
 */
- (void)setObjectMapping:(RKObjectMapping*)objectMapping whenValueOfKey:(NSString*)key isEqualTo:(id)value;

/**
 Invoked by the RKObjectMapper and RKObjectMappingOperation to determine the appropriate RKObjectMapping to use
 when mapping the specified dictionary of mappable data.
 */
- (RKObjectMapping*)objectMappingForDictionary:(NSDictionary*)dictionary;

@end
