//
//  RKObjectMapper.m
//  RestKit
//
//  Created by Blake Watters on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapper.h"
#import "Errors.h"
#import "RKObjectMapper_Private.h"

// TODO: Move these into the object mapping operation class
//@implementation RKObjectMapperTracingDelegate
//
//- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectAttributeMapping *)elementMapping forKeyPath:(NSString *)keyPath {
//    RKLOG_MAPPING(0, @"Found mapping for keyPath '%@': %@", keyPath, elementMapping);
//}
//
//- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath {
//    RKLOG_MAPPING(0, @"Unable to find mapping for keyPath '%@'", keyPath);
//}
//
//- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping*)mapping {
//    RKLOG_MAPPING(0, @"Set '%@' to '%@' on object %@", keyPath, value, operation.destinationObject);
//}
//
//- (void)objectMapper:(RKObjectMapper *)objectMapper didAddError:(NSError *)error {
//    RKLOG_MAPPING(0, @"Object mapper encountered error: %@", [error localizedDescription]);
//}
//
//- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFailWithError:(NSError*)error {
//    RKLOG_MAPPING(0, @"Object mapping operation failed with error: %@", [error localizedDescription]);
//}
//
//@end

@implementation RKObjectMapper

@synthesize sourceObject = _sourceObject;
@synthesize targetObject = _targetObject;
@synthesize delegate =_delegate;
@synthesize mappingProvider = _mappingProvider;
@synthesize errors = _errors;

+ (id)mapperWithObject:(id)object mappingProvider:(RKObjectMappingProvider*)mappingProvider {
    return [[[self alloc] initWithObject:object mappingProvider:mappingProvider] autorelease];
}

- (id)initWithObject:(id)object mappingProvider:(RKObjectMappingProvider*)mappingProvider {
    self = [super init];
    if (self) {
        _sourceObject = [object retain];
        _mappingProvider = mappingProvider;
        _errors = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_sourceObject release];
    [_errors release];
    [super dealloc];
}

- (id)createInstanceOfClassForMapping:(Class)mappableClass {
    // TODO: Believe we want this to consult the delegate? Or maybe the provider? objectForMappingWithClass:atKeyPath:
    if (mappableClass) {
        return [[mappableClass new] autorelease];
    }
    
    return nil;
}

#pragma mark - Errors

- (NSUInteger)errorCount {
    return [self.errors count];
}

- (void)addError:(NSError*)error {
    NSAssert(error, @"Cannot add a nil error");
    [_errors addObject:error];
    
    if ([self.delegate respondsToSelector:@selector(objectMapper:didAddError:)]) {
        [self.delegate objectMapper:self didAddError:error];
    }
    
    RKLOG_MAPPING(0, @"Adding mapping error: %@", [error localizedDescription]);
}

- (void)addErrorWithCode:(RKObjectMapperErrorCode)errorCode message:(NSString*)errorMessage keyPath:(NSString*)keyPath userInfo:(NSDictionary*)otherInfo {
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     errorMessage, NSLocalizedDescriptionKey,
                                     @"RKObjectMapperKeyPath", keyPath ? keyPath : (NSString*) [NSNull null],
                                     nil];
    [userInfo addEntriesFromDictionary:otherInfo];
    NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:errorCode userInfo:userInfo];
    [self addError:error];
}

- (void)addErrorForUnmappableKeyPath:(NSString*)keyPath {
    NSString* errorMessage = [NSString stringWithFormat:@"Could not find an object mapping for keyPath: %@", keyPath];
    [self addErrorWithCode:RKObjectMapperErrorObjectMappingNotFound message:errorMessage keyPath:keyPath userInfo:nil];
}

- (BOOL)isNullCollection:(id)object {
    if ([object respondsToSelector:@selector(countForObject:)]) {
        return ([object countForObject:[NSNull null]] == [object count]);
    }
    
    return NO;
}

#pragma mark - Mapping Primitives

- (id)mapObject:(id)mappableObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping {
    NSAssert([mappableObject respondsToSelector:@selector(setValue:forKeyPath:)], @"Expected self.object to be KVC compliant");
    id destinationObject = nil;
    
    if (self.targetObject) {
        // If we find a mapping for this type and keyPath, map the entire dictionary to the target object
        destinationObject = self.targetObject;
        if (objectMapping && NO == [[self.targetObject class] isSubclassOfClass:objectMapping.objectClass]) {
            NSString* errorMessage = [NSString stringWithFormat:
                                      @"Expected an object mapping for class of type '%@', provider returned one for '%@'", 
                                      NSStringFromClass([self.targetObject class]), NSStringFromClass(objectMapping.objectClass)];            
            [self addErrorWithCode:RKObjectMapperErrorObjectMappingTypeMismatch message:errorMessage keyPath:keyPath userInfo:nil];
            return nil;
        }
    } else {
        destinationObject = [self createInstanceOfClassForMapping:objectMapping.objectClass];
        // TODO: Check the type?
    }
    
    if (objectMapping && destinationObject) {
        BOOL success = [self mapFromObject:mappableObject toObject:destinationObject atKeyPath:keyPath usingMapping:objectMapping];
        if (success) {
            return destinationObject;
        }
    } else {
        // Attempted to map an object but couldn't find a mapping for the keyPath
        [self addErrorForUnmappableKeyPath:keyPath];
        return nil;
    }
    
    return nil;
}

- (NSArray*)mapCollection:(NSArray*)mappableObjects atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)mapping {
    NSAssert(mappableObjects != nil, @"Cannot map without an collection of mappable objects");
    NSAssert(mapping != nil, @"Cannot map without a mapping to consult");
    
    // Ensure we are mapping onto a mutable collection if there is a target
    NSMutableArray* mappedObjects = self.targetObject ? self.targetObject : [NSMutableArray arrayWithCapacity:[mappableObjects count]];
    if (NO == [mappedObjects respondsToSelector:@selector(addObject:)]) {
        NSString* errorMessage = [NSString stringWithFormat:
                                  @"Cannot map a collection of objects onto a non-mutable collection. Unexpected destination object type '%@'", 
                                  NSStringFromClass([mappedObjects class])];            
        [self addErrorWithCode:RKObjectMapperErrorObjectMappingTypeMismatch message:errorMessage keyPath:keyPath userInfo:nil];
        return nil;
    }
    
    // TODO: It should map arrays of arrays...
    // TODO: It should map array of objects back to dicitonaries...    
    for (id mappableObject in mappableObjects) {
        id destinationObject = [self createInstanceOfClassForMapping:mapping.objectClass];
        BOOL success = [self mapFromObject:mappableObject toObject:destinationObject atKeyPath:keyPath usingMapping:mapping];
        if (success) {
            [mappedObjects addObject:destinationObject];
        }
    }
    
    return mappedObjects;
}

// The workhorse of this entire process. Emits object loading operations
- (BOOL)mapFromObject:(id)mappableObject toObject:(id)destinationObject atKeyPath:keyPath usingMapping:(RKObjectMapping*)mapping {
    NSAssert(destinationObject != nil, @"Cannot map without a target object to assign the results to");    
    NSAssert(mappableObject != nil, @"Cannot map without a collection of attributes");
    NSAssert(mapping != nil, @"Cannot map without an mapping");
    
    RKLOG_MAPPING(0, @"Asked to map source object %@ with mapping %@", sourceObject, mapping);
    if ([self.delegate respondsToSelector:@selector(objectMapper:willMapFromObject:toObject:atKeyPath:usingMapping:)]) {
        [self.delegate objectMapper:self willMapFromObject:mappableObject toObject:destinationObject atKeyPath:keyPath usingMapping:mapping];
    }
    
    NSError* error = nil;
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:mappableObject destinationObject:destinationObject objectMapping:mapping];
    BOOL success = [operation performMapping:&error];
    [operation release];
    
    if (success) {
        if ([self.delegate respondsToSelector:@selector(objectMapper:didMapFromObject:toObject:atKeyPath:usingMapping:)]) {
            [self.delegate objectMapper:self didMapFromObject:mappableObject toObject:destinationObject atKeyPath:keyPath usingMapping:mapping];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(objectMapper:didFailMappingFromObject:toObject:withError:atKeyPath:usingMapping:)]) {
            [self.delegate objectMapper:self didFailMappingFromObject:mappableObject toObject:destinationObject withError:error atKeyPath:keyPath usingMapping:mapping];
        }
        [self addError:error];
    }
    
    return success;
}

// Primary entry point for the mapper. 
- (RKObjectMappingResult*)performMapping {
    NSAssert(self.sourceObject != nil, @"Cannot perform object mapping without a source object to map from");
    NSAssert(self.mappingProvider != nil, @"Cannot perform object mapping without an object mapping provider");
    
    RKLOG_MAPPING(0, @"Self.object is %@", self.object);
    // TODO: Log if there is a target object...
    
    if ([self.delegate respondsToSelector:@selector(objectMapperWillBeginMapping:)]) {
        [self.delegate objectMapperWillBeginMapping:self];
    }
    
    // Perform the mapping
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    NSDictionary* keyPathsAndObjectMappings = [self.mappingProvider keyPathsAndObjectMappings];
    for (NSString* keyPath in keyPathsAndObjectMappings) {
        id mappingResult;
        id mappableValue;
        
        // TODO: Log that we will attempt mapping this keyPath
        
        if ([keyPath isEqualToString:@""]) {
            mappableValue = self.sourceObject;
        } else {
            mappableValue = [self.sourceObject valueForKeyPath:keyPath];
        }
        
        // Not found...
        if (mappableValue == nil || mappableValue == [NSNull null] || [self isNullCollection:mappableValue]) {
            NSLog(@"Not mappable, skipping... %@", mappableValue);
            
            if ([self.delegate respondsToSelector:@selector(objectMapper:didNotFindMappableObjectAtKeyPath:)]) {
                [self.delegate objectMapper:self didNotFindMappableObjectAtKeyPath:keyPath];
            }
            
            continue;
        }
        
        // Found something to map
        RKObjectMapping* objectMapping = [keyPathsAndObjectMappings objectForKey:keyPath];
        if ([self.delegate respondsToSelector:@selector(objectMapper:didFindMappableObject:atKeyPath:withMapping:)]) {
            [self.delegate objectMapper:self didFindMappableObject:mappableValue atKeyPath:keyPath withMapping:objectMapping];
        }
        if ([mappableValue isKindOfClass:[NSArray class]] || [mappableValue isKindOfClass:[NSSet class]]) {
            mappingResult = [self mapCollection:mappableValue atKeyPath:keyPath usingMapping:objectMapping];
        } else {
            mappingResult = [self mapObject:mappableValue atKeyPath:keyPath usingMapping:objectMapping];
        }
        
        if (mappingResult) {
            [results setObject:mappingResult forKey:keyPath];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(objectMapperDidFinishMapping:)]) {
        [self.delegate objectMapperDidFinishMapping:self];
    }
    
    
    if ([results count] == 0) {
        [self addErrorForUnmappableKeyPath:@""];
        return nil;
    }
    
    return [RKObjectMappingResult mappingResultWithDictionary:results];
}

@end
