//
//  RKMappingInverter.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import "RKMappingInverter.h"
#import "RKObjectMapping.h"
#import "RKAttributeMapping.h"
#import "RKRelationshipMapping.h"
#import "RKDynamicMapping.h"
#import "RKLog.h"


// We need to expose a few private methods and properties to the inverter
@interface RKObjectMappingMatcher (Private_Inversion)
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) NSString *destinationKeyPath;
@property (nonatomic, strong, readwrite) id expectedValue;
@end

@interface RKObjectMapping (Private_Inversion)
- (void)copyPropertiesFromMapping:(RKObjectMapping *)mapping;
@end

@interface RKDynamicMapping (Private_Inversion)
@property (nonatomic, copy) RKObjectMapping *(^objectMappingForRepresentationBlock)(id representation);
@end



@implementation RKMappingInverter

- (id)initWithMapping:(RKMapping *)mapping
{
    self = [self init];
    if (self) {
        self.mapping = mapping;
        self.invertedMappings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (RKMapping *)invertMapping:(RKMapping *)mapping
{
    if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        RKObjectMapping *objectMapping = (RKObjectMapping *) mapping;
        return [self invertObjectMapping:objectMapping];
        
    } else if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        RKDynamicMapping *dynamicMapping = (RKDynamicMapping *) mapping;
        return [self invertDynamicMapping:dynamicMapping];
    } else {
        RKLogWarning(@"Unable to generate inverse mapping for mapping: %@ ",  NSStringFromClass([mapping class]));
        return nil;
    }
}

- (RKMapping *)inverseMapping
{
    return [self invertMapping:self.mapping];
}

#pragma mark - Concrete Mapping Inversion

- (RKObjectMapping *)invertObjectMapping:(RKObjectMapping *)mapping
{
    // Use existing mapping
    NSValue *dictionaryKey = [NSValue valueWithNonretainedObject:mapping];
    RKObjectMapping *inverseMapping = [self.invertedMappings objectForKey:dictionaryKey];
    if (inverseMapping) return inverseMapping;
    // ... or create new one
    inverseMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [self.invertedMappings setObject:mapping forKey:dictionaryKey];
    [inverseMapping copyPropertiesFromMapping:mapping];

    for (RKAttributeMapping *attributeMapping in mapping.attributeMappings) {
        [inverseMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:attributeMapping.destinationKeyPath
                                                                                 toKeyPath:attributeMapping.sourceKeyPath]];
    }
    
    for (RKRelationshipMapping *relationshipMapping in mapping.relationshipMappings) {
        RKObjectMapping *actualMapping = (RKObjectMapping *) relationshipMapping.mapping;
        RKMapping *inverseActualMapping = [self invertMapping:actualMapping];
        if (inverseActualMapping) {
            [inverseMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:relationshipMapping.destinationKeyPath
                                                                                           toKeyPath:relationshipMapping.sourceKeyPath
                                                                                         withMapping:inverseActualMapping]];
        }
    }
    
    return inverseMapping;
}

- (RKDynamicMapping *)invertDynamicMapping:(RKDynamicMapping *)mapping
{
    if (mapping.objectMappingForRepresentationBlock != nil) {
        RKLogWarning(@"Cannot invert the selection block in a dynamic mapping. Skipping the selection block.");
    }
    
    // Use existing mapping
    NSValue *dictionaryKey = [NSValue valueWithNonretainedObject:mapping];
    RKDynamicMapping *inverseMapping = [self.invertedMappings objectForKey:dictionaryKey];
    if (inverseMapping) return inverseMapping;
    // ... or create new one
    inverseMapping = [[RKDynamicMapping alloc] init];
    [self.invertedMappings setObject:mapping forKey:dictionaryKey];
    
    for (RKObjectMappingMatcher *matcher in mapping.matchers) {
        if ([matcher respondsToSelector:@selector(destinationKeyPath)]) {
            RKObjectMapping *inverseObjectMapping = (RKObjectMapping *) [self invertMapping:matcher.objectMapping];
            if (inverseObjectMapping) {
                RKObjectMappingMatcher *inverseMatcher = [RKObjectMappingMatcher matcherWithSourceKeyPath:matcher.destinationKeyPath
                                                                                       destinationKeyPath:matcher.keyPath
                                                                                            expectedValue:matcher.expectedValue
                                                                                            objectMapping:inverseObjectMapping];
                [inverseMapping addMatcher:inverseMatcher];
            }
        } else if ([matcher respondsToSelector:@selector(keyPath)]) {
            RKObjectMapping *inverseObjectMapping = (RKObjectMapping *) [self invertMapping:matcher.objectMapping];
            if (inverseObjectMapping) {
                RKObjectMappingMatcher *inverseMatcher = [RKObjectMappingMatcher matcherWithKeyPath:matcher.keyPath
                                                                                      expectedValue:matcher.expectedValue
                                                                                      objectMapping:inverseObjectMapping];
                [inverseMapping addMatcher:inverseMatcher];
            }
        } else {
            RKLogWarning(@"Cannot invert matcher without a key path. Skipping matcher.");
            continue;
        }
    }
    
    return inverseMapping;
}

@end
