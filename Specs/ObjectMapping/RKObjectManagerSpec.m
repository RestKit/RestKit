//
//  RKObjectManagerSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectManager.h"
#import "RKManagedObjectStore.h"
#import "RKSpecResponseLoader.h"
#import "RKObjectMappingProvider.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "RKObjectMapperSpecModel.h"

@interface RKObjectManagerSpec : RKSpec {
	RKObjectManager* _objectManager;
	RKSpecResponseLoader* _responseLoader;
}

@end

@implementation RKObjectManagerSpec

- (void)beforeAll {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://localhost:4567"]; //getenv("RESTKIT_IP_ADDRESS")
	_objectManager = [[RKObjectManager objectManagerWithBaseURL:localBaseURL] retain];
	_objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
    [RKObjectManager setSharedManager:_objectManager];
    [_objectManager.objectStore deletePersistantStore];
    
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider new] autorelease];
    
    RKObjectMapping* humanMapping = [RKObjectMapping mappingForClass:[RKHuman class]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKObjectMapping* catObjectMapping = [RKObjectMapping mappingForClass:[RKCat class]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    [catObjectMapping addRelationshipMapping:[RKObjectRelationshipMapping mappingFromKeyPath:@"cats" toKeyPath:@"cats" objectMapping:catObjectMapping]];
    
    [provider setMapping:humanMapping forKeyPath:@"human"];
    [provider setMapping:humanMapping forKeyPath:@"humans"];
    
    RKObjectMapping* humanSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [humanSerialization addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [provider setMapping:humanSerialization forClass:[RKHuman class]];
    _objectManager.mappingProvider = provider;
	
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKHuman class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    _objectManager.router = router;
    
	_responseLoader	= [[RKSpecResponseLoader alloc] init];
}

- (void)itShouldSetTheAcceptHeaderAppropriatelyForTheFormat {
	[expectThat([_objectManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/json")];
}

// TODO: Move to Core Data specific spec file...
- (void)itShouldUpdateACoreDataBackedTargetObject {
    RKHuman* temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.objectStore.managedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.managedObjectContext];
    temporaryHuman.name = @"My Name";
    
    // TODO: We should NOT have to save the object store here to make this
    // spec pass. Without it we are crashing inside the mapper internals. Believe
    // that we just need a way to save the context before we begin mapping or something
    // on success. Always saving means that we can abandon objects on failure...
    [_objectManager.objectStore save];
    [_objectManager postObject:temporaryHuman delegate:_responseLoader];
    [_responseLoader waitForResponse];
    
    RKHuman* human = (RKHuman*)[_responseLoader.objects objectAtIndex:0];
    assertThat(human, is(equalTo(temporaryHuman)));
    assertThat(human.railsID, is(equalToInt(1)));
}

// TODO: Move to Core Data specific spec file...
- (void)itShouldLoadAHuman {
	[_objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:_responseLoader];
    _responseLoader.timeout = 200;
	[_responseLoader waitForResponse];
    [expectThat(_responseLoader.failureError) should:be(nil)];
    assertThat(_responseLoader.objects, isNot(empty()));
	RKHuman* blake = (RKHuman*)[_responseLoader.objects objectAtIndex:0];
	NSLog(@"Blake: %@ (name = %@)", blake, blake.name);
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	[_objectManager loadObjectsAtResourcePath:@"/JSON/humans/all.json" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.objects;
	[expectThat([humans count]) should:be(2)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([RKHuman class])];
}

- (void)itShouldHandleConnectionFailures {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://127.0.0.1:3001"];
	RKObjectManager* modelManager = [RKObjectManager objectManagerWithBaseURL:localBaseURL];
	[modelManager loadObjectsAtResourcePath:@"/JSON/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	[expectThat(_responseLoader.success) should:be(NO)];
}

- (void)itShouldPOSTAnObject {
    RKObjectManager* manager = RKSpecNewObjectManager();
    RKObjectRouter* router = [[RKObjectRouter new] autorelease];
    [router routeClass:[RKObjectMapperSpecModel class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    manager.router = router;
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [manager.mappingProvider setMapping:mapping forKeyPath:@"human"];
    [manager.mappingProvider setMapping:mapping forClass:[RKObjectMapperSpecModel class]];
    
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

@end
