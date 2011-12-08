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
#import "RKObjectMappingProvider.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "RKObjectMapperSpecModel.h"

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
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider objectMappingProvider];
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

@end
