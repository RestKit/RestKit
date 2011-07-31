//
//  RKDynamicObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectDynamicMapping.h"
#import "../Support/RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitObjectMapping

// Implemented in RKObjectMappingOperation
BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

@interface RKObjectDynamicMappingMatcher : NSObject {
    NSString* _keyPath;
    id _value;
    RKObjectMapping* _objectMapping;
}

@property (nonatomic, readonly) RKObjectMapping* objectMapping;

- (id)initWithKey:(NSString*)key value:(id)value objectMapping:(RKObjectMapping*)objectMapping;
- (BOOL)isMatchForData:(id)data;
- (NSString*)matchDescription;
@end

@implementation RKObjectDynamicMappingMatcher

@synthesize objectMapping = _objectMapping;

- (id)initWithKey:(NSString*)key value:(id)value objectMapping:(RKObjectMapping*)objectMapping {
    self = [super init];
    if (self) {
        _keyPath = [key retain];
        _value = [value retain];
        _objectMapping = [objectMapping retain];
    }
    
    return self;
}

- (void)dealloc {
    [_keyPath release];
    [_value release];
    [_objectMapping release];
    [super dealloc];
}

- (BOOL)isMatchForData:(id)data {
    return RKObjectIsValueEqualToValue([data valueForKeyPath:_keyPath], _value);
}

- (NSString*)matchDescription {
    return [NSString stringWithFormat:@"%@ == %@", _keyPath, _value];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKObjectDynamicMapping

@synthesize delegate = _delegate;
@synthesize objectMappingForDataBlock = _objectMappingForDataBlock;
@synthesize forceCollectionMapping = _forceCollectionMapping;

+ (RKObjectDynamicMapping*)dynamicMapping {
    return [[self new] autorelease];
}

#if NS_BLOCKS_AVAILABLE

+ (RKObjectDynamicMapping*)dynamicMappingWithBlock:(void(^)(RKObjectDynamicMapping*))block {
    RKObjectDynamicMapping* mapping = [self dynamicMapping];
    block(mapping);
    return mapping;
}

#endif

- (id)init {
    self = [super init];
    if (self) {
        _matchers = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_matchers release];
    [super dealloc];
}

- (void)setObjectMapping:(RKObjectMapping*)objectMapping whenValueOfKeyPath:(NSString*)keyPath isEqualTo:(id)value {
    RKLogDebug(@"Adding dynamic object mapping for key '%@' with value '%@' to destination class: %@", keyPath, value, NSStringFromClass(objectMapping.objectClass));
    RKObjectDynamicMappingMatcher* matcher = [[RKObjectDynamicMappingMatcher alloc] initWithKey:keyPath value:value objectMapping:objectMapping];
    [_matchers addObject:matcher];
    [matcher release];
}

- (RKObjectMapping*)objectMappingForDictionary:(NSDictionary*)data {
    NSAssert([data isKindOfClass:[NSDictionary class]], @"Dynamic object mapping can only be performed on NSDictionary mappables, got %@", NSStringFromClass([data class]));
    RKObjectMapping* mapping = nil;
    
    RKLogTrace(@"Performing dynamic object mapping for mappable data: %@", data);
    
    // Consult the declarative matchers first
    for (RKObjectDynamicMappingMatcher* matcher in _matchers) {
        if ([matcher isMatchForData:data]) {
            RKLogTrace(@"Found declarative match for data: %@.", [matcher matchDescription]);
            return matcher.objectMapping;
        }
    }
    
    // Otherwise consult the delegates
    if (self.delegate) {
        mapping = [self.delegate objectMappingForData:data];
        if (mapping) {
            RKLogTrace(@"Found dynamic delegate match. Delegate = %@", self.delegate);
            return mapping;
        }
    }
    
    if (self.objectMappingForDataBlock) {        
        mapping = self.objectMappingForDataBlock(data);
        if (mapping) {
            RKLogTrace(@"Found dynamic delegateBlock match. objectMappingForDataBlock = %@", self.objectMappingForDataBlock);
        }
    }
    
    return mapping;
}

@end
