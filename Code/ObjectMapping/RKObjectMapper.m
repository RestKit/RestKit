//
//  RKObjectMapper.m
//  RestKit
//
//  Created by Blake Watters on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapper.h"
#import "Errors.h"

@interface RKObjectMapper (Private)

- (id)mapObject:(id)destinationObject fromObject:(id)sourceObject atKeyPath:keyPath usingMapping:(RKObjectMapping*)mapping;
- (NSArray*)mapObjectsFromArray:(NSArray*)array atKeyPath:keyPath usingMapping:(RKObjectMapping*)mapping;

@end

// TODO: We can probably just ditch tracing in favor of NSLogger
@implementation RKObjectMapperTracingDelegate

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectAttributeMapping *)elementMapping forKeyPath:(NSString *)keyPath {
    RKLOG_MAPPING(0, @"Found mapping for keyPath '%@': %@", keyPath, elementMapping);
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath {
    RKLOG_MAPPING(0, @"Unable to find mapping for keyPath '%@'", keyPath);
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping*)mapping {
    RKLOG_MAPPING(0, @"Set '%@' to '%@' on object %@", keyPath, value, operation.destinationObject);
}

- (void)objectMapper:(RKObjectMapper *)objectMapper didAddError:(NSError *)error {
    RKLOG_MAPPING(0, @"Object mapper encountered error: %@", [error localizedDescription]);
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFailWithError:(NSError*)error {
    RKLOG_MAPPING(0, @"Object mapping operation failed with error: %@", [error localizedDescription]);
}

@end

@implementation RKObjectMapper

@synthesize tracingEnabled = _tracingEnabled;
@synthesize targetObject = _targetObject;
@synthesize delegate =_delegate;
@synthesize mappingProvider = _mappingProvider;
@synthesize object = _object;
@synthesize errors = _errors;

+ (id)mapperForObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(RKObjectMappingProvider*)mappingProvider {
    return [[[self alloc] initWithObject:object atKeyPath:keyPath mappingProvider:mappingProvider] autorelease];
}

- (id)initWithObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(RKObjectMappingProvider*)mappingProvider {
    self = [super init];
    if (self) {
        _object = [object retain];
        _mappingProvider = mappingProvider;
        _errors = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_object release];
    [_errors release];
    [_tracer release];
    [super dealloc];
}

- (void)setTracer:(RKObjectMapperTracingDelegate*)tracer {
    [tracer retain];
    [_tracer release];
    _tracer = tracer;
}

- (void)setTracingEnabled:(BOOL)tracingEnabled {
    if (tracingEnabled) {
        [self setTracer:[RKObjectMapperTracingDelegate new]];
    } else {
        [self setTracer:nil];
    }
}

- (BOOL)tracingEnabled {
    return _tracer != nil;
}

- (NSUInteger)errorCount {
    return [self.errors count];
}

- (id)createInstanceOfClassForMapping:(Class)mappableClass {
    // TODO: Believe we want this to consult the delegate? Or maybe the provider? objectForMappingWithClass:atKeyPath:
    if (mappableClass) {
        return [[mappableClass new] autorelease];
    }
    
    return nil;
}

- (NSString*)keyPath {
    return nil;
}

- (void)addError:(NSError*)error {
    NSAssert(error, @"Cannot add a nil error");
    [_errors addObject:error];
    
    if ([self.delegate respondsToSelector:@selector(objectMapper:didAddError:)]) {
        [self.delegate objectMapper:self didAddError:error];
    }
    [_tracer objectMapper:self didAddError:error];
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

// If the object being mapped is a collection, we map each object within the collection
//- (id)performMappingForCollectionWithObjectMapping:(RKObjectMapping*)objectMapping {
//    NSAssert([self.object isKindOfClass:[NSArray class]] || [self.object isKindOfClass:[NSSet class]], @"Expected self.object to be a collection");
////    RKObjectMapping* mapping = [self.mappingProvider objectMappingForKeyPath:self.keyPath];
//    if (mapping) {
//        return [self mapObjectsFromArray:self.object usingMapping:mapping];
//    } else {
//        // Attempted to map a collection but couldn't find a mapping for the keyPath
//        [self addErrorForUnmappableKeyPath:self.keyPath];
//    }
//    
//    return nil;
//}
//
//- (RKObjectMapping*)mappingForKeyPath:(NSString*)keyPath {
//    RKLOG_MAPPING(0, @"Looking for mapping for keyPath %@", keyPath);
//    if ([self.delegate respondsToSelector:@selector(objectMapper:willAttemptMappingForKeyPath:)]) {
//        [self.delegate objectMapper:self willAttemptMappingForKeyPath:keyPath];
//    }
//    [_tracer objectMapper:self willAttemptMappingForKeyPath:keyPath]; // TODO: Eliminate tracer in favor of logging macros...
//    
//    RKObjectMapping* mapping = [self.mappingProvider objectMappingForKeyPath:keyPath];
//    if (mapping) {
//        if ([self.delegate respondsToSelector:@selector(objectMapper:didFindMapping:forKeyPath:)]) {
//            [self.delegate objectMapper:self didFindMapping:mapping forKeyPath:keyPath];
//        }
//    } else {
//        if ([self.delegate respondsToSelector:@selector(objectMapper:didNotFindMappingForKeyPath:)]) {
//            [self.delegate objectMapper:self didNotFindMappingForKeyPath:keyPath];
//        }
//    }
//    
//    return mapping;
//}

// Attempts to map each sub keyPath for a mappable collection and returns the result as a dictionary
//- (id)performSubKeyPathObjectMapping {
//    NSAssert([self.object isKindOfClass:[NSDictionary class]], @"Can only perform sub keyPath mapping on a dictionary");
//    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
//    for (NSString* subKeyPath in [self.object allKeys]) {
//        NSString* keyPath = ([self.keyPath length] > 0) ? [NSString stringWithFormat:@"%@.%@", self.keyPath, subKeyPath] : subKeyPath;
//        RKObjectMapping* mapping = [self mappingForKeyPath:keyPath];
//        if (mapping) {
//            // This is a mappable sub keyPath. Initialize a new object mapper targeted at the subObject
//            id subObject = [self.object valueForKey:keyPath];
//            RKObjectMapper* subMapper = [RKObjectMapper mapperForObject:subObject atKeyPath:keyPath mappingProvider:self.mappingProvider];
//            subMapper.targetObject = self.targetObject;
//            subMapper.delegate = self.delegate;
//            [subMapper setTracer:_tracer];
//            id mappedResults = [subMapper performMapping];
//            if (mappedResults) {
//                [dictionary setValue:mappedResults forKey:keyPath];
//            }
//        }
//    }
//    
//    // If we have attempted a sub keyPath mapping and found no results, add an error
//    if ([dictionary count] == 0) {
//        NSString* errorMessage = [NSString stringWithFormat:@"Could not find an object mapping for keyPath: %@", self.keyPath];
//        [self addErrorWithCode:RKObjectMapperErrorObjectMappingNotFound message:errorMessage keyPath:self.keyPath userInfo:nil];
//        return nil;
//    }
//    
//    return dictionary;
//}

- (id)performMappingForObject:(id)object atKeyPath:(NSString*)keyPath withObjectMapping:(RKObjectMapping*)objectMapping {
    NSAssert([object respondsToSelector:@selector(setValue:forKeyPath:)], @"Expected self.object to be KVC compliant");
    
//    RKObjectMapping* objectMapping = nil;
    id destinationObject = nil;
    
    if (self.targetObject) {
        // If we find a mapping for this type and keyPath, map the entire dictionary to the target object
        destinationObject = self.targetObject;
//        objectMapping = [self mappingForKeyPath:self.keyPath];
        if (objectMapping && NO == [[self.targetObject class] isSubclassOfClass:objectMapping.objectClass]) {
            NSString* errorMessage = [NSString stringWithFormat:
                                      @"Expected an object mapping for class of type '%@', provider returned one for '%@'", 
                                      NSStringFromClass([self.targetObject class]), NSStringFromClass(objectMapping.objectClass)];            
            [self addErrorWithCode:RKObjectMapperErrorObjectMappingTypeMismatch message:errorMessage keyPath:keyPath userInfo:nil];
            return nil;
        }
    } else {
        // Otherwise map to a new object instance
//        objectMapping = [self mappingForKeyPath:self.keyPath];
        destinationObject = [self createInstanceOfClassForMapping:objectMapping.objectClass];
    }
    
    if (objectMapping && destinationObject) {
        return [self mapObject:destinationObject fromObject:object atKeyPath:keyPath usingMapping:objectMapping];
//    } else if ([object isKindOfClass:[NSDictionary class]]) {
        // If this is a dictionary, attempt to map each sub-keyPath
//        return [self performSubKeyPathObjectMapping];
    } else {
        // Attempted to map an object but couldn't find a mapping for the keyPath
        [self addErrorForUnmappableKeyPath:keyPath];
        return nil;
    }
    
    return nil;
}

- (BOOL)isNullCollection:(id)object {
    if ([object respondsToSelector:@selector(countForObject:)]) {
        return ([object countForObject:[NSNull null]] == [object count]);
    }
    
    return NO;
}

// Primary entry point for the mapper. 
- (RKObjectMappingResult*)performMapping {
    NSAssert(self.object != nil, @"Cannot perform object mapping without an object to map");
    NSAssert(self.mappingProvider != nil, @"Cannot perform object mapping without an object mapping provider");
    
    RKLOG_MAPPING(0, @"Self.object is %@", self.object);
    
    if ([self.delegate respondsToSelector:@selector(objectMapperWillBeginMapping:)]) {
        [self.delegate objectMapperWillBeginMapping:self];
    }
    
    // Perform the mapping
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    NSDictionary* keyPathsAndObjectMappings = [self.mappingProvider keyPathsAndObjectMappings];
    for (NSString* keyPath in keyPathsAndObjectMappings) {
        id mappingResult;
        id mappableValue;
        
        if ([self.delegate respondsToSelector:@selector(objectMapper:willAttemptMappingForKeyPath:)]) {
            [self.delegate objectMapper:self willAttemptMappingForKeyPath:keyPath];
        }
        [_tracer objectMapper:self willAttemptMappingForKeyPath:keyPath]; // TODO: Eliminate tracer in favor of logging macros...
        
        if ([keyPath isEqualToString:@""]) {
            mappableValue = self.object;
        } else {
            mappableValue = [self.object valueForKeyPath:keyPath];
        }
        
        // Not found...
        if (mappableValue == nil || mappableValue == [NSNull null] || [self isNullCollection:mappableValue]) {
            NSLog(@"Not mappable, skipping... %@", mappableValue);
            
            if ([self.delegate respondsToSelector:@selector(objectMapper:didNotFindMappingForKeyPath:)]) {
                [self.delegate objectMapper:self didNotFindMappingForKeyPath:keyPath];
            }
                
            continue;
        }
        
        // Found something to map
        RKObjectMapping* objectMapping = [keyPathsAndObjectMappings objectForKey:keyPath];
        if ([self.delegate respondsToSelector:@selector(objectMapper:didFindMapping:forKeyPath:)]) {
            [self.delegate objectMapper:self didFindMapping:objectMapping forKeyPath:keyPath];
        }
        if ([mappableValue isKindOfClass:[NSArray class]] || [mappableValue isKindOfClass:[NSSet class]]) {
            mappingResult = [self mapObjectsFromArray:mappableValue atKeyPath:keyPath usingMapping:objectMapping];
        } else {
            mappingResult = [self performMappingForObject:mappableValue atKeyPath:keyPath withObjectMapping:objectMapping];
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

- (id)mapObject:(id)destinationObject fromObject:(id)sourceObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)mapping {    
    NSAssert(destinationObject != nil, @"Cannot map without a target object to assign the results to");    
    NSAssert(sourceObject != nil, @"Cannot map without a collection of attributes");
    NSAssert(mapping != nil, @"Cannot map without an mapping");
    
    RKLOG_MAPPING(0, @"Asked to map source object %@ with mapping %@", sourceObject, mapping);
    if ([self.delegate respondsToSelector:@selector(objectMapper:willMapObject:fromObject:atKeyPath:usingMapping:)]) {
        [self.delegate objectMapper:self willMapObject:destinationObject fromObject:sourceObject atKeyPath:keyPath usingMapping:mapping];
    }
    
    NSError* error = nil;
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:destinationObject objectMapping:mapping];
    operation.delegate = _tracer;
    BOOL success = [operation performMapping:&error];
    [operation release];
    
    if (success) {
        if ([self.delegate respondsToSelector:@selector(objectMapper:didMapObject:fromObject:atKeyPath:usingMapping:)]) {
            [self.delegate objectMapper:self didMapObject:destinationObject fromObject:sourceObject atKeyPath:self.keyPath usingMapping:mapping];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(objectMapper:didFailMappingObject:withError:fromObject:atKeyPath:usingMapping:)]) {
            [self.delegate objectMapper:self didFailMappingObject:destinationObject withError:error fromObject:sourceObject atKeyPath:self.keyPath usingMapping:mapping];
        }
        [self addError:error];
    }
    
    return destinationObject;
}

- (NSArray*)mapObjectsFromArray:(NSArray*)array atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)mapping {
    NSAssert(array != nil, @"Cannot map without an array of objects");
    NSAssert(mapping != nil, @"Cannot map without a mapping to consult");
    
    // Ensure we are mapping onto a mutable collection if there is a target
    if (self.targetObject && NO == [self.targetObject respondsToSelector:@selector(addObject:)]) {
        NSString* errorMessage = [NSString stringWithFormat:
                                  @"Cannot map a collection of objects onto a non-mutable collection. Unexpected target object type '%@'", 
                                  NSStringFromClass([self.targetObject class])];            
        [self addErrorWithCode:RKObjectMapperErrorObjectMappingTypeMismatch message:errorMessage keyPath:self.keyPath userInfo:nil];
        return nil;
    }
    
    // TODO: It should map arrays of arrays...
    NSMutableArray* mappedObjects = [NSMutableArray arrayWithCapacity:[array count]];
    for (id elements in array) {
        // TODO: Need to examine the type of elements and behave appropriately...
        if ([elements isKindOfClass:[NSDictionary class]]) {
            id mappableObject = [self createInstanceOfClassForMapping:mapping.objectClass];
            NSObject* mappedObject = [self mapObject:mappableObject fromObject:elements atKeyPath:keyPath usingMapping:mapping];
            if (mappedObject) {
                [mappedObjects addObject:mappedObject];
            }
        } else {
            // TODO: Delegate method invocation here...
            RKFAILMAPPING();
        }
    }
    
    return mappedObjects;
}

@end
