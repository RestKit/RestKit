//
//  RKMapperOperation.m
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

#import "RKMapperOperation.h"
#import "RKMapperOperation_Private.h"
#import "RKObjectMappingOperationDataSource.h"
#import "RKMappingErrors.h"
#import "RKResponseDescriptor.h"
#import "RKDynamicMapping.h"
#import "RKLog.h"

NSString * const RKMappingErrorKeyPathErrorKey = @"keyPath";

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitObjectMapping

static NSString *RKDelegateKeyPathFromKeyPath(NSString *keyPath)
{
    return ([keyPath isEqual:[NSNull null]]) ? nil : keyPath;
}

@interface RKMapperOperation ()

@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong) NSMutableArray *mappingErrors;
@property (nonatomic, strong) id sourceObject;
@property (nonatomic, strong, readwrite) NSDictionary *mappingsDictionary;

@end

@implementation RKMapperOperation

- (id)initWithObject:(id)object mappingsDictionary:(NSDictionary *)mappingsDictionary;
{
    self = [super init];
    if (self) {
        self.sourceObject = object;
        self.mappingsDictionary = mappingsDictionary;
        self.mappingErrors = [NSMutableArray new];
        self.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    }

    return self;
}

#pragma mark - Errors

- (NSArray *)errors
{
    return [NSArray arrayWithArray:self.mappingErrors];
}

- (void)addError:(NSError *)error
{
    NSAssert(error, @"Cannot add a nil error");
    [self.mappingErrors addObject:error];
    RKLogWarning(@"Adding mapping error: %@", [error localizedDescription]);
}

- (void)addErrorWithCode:(RKMappingErrorCode)errorCode message:(NSString *)errorMessage keyPath:(NSString *)keyPath userInfo:(NSDictionary *)otherInfo
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     errorMessage, NSLocalizedDescriptionKey,
                                     keyPath ? keyPath : [NSNull null], RKMappingErrorKeyPathErrorKey,
                                     nil];
    [userInfo addEntriesFromDictionary:otherInfo];
    NSError *error = [NSError errorWithDomain:RKErrorDomain code:errorCode userInfo:userInfo];
    [self addError:error];
    self.error = error;
}

- (void)addErrorForUnmappableKeyPath:(NSString *)keyPath
{
    NSString *errorMessage = [NSString stringWithFormat:@"Could not find an object mapping for keyPath: '%@'", keyPath];
    [self addErrorWithCode:RKMappingErrorNotFound message:errorMessage keyPath:keyPath userInfo:nil];
}

- (BOOL)isNullCollection:(id)object
{
    // The purpose of this method is to guard against the case where we perform valueForKeyPath: on an array
    // and it returns NSNull for each element in the array.

    // We consider an empty array/dictionary mappable, but a collection that contains only NSNull
    // values is unmappable
    if ([object respondsToSelector:@selector(objectForKey:)]) {
        return NO;
    }

    if ([object respondsToSelector:@selector(countForObject:)] && [object count] > 0) {
        if ([object countForObject:[NSNull null]] == [object count]) {
            RKLogDebug(@"Found a collection containing only NSNull values, considering the collection unmappable...");
            return YES;
        }
    }

    return NO;
}

#pragma mark - Mapping Primitives

- (id)mapObject:(id)mappableObject atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping
{
    NSAssert([mappableObject respondsToSelector:@selector(setValue:forKeyPath:)], @"Expected self.object to be KVC compliant");
    id destinationObject = nil;

    if (self.targetObject) {
        destinationObject = self.targetObject;
        RKObjectMapping *objectMapping = nil;
        if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
            objectMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:mappableObject];
        } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
            objectMapping = (RKObjectMapping *)mapping;
        } else {
            NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
        }
        if (NO == [[self.targetObject class] isSubclassOfClass:objectMapping.objectClass]) {
            NSString *errorMessage = [NSString stringWithFormat:
                                      @"Expected an object mapping for class of type '%@', provider returned one for '%@'",
                                      NSStringFromClass([self.targetObject class]), NSStringFromClass(objectMapping.objectClass)];
            [self addErrorWithCode:RKMappingErrorTypeMismatch message:errorMessage keyPath:keyPath userInfo:nil];
            return nil;
        }
    } else {
        destinationObject = [self objectWithMapping:mapping andData:mappableObject];
    }

    if (mapping && destinationObject) {
        BOOL success = [self mapFromObject:mappableObject toObject:destinationObject atKeyPath:keyPath usingMapping:mapping];
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

- (NSArray *)mapCollection:(NSArray *)mappableObjects atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping
{
    NSAssert(mappableObjects != nil, @"Cannot map without an collection of mappable objects");
    NSAssert(mapping != nil, @"Cannot map without a mapping to consult");

    NSArray *objectsToMap = mappableObjects;
    if (mapping.forceCollectionMapping) {
        // If we have forced mapping of a dictionary, map each subdictionary
        if ([mappableObjects isKindOfClass:[NSDictionary class]]) {
            RKLogDebug(@"Collection mapping forced for NSDictionary, mapping each key/value independently...");
            objectsToMap = [NSMutableArray arrayWithCapacity:[mappableObjects count]];
            for (id key in mappableObjects) {
                NSDictionary *dictionaryToMap = [NSDictionary dictionaryWithObject:[mappableObjects valueForKey:key] forKey:key];
                [(NSMutableArray *)objectsToMap addObject:dictionaryToMap];
            }
        } else {
            RKLogWarning(@"Collection mapping forced but mappable objects is of type '%@' rather than NSDictionary", NSStringFromClass([mappableObjects class]));
        }
    }

    // Ensure we are mapping onto a mutable collection if there is a target
    NSMutableArray *mappedObjects = self.targetObject ? self.targetObject : [NSMutableArray arrayWithCapacity:[mappableObjects count]];
    if (NO == [mappedObjects respondsToSelector:@selector(addObject:)]) {
        NSString *errorMessage = [NSString stringWithFormat:
                                  @"Cannot map a collection of objects onto a non-mutable collection. Unexpected destination object type '%@'",
                                  NSStringFromClass([mappedObjects class])];
        [self addErrorWithCode:RKMappingErrorTypeMismatch message:errorMessage keyPath:keyPath userInfo:nil];
        return nil;
    }

    for (id mappableObject in objectsToMap) {
        id destinationObject = [self objectWithMapping:mapping andData:mappableObject];
        if (! destinationObject) {
            continue;
        }

        BOOL success = [self mapFromObject:mappableObject toObject:destinationObject atKeyPath:keyPath usingMapping:mapping];
        if (success) {
            [mappedObjects addObject:destinationObject];
        }
    }

    return mappedObjects;
}

// The workhorse of this entire process. Emits object loading operations
- (BOOL)mapFromObject:(id)mappableObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping
{
    NSAssert(destinationObject != nil, @"Cannot map without a target object to assign the results to");
    NSAssert(mappableObject != nil, @"Cannot map without a collection of attributes");
    NSAssert(mapping != nil, @"Cannot map without an mapping");

    RKLogDebug(@"Asked to map source object %@ with mapping %@", mappableObject, mapping);

    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:mappableObject destinationObject:destinationObject mapping:mapping];
    mappingOperation.dataSource = self.mappingOperationDataSource;
    if ([self.delegate respondsToSelector:@selector(mapper:willStartMappingOperation:forKeyPath:)]) {
        [self.delegate mapper:self willStartMappingOperation:mappingOperation forKeyPath:RKDelegateKeyPathFromKeyPath(keyPath)];
    }
    [mappingOperation start];
    if (mappingOperation.error) {
        if ([self.delegate respondsToSelector:@selector(mapper:didFailMappingOperation:forKeyPath:withError:)]) {
            [self.delegate mapper:self didFailMappingOperation:mappingOperation forKeyPath:RKDelegateKeyPathFromKeyPath(keyPath) withError:mappingOperation.error];
        }
        [self addError:mappingOperation.error];
     
        return NO;
    } else {
        if ([self.delegate respondsToSelector:@selector(mapper:didFinishMappingOperation:forKeyPath:)]) {
            [self.delegate mapper:self didFinishMappingOperation:mappingOperation forKeyPath:RKDelegateKeyPathFromKeyPath(keyPath)];
        }
        
        return YES;
    }
}

- (id)objectWithMapping:(RKMapping *)mapping andData:(id)mappableData
{
    NSAssert([mapping isKindOfClass:[RKMapping class]], @"Expected an RKMapping object");
    NSAssert(self.mappingOperationDataSource, @"Cannot find or instantiate objects without a data source");

    RKObjectMapping *objectMapping = nil;
    if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        objectMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:mappableData];
        if (! objectMapping) {
            RKLogDebug(@"Mapping %@ declined mapping for data %@: returned nil objectMapping", mapping, mappableData);
        }
    } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        objectMapping = (RKObjectMapping *)mapping;
    } else {
        NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
    }

    if (objectMapping) {
        return [self.mappingOperationDataSource mappingOperation:nil targetObjectForRepresentation:mappableData withMapping:objectMapping];
    }

    return nil;
}

- (id)performMappingForObject:(id)mappableValue atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping
{
    id mappingResult;
    if (mapping.forceCollectionMapping || [mappableValue isKindOfClass:[NSArray class]] || [mappableValue isKindOfClass:[NSSet class]]) {
        RKLogDebug(@"Found mappable collection at keyPath '%@': %@", keyPath, mappableValue);
        mappingResult = [self mapCollection:mappableValue atKeyPath:keyPath usingMapping:mapping];
    } else {
        RKLogDebug(@"Found mappable data at keyPath '%@': %@", keyPath, mappableValue);
        mappingResult = [self mapObject:mappableValue atKeyPath:keyPath usingMapping:mapping];
    }

    return mappingResult;
}

- (NSMutableDictionary *)performKeyPathMappingUsingMappingDictionary:(NSDictionary *)mappingsByKeyPath
{
    BOOL foundMappable = NO;
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    for (NSString *keyPath in mappingsByKeyPath) {
        if ([self isCancelled]) return nil;
        
        id mappingResult = nil;
        id mappableValue = nil;

        RKLogTrace(@"Examining keyPath '%@' for mappable content...", keyPath);

        if ([keyPath isEqual:[NSNull null]] || [keyPath isEqualToString:@""]) {
            mappableValue = self.sourceObject;
        } else {
            mappableValue = [self.sourceObject valueForKeyPath:keyPath];
        }

        // Not found...
        if (mappableValue == nil || mappableValue == [NSNull null] || [self isNullCollection:mappableValue]) {
            RKLogDebug(@"Found unmappable value at keyPath: %@", keyPath);

            if ([self.delegate respondsToSelector:@selector(mapper:didNotFindRepresentationOrArrayOfRepresentationsAtKeyPath:)]) {
                [self.delegate mapper:self didNotFindRepresentationOrArrayOfRepresentationsAtKeyPath:RKDelegateKeyPathFromKeyPath(keyPath)];
            }

            continue;
        }

        // Found something to map
        foundMappable = YES;
        RKMapping *mapping = [mappingsByKeyPath objectForKey:keyPath];
        if ([self.delegate respondsToSelector:@selector(mapper:didFindRepresentationOrArrayOfRepresentations:atKeyPath:)]) {
            [self.delegate mapper:self didFindRepresentationOrArrayOfRepresentations:mappableValue atKeyPath:RKDelegateKeyPathFromKeyPath(keyPath)];
        }

        mappingResult = [self performMappingForObject:mappableValue atKeyPath:keyPath usingMapping:mapping];

        if (mappingResult) {
            [results setObject:mappingResult forKey:keyPath];
        }
    }

    if (NO == foundMappable) return nil;
    return results;
}

- (void)cancel
{
    [super cancel];
    RKLogDebug(@"%@:%p received `cancel` message: cancelling mapping...", [self class], self);
    
    if ([self.delegate respondsToSelector:@selector(mapperDidCancelMapping:)]) {
        [self.delegate mapperDidCancelMapping:self];
    }
}

- (void)main
{
    NSAssert(self.sourceObject != nil, @"Cannot perform object mapping without a source object to map from");
    NSAssert(self.mappingsDictionary, @"Cannot perform object mapping without a dictionary of mappings");
    
    if ([self isCancelled]) return;

    RKLogDebug(@"Performing object mapping sourceObject: %@\n and targetObject: %@", self.sourceObject, self.targetObject);

    if ([self.delegate respondsToSelector:@selector(mapperWillStartMapping:)]) {
        [self.delegate mapperWillStartMapping:self];
    }

    // Perform the mapping
    BOOL foundMappable = NO;
    NSMutableDictionary *results = [self performKeyPathMappingUsingMappingDictionary:self.mappingsDictionary];
    if ([self isCancelled]) return;
    foundMappable = (results != nil);

    if ([self.delegate respondsToSelector:@selector(mapperDidFinishMapping:)]) {
        [self.delegate mapperDidFinishMapping:self];
    }

    // If we found nothing eligible for mapping in the content, add an unmappable key path error and fail mapping
    // If the content is empty, we don't consider it an error
    BOOL isEmpty = [self.sourceObject respondsToSelector:@selector(count)] && ([self.sourceObject count] == 0);
    if (foundMappable == NO && !isEmpty) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         NSLocalizedString(@"Unable to find any mappings for the given content", nil), NSLocalizedDescriptionKey,
                                         [NSNull null], RKMappingErrorKeyPathErrorKey,
                                         self.errors, RKDetailedErrorsKey,
                                         nil];
        NSError *compositeError = [[NSError alloc] initWithDomain:RKErrorDomain code:RKMappingErrorNotFound userInfo:userInfo];
        self.error = compositeError;
        return;
    }

    RKLogDebug(@"Finished performing object mapping. Results: %@", results);

    if (results) self.mappingResult = [[RKMappingResult alloc] initWithDictionary:results];
}

@end
