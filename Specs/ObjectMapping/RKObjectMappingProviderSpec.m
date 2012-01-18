//
//  RKObjectMappingProviderSpec.m
//  RestKit
//
//  Created by Greg Combs on 9/18/11.
//  Copyright 2011 Two Toasters
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

#import "RKSpecEnvironment.h"
#import "RKObjectManager.h"
#import "RKManagedObjectStore.h"
#import "RKSpecResponseLoader.h"
#import "RKManagedObjectMapping.h"
#import "RKObjectMappingProvider+Contexts.h"
#import "RKObjectMappingProvider.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "RKObjectMapperSpecModel.h"
#import "RKOrderedDictionary.h"

@interface RKObjectMappingProviderSpec : RKSpec {
	RKObjectManager* _objectManager;
}

@end

@implementation RKObjectMappingProviderSpec

- (void)setUp {
    _objectManager = RKSpecNewObjectManager();
	_objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
    [RKObjectManager setSharedManager:_objectManager];
    [_objectManager.objectStore deletePersistantStore];
}

- (void)testShouldFindAnExistingObjectMappingForAClass {
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    assertThat(humanMapping, isNot(equalTo(nil)));
    [humanMapping mapAttributes:@"name", nil];
    [_objectManager.mappingProvider addObjectMapping:humanMapping];
    NSObject <RKObjectMappingDefinition> *returnedMapping = [_objectManager.mappingProvider objectMappingForClass:[RKHuman class]];
    assertThat(returnedMapping, isNot(equalTo(nil)));
    assertThat(returnedMapping, is(equalTo(humanMapping)));
}

- (void)testShouldFindAnExistingObjectMappingForAKeyPath {
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    assertThat(catMapping, isNot(equalTo(nil)));
    [catMapping mapAttributes:@"name", nil];
    [_objectManager.mappingProvider setMapping:catMapping forKeyPath:@"cat"];
    NSObject <RKObjectMappingDefinition> *returnedMapping = [_objectManager.mappingProvider mappingForKeyPath:@"cat"];
    assertThat(returnedMapping, isNot(equalTo(nil)));
    assertThat(returnedMapping, is(equalTo(catMapping)));
}

- (void)testShouldAllowYouToRemoveAMappingByKeyPath {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    assertThat(catMapping, isNot(equalTo(nil)));
    [catMapping mapAttributes:@"name", nil];
    [mappingProvider setMapping:catMapping forKeyPath:@"cat"];
    NSObject <RKObjectMappingDefinition> *returnedMapping = [mappingProvider mappingForKeyPath:@"cat"];
    assertThat(returnedMapping, isNot(equalTo(nil)));
    [mappingProvider removeMappingForKeyPath:@"cat"];
    returnedMapping = [mappingProvider mappingForKeyPath:@"cat"];
    assertThat(returnedMapping, is(nilValue()));
}

- (void)testSettingMappingInAContext {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    STAssertNoThrow([mappingProvider setMapping:mapping context:1], nil);
}

- (void)testRetrievalOfMapping {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping context:1];
    assertThat([mappingProvider mappingForContext:1], is(equalTo(mapping)));
}

- (void)testRetrievalOfMappingsCollectionForUndefinedContextReturnsEmptyArray {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    NSArray *collection = [mappingProvider mappingsForContext:1];
    assertThat(collection, is(empty()));
}

- (void)testRetrievalOfMappingsCollectionWhenSingleMappingIsStoredRaisesError {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping context:1];
    STAssertThrows([mappingProvider mappingsForContext:1], @"Expected collection mapping retrieval to throw due to storage of single mapping");
}

- (void)testAddingMappingToCollectionContext {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    STAssertNoThrow([mappingProvider addMapping:mapping context:1], nil);
}

- (void)testRetrievalOfMappingCollection {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping_1 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider addMapping:mapping_1 context:1];
    RKObjectMapping *mapping_2 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider addMapping:mapping_2 context:1];
    NSArray *collection = [mappingProvider mappingsForContext:1];
    assertThat(collection, hasItems(mapping_1, mapping_2, nil));
}

- (void)testRetrievalOfMappingCollectionReturnsImmutableArray {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping_1 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider addMapping:mapping_1 context:1];
    RKObjectMapping *mapping_2 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider addMapping:mapping_2 context:1];
    NSArray *collection = [mappingProvider mappingsForContext:1];
    assertThat(collection, isNot(instanceOf([NSMutableArray class])));
}

- (void)testRemovalOfMappingFromCollection {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping_1 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider addMapping:mapping_1 context:1];
    RKObjectMapping *mapping_2 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider addMapping:mapping_2 context:1];
    [mappingProvider removeMapping:mapping_1 context:1];
    NSArray *collection = [mappingProvider mappingsForContext:1];
    assertThat(collection, onlyContains(mapping_2, nil));
}

- (void)testAttemptToRemoveMappingFromContextThatDoesNotIncludeItRaisesError {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    STAssertThrows([mappingProvider removeMapping:mapping context:1], @"Removal of mapping not included in context should raise an error.");
}

- (void)testSettingMappingForKeyPathInContext {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    STAssertNoThrow([mappingProvider setMapping:mapping forKeyPath:@"testing" context:1], nil);
}

- (void)testRetrievalOfMappingForKeyPathInContext {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping forKeyPath:@"testing" context:1];
    assertThat([mappingProvider mappingForKeyPath:@"testing" context:1], is(equalTo(mapping)));
}

- (void)testRemovalOfMappingByKeyPathInContext {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping forKeyPath:@"testing" context:1];
    [mappingProvider removeMappingForKeyPath:@"testing" context:1];
    assertThat([mappingProvider mappingForKeyPath:@"testing" context:1], is(nilValue()));
}

- (void)testSettingMappingForPathMatcherCreatesOrderedDictionary {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping forPattern:@"/articles/:id" context:1];
    id contextValue = [mappingProvider valueForContext:1];
    assertThat(contextValue, is(instanceOf([RKOrderedDictionary class])));
}

- (void)testSettingMappingForPathMatcherCreatesDictionaryWithPathMatcherAsKey {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping forPattern:@"/articles/:id" context:1];
    NSDictionary *contextValue = [mappingProvider valueForContext:1];
    assertThat([contextValue allKeys], contains(@"/articles/:id", nil));
}

- (void)testSettingMappingForPathMatcherCreatesDictionaryWithMappingAsValue {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping forPattern:@"/articles/:id" context:1];
    NSDictionary *contextValue = [mappingProvider valueForContext:1];
    assertThat([contextValue allValues], contains(mapping, nil));
}

- (void)testRetrievalOfMappingForPathMatcher {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping forPattern:@"/articles/:id" context:1];
    
    id<RKObjectMappingDefinition> matchedMapping = [mappingProvider mappingForPatternMatchingString:@"/articles/12345" context:1];
    assertThat(matchedMapping, is(equalTo(mapping)));
}

- (void)testRetrievalOfMappingForPathMatcherIncludingQueryParameters {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping forPattern:@"/articles/:id" context:1];
    
    id<RKObjectMappingDefinition> matchedMapping = [mappingProvider mappingForPatternMatchingString:@"/articles/12345?page=5&this=that" context:1];
    assertThat(matchedMapping, is(equalTo(mapping)));
}

- (void)testRetrievalOfMappingForPathMatcherWithMultipleEntries {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
        
    RKObjectMapping *mapping_2 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_2 forPattern:@"/articles/:id\\.json" context:1];
    
    RKObjectMapping *mapping_3 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_3 forPattern:@"/articles/:id\\.xml" context:1];
    
    RKObjectMapping *mapping_4 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_4 forPattern:@"/articles/:id/comments/:id" context:1];
    
    RKObjectMapping *mapping_1 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_1 forPattern:@"/articles/:id" context:1];
    
    // Test them
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345" context:1], is(equalTo(mapping_1)));
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345.json" context:1], is(equalTo(mapping_2)));
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345.xml" context:1], is(equalTo(mapping_3)));
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345/comments/3" context:1], is(equalTo(mapping_4)));
}

- (void)testRetrievalOfMappingForPathMatcherWithEntriesInsertedByIndex {
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    
    RKObjectMapping *mapping_2 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_2 forPattern:@"/articles/:id\\.json" atIndex:0 context:1];
    
    RKObjectMapping *mapping_3 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_3 forPattern:@"/articles/:id\\.xml" atIndex:0 context:1];
    
    RKObjectMapping *mapping_4 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_4 forPattern:@"/articles/:id/comments/:id" atIndex:1 context:1];
    
    RKObjectMapping *mapping_1 = [RKObjectMapping mappingForClass:[NSMutableArray class]];
    [mappingProvider setMapping:mapping_1 forPattern:@"/articles/:id" atIndex:3 context:1];
    
    // Test them
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345" context:1], is(equalTo(mapping_1)));
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345.json" context:1], is(equalTo(mapping_2)));
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345.xml" context:1], is(equalTo(mapping_3)));
    assertThat([mappingProvider mappingForPatternMatchingString:@"/articles/12345/comments/3" context:1], is(equalTo(mapping_4)));
}

@end
