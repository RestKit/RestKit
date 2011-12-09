//
//  RKObjectManagerSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters
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

@interface RKObjectManagerSpec : RKSpec {
	RKObjectManager* _objectManager;
}

@end

@implementation RKObjectManagerSpec

- (void)setUp {
    _objectManager = RKSpecNewObjectManager();
	_objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
    [RKObjectManager setSharedManager:_objectManager];
    [_objectManager.objectStore deletePersistantStore];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    humanMapping.rootKeyPath = @"human";
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKManagedObjectMapping* catObjectMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    [catObjectMapping addRelationshipMapping:[RKObjectRelationshipMapping mappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catObjectMapping]];
    
    [provider setMapping:humanMapping forKeyPath:@"human"];
    [provider setMapping:humanMapping forKeyPath:@"humans"];
    
    RKObjectMapping* humanSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [humanSerialization addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [provider setSerializationMapping:humanSerialization forClass:[RKHuman class]];
    _objectManager.mappingProvider = provider;
	
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKHuman class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    _objectManager.router = router;
    
//    RKSpecStubNetworkAvailability(YES);
}

- (void)testShouldSetTheAcceptHeaderAppropriatelyForTheFormat {
	assertThat([_objectManager.client.HTTPHeaders valueForKey:@"Accept"], is(equalTo(@"application/json")));
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldUpdateACoreDataBackedTargetObject {
    RKHuman* temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.objectStore.managedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.managedObjectContext];
    temporaryHuman.name = @"My Name";
    
    // TODO: We should NOT have to save the object store here to make this
    // spec pass. Without it we are crashing inside the mapper internals. Believe
    // that we just need a way to save the context before we begin mapping or something
    // on success. Always saving means that we can abandon objects on failure...
    [_objectManager.objectStore save];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    [_objectManager postObject:temporaryHuman delegate:loader];
    [loader waitForResponse];
    
    assertThat(loader.objects, isNot(empty()));
    RKHuman* human = (RKHuman*)[loader.objects objectAtIndex:0];
    assertThat(human, is(equalTo(temporaryHuman)));
    assertThat(human.railsID, is(equalToInt(1)));
}

- (void)testShouldDeleteACoreDataBackedTargetObjectOnError {
    RKHuman* temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.objectStore.managedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.managedObjectContext];
    temporaryHuman.name = @"My Name";
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping mapAttributes:@"name", nil];
    
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];    
    NSString* resourcePath = @"/humans/fail";
    RKObjectLoader* objectLoader = [_objectManager objectLoaderWithResourcePath:resourcePath delegate:loader];
    objectLoader.method = RKRequestMethodPOST;
    objectLoader.targetObject = temporaryHuman;
    objectLoader.serializationMapping = mapping;
	[objectLoader send];
    [loader waitForResponse];

    assertThat(temporaryHuman.managedObjectContext, is(equalTo(nil)));
}

- (void)testShouldNotDeleteACoreDataBackedTargetObjectOnErrorIfItWasAlreadySaved {
    RKHuman* temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.objectStore.managedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.managedObjectContext];
    temporaryHuman.name = @"My Name";
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping mapAttributes:@"name", nil];
    
    // Save it to suppress deletion
    [_objectManager.objectStore save];
    
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];    
    NSString* resourcePath = @"/humans/fail";
    RKObjectLoader* objectLoader = [_objectManager objectLoaderWithResourcePath:resourcePath delegate:loader];
    objectLoader.method = RKRequestMethodPOST;
    objectLoader.targetObject = temporaryHuman;
    objectLoader.serializationMapping = mapping;
	[objectLoader send];
    [loader waitForResponse];
    
    assertThat(temporaryHuman.managedObjectContext, is(equalTo(_objectManager.objectStore.managedObjectContext)));
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldLoadAHuman {
    assertThatBool([RKClient sharedClient].isNetworkReachable, is(equalToBool(YES)));
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];    
	[_objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:loader];
	[loader waitForResponse];
    assertThat(loader.failureError, is(nilValue()));
    assertThat(loader.objects, isNot(empty()));
	RKHuman* blake = (RKHuman*)[loader.objects objectAtIndex:0];
	assertThat(blake.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldLoadAllHumans {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
	[_objectManager loadObjectsAtResourcePath:@"/JSON/humans/all.json" delegate:loader];
	[loader waitForResponse];
	NSArray* humans = (NSArray*) loader.objects;
	assertThatUnsignedInteger([humans count], is(equalToInt(2)));	
	assertThat([humans objectAtIndex:0], is(instanceOf([RKHuman class])));
}

- (void)testShouldHandleConnectionFailures {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://127.0.0.1:3001"];
	RKObjectManager* modelManager = [RKObjectManager objectManagerWithBaseURL:localBaseURL];
    modelManager.client.requestQueue.suspended = NO;
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
	[modelManager loadObjectsAtResourcePath:@"/JSON/humans/1" delegate:loader];
	[loader waitForResponse];
	assertThatBool(loader.success, is(equalToBool(NO)));
}

- (void)testShouldPOSTAnObject {
    RKObjectManager* manager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    assertThatBool([RKClient sharedClient].isNetworkReachable, is(equalToBool(YES)));
    
    RKObjectRouter* router = [[RKObjectRouter new] autorelease];
    [router routeClass:[RKObjectMapperSpecModel class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    manager.router = router;
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];
    [manager.mappingProvider setMapping:mapping forKeyPath:@"human"];
    [manager.mappingProvider setSerializationMapping:mapping forClass:[RKObjectMapperSpecModel class]];
    
    RKObjectMapperSpecModel* human = [[RKObjectMapperSpecModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    [manager postObject:human delegate:loader];
    [loader waitForResponse];
    
    // NOTE: The /humans endpoint returns a canned response, we are testing the plumbing
    // of the object manager here.
    assertThat(human.name, is(equalTo(@"My Name")));
}

- (void)testShouldNotSetAContentBodyOnAGET {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.router routeClass:[RKObjectMapperSpecModel class] toResourcePath:@"/humans/1"];
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectMapperSpecModel* human = [[RKObjectMapperSpecModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    RKObjectLoader* loader = [objectManager getObject:human delegate:responseLoader];
    [responseLoader waitForResponse];
    RKLogCritical(@"%@", [loader.URLRequest allHTTPHeaderFields]);
    assertThat([loader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldNotSetAContentBodyOnADELETE {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.router routeClass:[RKObjectMapperSpecModel class] toResourcePath:@"/humans/1"];
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectMapperSpecModel* human = [[RKObjectMapperSpecModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    RKObjectLoader* loader = [objectManager deleteObject:human delegate:responseLoader];
    [responseLoader waitForResponse];
    RKLogCritical(@"%@", [loader.URLRequest allHTTPHeaderFields]);
    assertThat([loader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

#pragma mark - Block Helpers

- (void)testShouldLetYouLoadObjectsWithABlock {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:responseLoader block:^(RKObjectLoader* loader) {
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.success, is(equalToBool(YES)));
    assertThat(responseLoader.objects, hasCountOf(1));
}

- (void)testShouldAllowYouToOverrideTheRoutedResourcePath {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.router routeClass:[RKObjectMapperSpecModel class] toResourcePath:@"/humans/2"];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectMapperSpecModel* human = [[RKObjectMapperSpecModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager deleteObject:human delegate:responseLoader block:^(RKObjectLoader* loader) {
        loader.resourcePath = @"/humans/1";
    }];
    [responseLoader waitForResponse];
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldAllowYouToUseObjectHelpersWithoutRouting {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectMapperSpecModel* human = [[RKObjectMapperSpecModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager deleteObject:human delegate:responseLoader block:^(RKObjectLoader* loader) {
        loader.resourcePath = @"/humans/1";
    }];
    [responseLoader waitForResponse];
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldAllowYouToSkipTheMappingProvider {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectMapperSpecModel* human = [[RKObjectMapperSpecModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager deleteObject:human delegate:responseLoader block:^(RKObjectLoader* loader) {
        loader.resourcePath = @"/humans/1";
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.success, is(equalToBool(YES)));
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));    
}

- (void)testShouldLetYouOverloadTheParamsOnAnObjectLoaderRequest {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKObjectMapperSpecModel* human = [[RKObjectMapperSpecModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    NSDictionary *myParams = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
    RKObjectLoader* loader = [objectManager sendObject:human delegate:responseLoader block:^(RKObjectLoader* loader) {
        loader.method = RKRequestMethodPOST;
        loader.resourcePath = @"/humans/1";
        loader.objectMapping = mapping;
        loader.params = myParams;
    }];
    [responseLoader waitForResponse];
    assertThat(loader.params, is(equalTo(myParams)));
}

@end
