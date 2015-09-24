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

#import <RestKit/ObjectMapping/RKDynamicMapping.h>
#import <RestKit/ObjectMapping/RKMapperOperation.h>
#import <RestKit/ObjectMapping/RKMapperOperation_Private.h>
#import <RestKit/ObjectMapping/RKMappingErrors.h>
#import <RestKit/ObjectMapping/RKObjectMapping.h>
#import <RestKit/ObjectMapping/RKObjectMappingOperationDataSource.h>
#import <RestKit/Support/RKDictionaryUtilities.h>
#import <RestKit/Support/RKLog.h>

NSString * const RKMappingErrorKeyPathErrorKey = @"keyPath";

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitObjectMapping

static NSString *RKDelegateKeyPathFromKeyPath(NSString *keyPath)
{
    return ([keyPath isEqual:[NSNull null]]) ? nil : keyPath;
}


static NSString *RKFailureReasonErrorStringForMappingNotFoundError(id representation, NSDictionary *mappingsDictionary)
{
    NSMutableString *failureReason = [NSMutableString string];
    [failureReason appendFormat:@"The mapping operation was unable to find any nested object representations at the key paths searched: %@", [[[mappingsDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] componentsJoinedByString:@", "]];
    if ([representation respondsToSelector:@selector(allKeys)]) {
        [failureReason appendFormat:@"\nThe representation inputted to the mapper was found to contain nested object representations at the following key paths: %@", [[[representation allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] componentsJoinedByString:@", "]];
    }
    [failureReason appendFormat:@"\nThis likely indicates that you have misconfigured the key paths for your mappings."];
    return failureReason;
}

// Duplicating interface from `RKMappingOperation.m`
@interface RKMappingSourceObject : NSObject
- (instancetype)initWithObject:(id)object parentObject:(id)parentObject rootObject:(id)rootObject metadata:(NSArray *)metadata;
@end

@interface RKMappingOperation (Private)
@property (nonatomic, readwrite, getter=isNewDestinationObject) BOOL newDestinationObject;
@end

@interface RKMapperMetadata : NSObject
@property NSUInteger collectionIndex;
@property NSString *rootKeyPath;
@end

@implementation RKMapperMetadata
- (id)valueForUndefinedKey:(NSString *)key { return nil; }
@end

@interface RKMapperOperation ()

@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong) NSMutableArray *mappingErrors;
@property (nonatomic, strong) id representation;
@property (nonatomic, strong, readwrite) NSDictionary *mappingsDictionary;
@property (nonatomic, strong) NSMutableDictionary *mutableMappingInfo;
@end

@implementation RKMapperOperation

- (instancetype)init
{
    return [self initWithRepresentation:nil mappingsDictionary:nil];
}

- (instancetype)initWithRepresentation:(id)representation mappingsDictionary:(NSDictionary *)mappingsDictionary;
{
    self = [super init];
    if (self) {
        self.representation = representation;
        self.mappingsDictionary = mappingsDictionary;
        self.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    }

    return self;
}

- (NSDictionary *)mappingInfo
{
    return self.mutableMappingInfo;
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
            RKLogDebug(@"Found a collection containing only `NSNull` values, considering the collection unmappable...");
            return YES;
        }
    }

    return NO;
}

#pragma mark - Mapping Primitives

// Maps a singular object representation
- (id)mapRepresentation:(id)representation atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping
{
    NSAssert([representation respondsToSelector:@selector(setValue:forKeyPath:)], @"Expected self.object to be KVC compliant");
    id destinationObject = nil;
    BOOL isNewObject = NO;
    
    if (self.targetObject) {
        destinationObject = self.targetObject;
        RKObjectMapping *objectMapping = nil;
        if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
            objectMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:representation];
        } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
            objectMapping = (RKObjectMapping *)mapping;
        } else {
            NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
        }
        
        if (NO == [[self.targetObject class] isSubclassOfClass:objectMapping.objectClass]) {
            if ([_mappingsDictionary count] == 1) {
                NSString *errorMessage = [NSString stringWithFormat:
                                          @"Expected an object mapping for class of type '%@', provider returned one for '%@'",
                                          NSStringFromClass([self.targetObject class]), NSStringFromClass(objectMapping.objectClass)];
                [self addErrorWithCode:RKMappingErrorTypeMismatch message:errorMessage keyPath:keyPath userInfo:nil];
                return nil;
            } else {
                // There is more than one mapping present. We are likely mapping secondary key paths to new objects
                destinationObject = [self objectForRepresentation:representation withMapping:mapping];
                isNewObject = YES;
            }
        }
    } else {
        destinationObject = [self objectForRepresentation:representation withMapping:mapping];
        isNewObject = YES;
    }

    if (mapping && destinationObject) {
        NSArray *metadataList = [NSArray arrayWithObjects:@{ @"mapping": @{ @"rootKeyPath": keyPath } }, self.metadata, nil];
        BOOL success = [self mapRepresentation:representation toObject:destinationObject isNew:isNewObject atKeyPath:keyPath usingMapping:mapping metadataList:metadataList];
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

// Map a collection of object representations
- (NSArray *)mapRepresentations:(id)representations atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping
{
    NSAssert(representations != nil, @"Cannot map without an collection of mappable objects");
    NSAssert(mapping != nil, @"Cannot map without a mapping to consult");

    NSArray *objectsToMap = representations;
    if (mapping.forceCollectionMapping) {
        // If we have forced mapping of a dictionary, map each subdictionary
        if ([representations isKindOfClass:[NSDictionary class]]) {
            RKLogDebug(@"Collection mapping forced for NSDictionary, mapping each key/value independently...");
            objectsToMap = [NSMutableArray arrayWithCapacity:[representations count]];
            for (id key in representations) {
                NSDictionary *dictionaryToMap = @{key: [representations valueForKey:key]};
                [(NSMutableArray *)objectsToMap addObject:dictionaryToMap];
            }
        } else {
            RKLogWarning(@"Collection mapping forced but representations is of type '%@' rather than NSDictionary", NSStringFromClass([representations class]));
        }
    }
    
    RKMapperMetadata *mappingData = [RKMapperMetadata new];
    mappingData.rootKeyPath = keyPath;
    NSDictionary *metadata = @{ @"mapping": mappingData };
    NSArray *metadataList = [NSArray arrayWithObjects:metadata, self.metadata, nil];
    NSMutableArray *mappedObjects = [NSMutableArray arrayWithCapacity:[representations count]];
    [objectsToMap enumerateObjectsUsingBlock:^(id mappableObject, NSUInteger index, BOOL *stop) {
        if (mappableObject == [NSNull null]) { return; }
        
        id destinationObject = [self objectForRepresentation:mappableObject withMapping:mapping];
        if (destinationObject) {
            mappingData.collectionIndex = index;
            BOOL success = [self mapRepresentation:mappableObject toObject:destinationObject isNew:YES atKeyPath:keyPath usingMapping:mapping metadataList:metadataList];
            if (success) [mappedObjects addObject:destinationObject];
        }
        *stop = [self isCancelled];
    }];

    return mappedObjects;
}

// The workhorse of this entire process. Emits object loading operations
- (BOOL)mapRepresentation:(id)mappableObject toObject:(id)destinationObject isNew:(BOOL)newDestination atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping metadataList:(NSArray *)metadataList
{
    NSAssert(destinationObject != nil, @"Cannot map without a target object to assign the results to");
    NSAssert(mappableObject != nil, @"Cannot map without a collection of attributes");
    NSAssert(mapping != nil, @"Cannot map without an mapping");

    RKLogDebug(@"Asked to map source object %@ with mapping %@", mappableObject, mapping);

    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:mappableObject destinationObject:destinationObject mapping:mapping metadataList:metadataList];
    mappingOperation.dataSource = self.mappingOperationDataSource;
    mappingOperation.newDestinationObject = newDestination;
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
        
        if (mappingOperation.mappingInfo) {
            id infoKey = keyPath ?: [NSNull null];
            NSMutableArray *infoForKeyPath = (self.mutableMappingInfo)[infoKey];
            if (infoForKeyPath) {
                [infoForKeyPath addObject:mappingOperation.mappingInfo];
            } else {
                infoForKeyPath = [NSMutableArray arrayWithObject:mappingOperation.mappingInfo];
                [self.mutableMappingInfo setValue:infoForKeyPath forKey:infoKey];
            }
        }
        
        return YES;
    }
}

- (id)objectForRepresentation:(id)representation withMapping:(RKMapping *)mapping
{
    NSAssert([mapping isKindOfClass:[RKMapping class]], @"Expected an RKMapping object");
    NSAssert(self.mappingOperationDataSource, @"Cannot find or instantiate objects without a data source");

    RKObjectMapping *objectMapping = nil;
    if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        objectMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:representation];
        if (! objectMapping) {
            RKLogDebug(@"Mapping %@ declined mapping for representation %@: returned nil objectMapping", mapping, representation);
        }
    } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        objectMapping = (RKObjectMapping *)mapping;
    } else {
        NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
    }

    if (objectMapping) {
        id object = nil;
        if ([self.mappingOperationDataSource respondsToSelector:@selector(mappingOperation:targetObjectForMapping:inRelationship:)])
        {
            object = [self.mappingOperationDataSource mappingOperation:nil targetObjectForMapping:objectMapping inRelationship:nil];
        }
        if (object == nil)
        {
            // Ensure that we are working with a dictionary when we call down into the data source
            NSDictionary *representationDictionary = [representation isKindOfClass:[NSDictionary class]] ? representation : @{ [NSNull null]: representation };
            id mappingSourceObject = [[RKMappingSourceObject alloc] initWithObject:representationDictionary parentObject:nil rootObject:representation metadata:self.metadata? @[self.metadata] : nil];
            object = [self.mappingOperationDataSource mappingOperation:nil targetObjectForRepresentation:mappingSourceObject withMapping:objectMapping inRelationship:nil];
        }
        return object;
    }

    return nil;
}

- (id)mapRepresentationOrRepresentations:(id)mappableValue atKeyPath:(NSString *)keyPath usingMapping:(RKMapping *)mapping
{
    id mappingResult;
    if (mapping.forceCollectionMapping || [mappableValue isKindOfClass:[NSArray class]] || [mappableValue isKindOfClass:[NSSet class]]) {
        RKLogDebug(@"Found mappable collection at keyPath '%@': %@", keyPath, mappableValue);
        mappingResult = [self mapRepresentations:mappableValue atKeyPath:keyPath usingMapping:mapping];
    } else {
        RKLogDebug(@"Found mappable data at keyPath '%@': %@", keyPath, mappableValue);
        mappingResult = [self mapRepresentation:mappableValue atKeyPath:keyPath usingMapping:mapping];
    }

    return mappingResult;
}

#pragma mark -

- (NSMutableDictionary *)mapSourceRepresentationWithMappingsDictionary:(NSDictionary *)mappingsByKeyPath
{
    BOOL foundMappable = NO;
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    for (NSString *keyPath in mappingsByKeyPath) {
        if ([self isCancelled]) return nil;
        
        @autoreleasepool {
            id mappingResult = nil;
            id nestedRepresentation = nil;

            RKLogTrace(@"Examining keyPath '%@' for mappable content...", keyPath);

            if ([keyPath isEqual:[NSNull null]] || [keyPath isEqualToString:@""]) {
                nestedRepresentation = self.representation;
            } else {
                nestedRepresentation = [self.representation valueForKeyPath:keyPath];
            }

            // Not found...
            if (nestedRepresentation == nil || nestedRepresentation == [NSNull null] || [self isNullCollection:nestedRepresentation]) {
                RKLogDebug(@"Found unmappable value at keyPath: %@", keyPath);

                if ([self.delegate respondsToSelector:@selector(mapper:didNotFindRepresentationOrArrayOfRepresentationsAtKeyPath:)]) {
                    [self.delegate mapper:self didNotFindRepresentationOrArrayOfRepresentationsAtKeyPath:RKDelegateKeyPathFromKeyPath(keyPath)];
                }

                continue;
            }

            // Found something to map
            foundMappable = YES;
            RKMapping *mapping = mappingsByKeyPath[keyPath];
            if ([self.delegate respondsToSelector:@selector(mapper:didFindRepresentationOrArrayOfRepresentations:atKeyPath:)]) {
                [self.delegate mapper:self didFindRepresentationOrArrayOfRepresentations:nestedRepresentation atKeyPath:RKDelegateKeyPathFromKeyPath(keyPath)];
            }

            mappingResult = [self mapRepresentationOrRepresentations:nestedRepresentation atKeyPath:keyPath usingMapping:mapping];

            if (mappingResult) {
                results[keyPath] = mappingResult;
            }
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
    NSAssert(self.representation != nil, @"Cannot perform object mapping without a source object to map from");
    NSAssert(self.mappingsDictionary, @"Cannot perform object mapping without a dictionary of mappings");
    
    if ([self isCancelled]) return;
    self.mutableMappingInfo = [NSMutableDictionary dictionary];
    self.mappingErrors = [NSMutableArray new];

    RKLogDebug(@"Executing mapping operation for representation: %@\n and targetObject: %@", self.representation, self.targetObject);

    if ([self.delegate respondsToSelector:@selector(mapperWillStartMapping:)]) {
        [self.delegate mapperWillStartMapping:self];
    }

    // Perform the mapping
    BOOL foundMappable = NO;
    NSMutableDictionary *results = [self mapSourceRepresentationWithMappingsDictionary:self.mappingsDictionary];
    if ([self isCancelled]) return;
    foundMappable = (results != nil);    

    // If we found nothing eligible for mapping in the content, add an unmappable key path error and fail mapping
    // If the content is empty, we don't consider it an error
    BOOL isEmpty = [self.representation respondsToSelector:@selector(count)] && ([self.representation count] == 0);
    if (foundMappable == NO && !isEmpty) {
        NSMutableDictionary *userInfo = [@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No mappable object representations were found at the key paths searched.", nil),
                                            NSLocalizedFailureReasonErrorKey: RKFailureReasonErrorStringForMappingNotFoundError(self.representation, self.mappingsDictionary),
                                            RKMappingErrorKeyPathErrorKey: [NSNull null],
                                            RKDetailedErrorsKey: self.errors} mutableCopy];
        NSError *compositeError = [[NSError alloc] initWithDomain:RKErrorDomain code:RKMappingErrorNotFound userInfo:userInfo];
        self.error = compositeError;
    } else {
        if (results) self.mappingResult = [[RKMappingResult alloc] initWithDictionary:results];
    }

    RKLogDebug(@"Finished performing object mapping. Results: %@", results);
    if ([self.delegate respondsToSelector:@selector(mapperDidFinishMapping:)]) {
        [self.delegate mapperDidFinishMapping:self];
    }
}

- (BOOL)execute:(NSError **)error
{
    [self start];
    if (error) *error = self.error;
    return self.mappingResult != nil;
}

@end
