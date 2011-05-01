//
//  RKObjectMappingNextGenSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "RKSpecEnvironment.h"
#import "RKJSONParser.h"
#import "RKObjectMapping.h"
#import "RKObjectMappingOperation.h"
#import "RKObjectElementMapping.h"

/*!
 Responsible for providing object mappings to an instance of the object mapper
 by evaluating the current keyPath being operated on
 */
@protocol RKObjectMappingProvider <NSObject>

@required
/*!
 Returns the object mapping that is appropriate to use for a given keyPath or nil if
 the keyPath is not mappable.
 */
- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath;

/*!
 Returns the object mapping for an instance of a class occuring at a particular keyPath
 
 This method is consulted by the object mapper when the destination class for an object is known (i.e. targetObject is set)
 */
- (RKObjectMapping*)objectMappingForClass:(Class)class atKeyPath:(NSString*)keyPath;

//- (id)objectForMappingAtKeyPath;

@end

@protocol RKObjectMapperDelegate <NSObject>

// TODO: This might be a dataSource protocol actually...
// MAYBE: - (RKObjectMapping*)objectMappingForElements:(NSDictionary*)elements atKeyPath:(NSString*)keyPath;

@end

/*!
 An object mapper delegate for tracing the object mapper operations
 */
@interface RKObjectMapperTracingDelegate : NSObject <RKObjectMapperDelegate, RKObjectMappingOperationDelegate> {
}
@end

@implementation RKObjectMapperTracingDelegate

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectElementMapping *)elementMapping forElement:(NSString *)element {
    NSLog(@"Found mapping for element '%@': %@", element, elementMapping);
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForElement:(NSString *)element {
    NSLog(@"Unable to find mapping for element '%@'", element);
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forProperty:(NSString *)property {
    NSLog(@"Set '%@' to '%@' on object %@ at keyPath '%@'", property, value, operation.object, operation.keyPath);
}

- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath {
    return nil;
}

@end

/*!
 Maps parsed primitive dictionary and arrays into objects. This is the primary entry point
 for an external object mapping operation.
 */
@interface RKNewObjectMapper : NSObject {
    BOOL _tracingEnabled;
    id _targetObject;
    NSArray* _objectMappings;
    id<RKObjectMappingProvider> _mappingProvider;
    id<RKObjectMapperDelegate> _delegate;
}

/*!
 When YES, the mapper will log tracing information about the mapping operations performed
 */
@property (nonatomic, assign) BOOL tracingEnabled;
@property (nonatomic, assign) id targetObject;
@property (nonatomic, copy) NSString* keyPath;
@property (nonatomic, assign) id<RKObjectMapperDelegate> delegate;
@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) id<RKObjectMappingProvider> mappingProvider;

+ (id)mapperForObject:(id)object mappingProvider:(id<RKObjectMappingProvider>)mappingProvider;
- (id)initWithObject:(id)object mappingProvider:(id<RKObjectMappingProvider>)mappingProvider;

// Primary entry point for the mapper. Examines the type of object and processes it appropriately...
- (id)performMapping;

@end

@interface RKNewObjectMapper (Private)

- (id)mapObject:(id)mappableObject fromElements:(NSDictionary*)elements usingMapping:(RKObjectMapping*)mapping;
- (NSArray*)mapFromArray:(NSArray*)array usingMapping:(RKObjectMapping*)mapping;

@end

@implementation RKNewObjectMapper

@synthesize tracingEnabled = _tracingEnabled;
@synthesize targetObject = _targetObject;
@synthesize delegate =_delegate;
@synthesize keyPath = _keyPath;
@synthesize mappingProvider = _mappingProvider;
@synthesize object = _object;

+ (id)mapperForObject:(id)object mappingProvider:(id<RKObjectMappingProvider>)mappingProvider {
    return [[[self alloc] initWithObject:object mappingProvider:mappingProvider] autorelease];
}

- (id)initWithObject:(id)object mappingProvider:(id<RKObjectMappingProvider>)mappingProvider {
    self = [super init];
    if (self) {
        _object = [object retain];
        _mappingProvider = mappingProvider;
    }
    
    return self;
}

- (void)dealloc {
    [_object release];
    [_keyPath release];
    [super dealloc];
}

- (void)failMapping {
    [NSException raise:nil format:@"fail!"];
}

- (id)createInstanceOfClassForMapping:(Class)mappableClass {
    // TODO: RKObjectMappable protocol probably comes back for + object method...
    // TODO: Believe we want this to consult the delegate?
    if (mappableClass) {
        return [mappableClass new];
    }
    
    return nil;
}

#define RKFAILMAPPING() NSAssert(nil != nil, @"Failed mapping operation!!!")

// Primary entry point for the mapper. 
- (id)performMapping {
    NSAssert(self.object != nil, @"Cannot perform object mapping without an object to map");
    NSAssert(self.mappingProvider != nil, @"Cannot perform object mapping without an object mapping provider");
    
    RKObjectMapping* objectMapping = nil;
    
    // If the object being mapped is a collection, we map each object within the collection
    NSLog(@"Self.object is %@", self.object);
    if ([self.object isKindOfClass:[NSArray class]] || [self.object isKindOfClass:[NSSet class]]) {
        [NSException raise:nil format:@"fail!"];
    } else if ([self.object respondsToSelector:@selector(setValue:forKeyPath:)]) {
        id destinationObject = nil;
        if (self.targetObject) {
            // If we find a mapping for this type and keyPath, map the entire elements to the target object
            objectMapping = [self.mappingProvider objectMappingForClass:[self.targetObject class] atKeyPath:self.keyPath];
            destinationObject = self.targetObject;
        } else {
            // If the entire payload is mappable, apply it to a new instance of the object
            objectMapping = [self.mappingProvider objectMappingForKeyPath:self.keyPath];
            destinationObject = [self createInstanceOfClassForMapping:objectMapping.objectClass];
        }
        
        if (objectMapping) {
            return [self mapObject:destinationObject fromElements:self.object usingMapping:objectMapping];
        } else {
            // TODO: Iterate over each keyPath in elements and return either a dictionary (keyPath => object) or an array?
            // TODO: return error and inform delegate
            RKFAILMAPPING();
        }
    } else {
        // TODO: We should probably return nil and set an error property
        RKFAILMAPPING();
    }
    
    // Examine the type of object
    // If its a dictionary
    return nil;
}

// Needs to determine the mapping target, either an explicit object or a new object

- (id)mapObject:(id)mappableObject fromElements:(NSDictionary*)elements usingMapping:(RKObjectMapping*)mapping {
    NSAssert(mappableObject != nil, @"Cannot map without a target object to assign the results to");
    NSAssert(mapping != nil, @"Cannot map without an mapping");
    NSAssert(elements != nil, @"Cannot map without a collection of attributes");    
    
    // TODO: Delegate invocation here...
    NSLog(@"Asked to map data %@ with mapping %@", elements, mapping);
        
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithObject:mappableObject andElements:elements atKeyPath:@"" usingObjectMapping:mapping];
    if (self.tracingEnabled) {
        // Create a tracing delegate
        RKObjectMapperTracingDelegate* tracer = [[RKObjectMapperTracingDelegate alloc] init];
        operation.delegate = tracer;
    }
    [operation performMapping];
    return mappableObject;
}

- (NSArray*)mapFromArray:(NSArray*)array usingMapping:(RKObjectMapping*)mapping {
    NSAssert(array != nil, @"Cannot map without an array of objects");
    NSAssert(mapping != nil, @"Cannot map without a mapping to consult");
    
    // TODO: Delegate invocation
    NSMutableArray* mappedObjects = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (id elements in array) {
        // TODO: Need to examine the type of elements and behave appropriately...
        if ([elements isKindOfClass:[NSDictionary class]]) {            
            // TODO: Memory management...             
            id mappableObject = [self createInstanceOfClassForMapping:mapping.objectClass];
            NSObject* mappedObject = [self mapObject:mappableObject fromElements:elements usingMapping:mapping];
            [mappedObjects addObject:mappedObject];
        } else {
            // TODO: Delegate method invocation here...
            // TODO: Do we want to make exception raising an option?
            [NSException raise:nil format:@"Don't know how to map"];
        }
    }
    
    return mappedObjects;
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface RKExampleUser : NSObject {
    NSNumber* _userID;
    NSString* _name;
}

@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSString* name;

@end

@implementation RKExampleUser

@synthesize userID = _userID;
@synthesize name = _name;

@end

////////////////////////////////////////////////////////////////////////////////

#pragma mark -

@interface RKObjectMappingNextGenSpec : NSObject <UISpec> {
    
}

@end

@implementation RKObjectMappingNextGenSpec

#pragma mark - RKObjectElementMapping Specs

- (void)itShouldDefineElementToPropertyMapping {
    RKObjectElementMapping* elementMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [expectThat(elementMapping.element) should:be(@"id")];
    [expectThat(elementMapping.property) should:be(@"userID")];
}

- (void)itShouldDescribeElementMappings {
    RKObjectElementMapping* elementMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [expectThat([elementMapping description]) should:be(@"RKObjectElementMapping: id => userID")];
}

#pragma mark - RKObjectMapping Specs

- (void)itShouldDefineMappingFromAnElementToAProperty {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    [expectThat([mapping mappingForElement:@"id"]) should:be(idMapping)];
}

#pragma mark - RKNewObjectMapper Specs

- (void)itShouldPerformBasicMapping {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    
    // Map that shit
    RKNewObjectMapper* mapper = [RKNewObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKExampleUser* user = [mapper mapObject:[RKExampleUser new] fromElements:userInfo usingMapping:mapping];
    [expectThat(user.userID) should:be(31337)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldTraceMapping {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    
    // Produce logging instead of results...
    RKNewObjectMapper* mapper = [RKNewObjectMapper new];
    mapper.tracingEnabled = YES;
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    [mapper mapObject:[RKExampleUser new] fromElements:userInfo usingMapping:mapping];
}

- (void)itShouldMapACollectionOfSimpleObjectDictionaries {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
   
    RKNewObjectMapper* mapper = [RKNewObjectMapper new];
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    NSArray* users = [mapper mapFromArray:userInfo usingMapping:mapping];
    [expectThat([users count]) should:be(3)];
    RKExampleUser* blake = [users objectAtIndex:0];
    [expectThat(blake.name) should:be(@"Blake Watters")];
}
                                    
- (void)itShouldDetermineTheObjectMappingByConsultingTheMappingProviderWhenThereIsATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForClass:[RKExampleUser class] atKeyPath:nil];
        
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [RKExampleUser new];
    [mapper performMapping];
    
    [mockProvider verify];
}

- (void)itShouldMapToATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForClass:[RKExampleUser class] atKeyPath:nil];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo mappingProvider:mockProvider];
    RKExampleUser* user = [RKExampleUser new];
    mapper.targetObject = user;
    RKExampleUser* userReference = [mapper performMapping];
    
    [mockProvider verify];
    [expectThat(userReference) should:be(user)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

// TODO:
- (void)itShouldCreateANewInstanceOfTheAppropriateDestinationObjectWhenThereIsNoTargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];        
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:@"user"];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo mappingProvider:mockProvider];
    mapper.keyPath = @"user";
    id mappingResult = [mapper performMapping];
    [expectThat([mappingResult isKindOfClass:[RKExampleUser class]]) should:be(YES)];
}

- (void)itShouldDetermineTheMappingClassForAKeyPathByConsultingTheMappingProviderWhenMappingADictionaryWithoutATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];        
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:@"user"];
        
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo mappingProvider:mockProvider];
    mapper.keyPath = @"user";
    [mapper performMapping];
    [mockProvider verify];
}

- (void)itShouldAttemptToMapEachSubKeyPathOfAnUnmappableDictionary {
}

- (void)itShouldMapRegisteredSubKeyPathsOfAnUnmappableDictionaryAndReturnTheResults {
}

- (void)itShouldMapACollectionOfObjects {
    
}

- (void)itShouldMapWithoutATargetMapping {
}

- (void)itShouldRaiseAnExceptionWhenYouTryToMapAnArrayToATargetObject {
    // TODO: Probably don't want to do this long term, invoke the delegate and return an error instead
}

- (void)itShouldApplyAKeyPathToMappableDataWhenOneIsSet {
    
}
// TODO: It should map to a target object
// TODO: Map an array of strings back to the object
// TODO: Map with registered object types
// TODO: It should map a composite object when we don't have a target class and elements is a dictionary
// each registered element gets mapped and then rolled up into the composite object, which is returned.

#pragma mark - RKObjectManager specs

// TODO: TH
- (void)itShouldImplementKeyPathToObjectMappingRegistrationServices {
    // Here we want it to find the registered mapping for a class and use that to process the mapping
}

- (void)itShouldSetSelfAsTheObjectMapperDelegateForObjectLoadersCreatedViaTheManager {
    
}

@end
