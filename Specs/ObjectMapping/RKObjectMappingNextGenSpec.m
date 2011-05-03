//
//  RKObjectMappingNextGenSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>
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

@class RKNewObjectMapper;

/*!
 Maps parsed primitive dictionary and arrays into objects. This is the primary entry point
 for an external object mapping operation.
 */
typedef enum RKObjectMapperErrors {
    RKObjectMapperErrorClassMappingNotFound
} RKObjectMapperErrorCode;

@protocol RKObjectMapperDelegate <NSObject>

@optional

/*!
 Return a dictionary serialization of an object that can be used for object mapping.
 */
- (NSDictionary*)mappableDictionaryForObject:(id)object;

- (void)objectMapper:(RKNewObjectMapper*)objectMapper didAddError:(NSError*)error;
- (void)objectMapper:(RKNewObjectMapper*)objectMapper willAttemptMappingForKeyPath:(NSString*)keyPath;
- (void)objectMapper:(RKNewObjectMapper*)objectMapper didFindMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath;
- (void)objectMapper:(RKNewObjectMapper*)objectMapper didNotFindMappingForKeyPath:(NSString*)keyPath;

//- (void)objectMappper:(RKNewObjectMapper*)objectMapper foundMappable: atKeyPath:
// begin mapping
// finish mapping
// - (BOOL)shouldMapKeyPath:toObject:usingMapping:
// willMapKeyPath:toObject:usingMapping:
// didMapKeyPath:toObject:usingMapping:
// objectMapper
@end

/*!
 An object mapper delegate for tracing the object mapper operations
 */
@interface RKObjectMapperTracingDelegate : NSObject <RKObjectMapperDelegate, RKObjectMappingOperationDelegate> {
}
@end

@implementation RKObjectMapperTracingDelegate

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didFindMapping:(RKObjectElementMapping *)elementMapping forKeyPath:(NSString *)keyPath {
    NSLog(@"Found mapping for keyPath '%@': %@", keyPath, elementMapping);
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didNotFindMappingForKeyPath:(NSString *)keyPath {
    NSLog(@"Unable to find mapping for keyPath '%@'", keyPath);
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forProperty:(NSString *)property {
    NSLog(@"Set '%@' to '%@' on object %@ at keyPath '%@'", property, value, operation.object, operation.keyPath);
}

- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath {
    return nil;
}

- (void)objectMapper:(RKNewObjectMapper *)objectMapper didAddError:(NSError *)error {
    NSLog(@"Object mapper encountered error: %@", [error localizedDescription]);
}

@end

@interface RKNewObjectMapper : NSObject {
    id _object;
    NSString* _keyPath;
    id _targetObject;
    id<RKObjectMappingProvider> _mappingProvider;
    id<RKObjectMapperDelegate> _delegate;
    NSMutableArray* _errors;
    RKObjectMapperTracingDelegate* _tracer;
}

@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) NSString* keyPath;
@property (nonatomic, readonly) id<RKObjectMappingProvider> mappingProvider;

/*!
 When YES, the mapper will log tracing information about the mapping operations performed
 */
@property (nonatomic, assign) BOOL tracingEnabled;
@property (nonatomic, assign) id targetObject;
@property (nonatomic, assign) id<RKObjectMapperDelegate> delegate;

@property (nonatomic, readonly) NSArray* errors;

+ (id)mapperForObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(id<RKObjectMappingProvider>)mappingProvider;
- (id)initWithObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(id<RKObjectMappingProvider>)mappingProvider;

// Primary entry point for the mapper. Examines the type of object and processes it appropriately...
- (id)performMapping;
- (NSUInteger)errorCount;

@end

@interface RKNewObjectMapper (Private)

- (id)mapObject:(id)mappableObject fromDictionary:(NSDictionary*)dictionary usingMapping:(RKObjectMapping*)mapping;
- (NSArray*)mapFromArray:(NSArray*)array usingMapping:(RKObjectMapping*)mapping;

@end

@implementation RKNewObjectMapper

@synthesize tracingEnabled = _tracingEnabled;
@synthesize targetObject = _targetObject;
@synthesize delegate =_delegate;
@synthesize keyPath = _keyPath;
@synthesize mappingProvider = _mappingProvider;
@synthesize object = _object;
@synthesize errors = _errors;

+ (id)mapperForObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(id<RKObjectMappingProvider>)mappingProvider {
    return [[[self alloc] initWithObject:object atKeyPath:keyPath mappingProvider:mappingProvider] autorelease];
}

- (id)initWithObject:(id)object atKeyPath:(NSString*)keyPath mappingProvider:(id<RKObjectMappingProvider>)mappingProvider {
    self = [super init];
    if (self) {
        _object = [object retain];
        _mappingProvider = mappingProvider;
        _keyPath = [keyPath copy];
        _errors = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_object release];
    [_keyPath release];
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
    // TODO: Believe we want this to consult the delegate?
    if (mappableClass) {
        return [mappableClass new];
    }
    
    return nil;
}

- (void)addErrorWithCode:(RKObjectMapperErrorCode)errorCode message:(NSString*)errorMessage keyPath:(NSString*)keyPath userInfo:(NSDictionary*)otherInfo {
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              errorMessage, NSLocalizedDescriptionKey,
                              @"RKObjectMapperKeyPath", keyPath ? keyPath : (NSString*) [NSNull null],
                              nil];
    [userInfo addEntriesFromDictionary:otherInfo];
    NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:errorCode userInfo:userInfo];
    [_errors addObject:error];
    
    if ([self.delegate respondsToSelector:@selector(objectMapper:didAddError:)]) {
        [self.delegate objectMapper:self didAddError:error];
    }
    [_tracer objectMapper:self didAddError:error];
}

- (void)addErrorForUnmappableKeyPath:(NSString*)keyPath {
    NSString* errorMessage = [NSString stringWithFormat:@"Could not find an object mapping for keyPath: %@", keyPath];
    [self addErrorWithCode:RKObjectMapperErrorClassMappingNotFound message:errorMessage keyPath:self.keyPath userInfo:nil];
}

#define RKFAILMAPPING() NSAssert(nil != nil, @"Failed mapping operation!!!")

// If the object being mapped is a collection, we map each object within the collection
- (id)performMappingForCollection {
    NSAssert([self.object isKindOfClass:[NSArray class]] || [self.object isKindOfClass:[NSSet class]], @"Expected self.object to be a collection");
    RKObjectMapping* mapping = [self.mappingProvider objectMappingForKeyPath:self.keyPath];
    if (mapping) {
        return [self mapFromArray:self.object usingMapping:mapping];
    } else {
        // Attempted to map a collection but couldn't find a mapping for the keyPath
        [self addErrorForUnmappableKeyPath:self.keyPath];
    }
    
    return nil;
}

- (RKObjectMapping*)mappingForKeyPath:(NSString*)keyPath withClass:(Class)objectClass {
    RKObjectMapping* mapping = nil;
    if ([self.delegate respondsToSelector:@selector(objectMapper:willAttemptMappingForKeyPath:)]) {
        [self.delegate objectMapper:self willAttemptMappingForKeyPath:keyPath];
    }
    [_tracer objectMapper:self willAttemptMappingForKeyPath:keyPath];
    
    // Obtain the mapping from the provider
    if (objectClass) {        
        mapping = [self.mappingProvider objectMappingForClass:objectClass atKeyPath:keyPath];
    } else {
        mapping = [self.mappingProvider objectMappingForKeyPath:keyPath];
    }
    
    return mapping;
}

// Attempts to map each sub keyPath for a mappable collection and returns the result as a dictionary
- (id)performSubKeyPathObjectMapping {
    NSAssert([self.object isKindOfClass:[NSDictionary class]], @"Can only perform sub keyPath mapping on a dictionary");
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    for (NSString* subKeyPath in [self.object allKeys]) {
        NSString* keyPath = self.keyPath ? [NSString stringWithFormat:@"%@.%@", self.keyPath, subKeyPath] : subKeyPath;
        RKObjectMapping* mapping = [self mappingForKeyPath:keyPath withClass:nil];
        if (mapping) {
            // This is a mappable sub keyPath. Initialize a new object mapper targeted at the subObject
            id subObject = [self.object valueForKey:keyPath];
            RKNewObjectMapper* subMapper = [RKNewObjectMapper mapperForObject:subObject atKeyPath:keyPath mappingProvider:self.mappingProvider];
            subMapper.delegate = self.delegate;
            [subMapper setTracer:_tracer];
            id mappedResults = [subMapper performMapping];
            if (mappedResults) {
                [dictionary setValue:mappedResults forKey:keyPath];
            }
        }
    }
    
    // If we have attempted a sub keyPath mapping and found no results, add an error
    if ([dictionary count] == 0) {
        NSString* errorMessage = [NSString stringWithFormat:@"Could not find an object mapping for keyPath: %@", self.keyPath];
        [self addErrorWithCode:RKObjectMapperErrorClassMappingNotFound message:errorMessage keyPath:self.keyPath userInfo:nil];
        return nil;
    }
    
    return dictionary;
}

- (id)performMappingForObject {
    NSAssert([self.object respondsToSelector:@selector(setValue:forKeyPath:)], @"Expected self.object to be KVC compliant");
    
    RKObjectMapping* objectMapping = nil;
    id destinationObject = nil;
        
    if (self.targetObject) {
        // If we find a mapping for this type and keyPath, map the entire dictionary to the target object
        destinationObject = self.targetObject;
        objectMapping = [self mappingForKeyPath:self.keyPath withClass:[self.targetObject class]];
    } else {
        // Otherwise map to a new object instance
        objectMapping = [self mappingForKeyPath:self.keyPath withClass:nil];
        destinationObject = [self createInstanceOfClassForMapping:objectMapping.objectClass];
    }
        
    if (objectMapping && destinationObject) {
        return [self mapObject:destinationObject fromDictionary:self.object usingMapping:objectMapping];
    } else if ([self.object isKindOfClass:[NSDictionary class]]) {
        // If this is a dictionary, attempt to map each sub-keyPath
        return [self performSubKeyPathObjectMapping];
    } else {
        // Attempted to map an object but couldn't find a mapping for the keyPath
        [self addErrorForUnmappableKeyPath:self.keyPath];
        return nil;
    }
    
    return nil;
}

// Perform mapping on an arbitrary class that conforms to the RKObjectMappable protocol. This
// allows the mapper to be used to transform between arbitrary types rather than just dictionaries & arrays
- (id)performMappingForMappableObject {
    NSAssert([[self.object class] respondsToSelector:@selector(mappableKeyPaths)], @"Expected self.object to RKObjectMappable");
    
    RKObjectMapping* mapping = [self mappingForKeyPath:self.keyPath withClass:nil];
    if (mapping) {        
        NSDictionary* mappableDictionary = [self.delegate mappableDictionaryForObject:self.object];
        if (mappableDictionary) {
            id targetObject = [self createInstanceOfClassForMapping:mapping.objectClass];
            return [self mapObject:targetObject fromDictionary:mappableDictionary usingMapping:mapping];
        } else {
            // TODO: return an error and inform delegate
        }        
    } else {
        // TODO: return an error and inform delegate...        
    }
    
    RKFAILMAPPING();
                                
    return nil;
}

// Primary entry point for the mapper. 
- (id)performMapping {
    NSAssert(self.object != nil, @"Cannot perform object mapping without an object to map");
    NSAssert(self.mappingProvider != nil, @"Cannot perform object mapping without an object mapping provider");        
    
    NSLog(@"Self.object is %@", self.object);
    if ([self.object isKindOfClass:[NSArray class]] || [self.object isKindOfClass:[NSSet class]]) {        
        return [self performMappingForCollection];
    } else if ([self.object isKindOfClass:[NSDictionary class]]) {
        return [self performMappingForObject];
    } else if ([[self.object class] respondsToSelector:@selector(mappableKeyPaths)]) {
        return [self performMappingForMappableObject];
    } else {
        // TODO: We should probably return nil and set an error property
        RKFAILMAPPING();
    }
    
    // Examine the type of object
    // If its a dictionary
    return nil;
}

// Needs to determine the mapping target, either an explicit object or a new object

- (id)mapObject:(id)mappableObject fromDictionary:(NSDictionary*)dictionary usingMapping:(RKObjectMapping*)mapping {    
    NSAssert(mappableObject != nil, @"Cannot map without a target object to assign the results to");
    NSAssert(mapping != nil, @"Cannot map without an mapping");
    NSAssert(dictionary != nil, @"Cannot map without a collection of attributes");    
    NSAssert([dictionary isKindOfClass:[NSDictionary class]], @"Can only map from a dictionary");
    
    // TODO: Delegate invocation here...
    NSLog(@"Asked to map data %@ with mapping %@", dictionary, mapping);
        
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithObject:mappableObject andDictionary:dictionary atKeyPath:@"" usingObjectMapping:mapping];
    operation.delegate = _tracer;
    [operation performMapping];
    return mappableObject;
}

- (NSArray*)mapFromArray:(NSArray*)array usingMapping:(RKObjectMapping*)mapping {
    NSAssert(array != nil, @"Cannot map without an array of objects");
    NSAssert(mapping != nil, @"Cannot map without a mapping to consult");
    
    // Ensure we are mapping onto a mutable collection if there is a target
    if (self.targetObject && NO == [self.targetObject respondsToSelector:@selector(addObject:)]) {
        // TODO: Should probably just be an error...
        // TODO: Inform delegate...
        [NSException raise:nil format:@"Cannot map a collection onto a %@", NSStringFromClass([self.targetObject class])];
    }
    
    // TODO: Delegate invocation
    NSMutableArray* mappedObjects = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (id elements in array) {
        // TODO: Need to examine the type of elements and behave appropriately...
        if ([elements isKindOfClass:[NSDictionary class]]) {            
            // TODO: Memory management...             
            id mappableObject = [self createInstanceOfClassForMapping:mapping.objectClass];
            NSObject* mappedObject = [self mapObject:mappableObject fromDictionary:elements usingMapping:mapping];
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

+ (NSArray*)mappableKeyPaths {
    return [NSArray arrayWithObjects:@"userID", @"name", nil];
}

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
    RKExampleUser* user = [mapper mapObject:[RKExampleUser new] fromDictionary:userInfo usingMapping:mapping];
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
    [mapper mapObject:[RKExampleUser new] fromDictionary:userInfo usingMapping:mapping];
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
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
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
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    RKExampleUser* user = [RKExampleUser new];
    mapper.targetObject = user;
    RKExampleUser* userReference = [mapper performMapping];
    
    [mockProvider verify];
    [expectThat(userReference) should:be(user)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldCreateANewInstanceOfTheAppropriateDestinationObjectWhenThereIsNoTargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];        
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:@"user"];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:@"user" mappingProvider:mockProvider];
    id mappingResult = [mapper performMapping];
    [expectThat([mappingResult isKindOfClass:[RKExampleUser class]]) should:be(YES)];
}

- (void)itShouldDetermineTheMappingClassForAKeyPathByConsultingTheMappingProviderWhenMappingADictionaryWithoutATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];        
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:@"user"];
        
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:@"user" mappingProvider:mockProvider];
    [mapper performMapping];
    [mockProvider verify];
}

- (void)itShouldMapWithoutATargetMapping {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:nil];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    RKExampleUser* user = [mapper performMapping];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldMapACollectionOfObjects {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:nil];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    NSArray* users = [mapper performMapping];
    [expectThat([users isKindOfClass:[NSArray class]]) should:be(YES)];
    [expectThat([users count]) should:be(3)];
    RKExampleUser* user = [users objectAtIndex:0];
    [expectThat([user isKindOfClass:[RKExampleUser class]]) should:be(YES)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

- (void)itShouldObtainAMappableRepresentationOfAnObjectFromTheDelegateWhenMappingArbitraryTypes {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:nil];
    
    RKExampleUser* user = [RKExampleUser new];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    NSDictionary* dictionaryOfObject = [NSDictionary dictionary];
    [[[mockDelegate expect] andReturn:dictionaryOfObject] mappableDictionaryForObject:user];
    
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:user atKeyPath:nil mappingProvider:mockProvider];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)itShouldBeAbleToMapFromAUserObjectToADictionary {    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:nil];
    
    RKExampleUser* user = [RKExampleUser new];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];
    
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    NSDictionary* dictionaryOfObject = [NSDictionary dictionaryWithObjectsAndKeys:@"Blake Watters", @"name", [NSNumber numberWithInt:123], @"userID", nil];
    [[[mockDelegate stub] andReturn:dictionaryOfObject] mappableDictionaryForObject:user];
    
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:user atKeyPath:nil mappingProvider:mockProvider];
    mapper.delegate = mockDelegate;
    NSDictionary* userInfo = [mapper performMapping];
    [expectThat([userInfo isKindOfClass:[NSDictionary class]]) should:be(YES)];
    [expectThat([userInfo valueForKey:@"name"]) should:be(@"Blake Watters")];
}

- (void)itShouldAttemptToMapEachSubKeyPathOfAnUnmappableDictionary {
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:nil] objectMappingForKeyPath:nil];
    [[[mockProvider expect] andReturn:nil] objectMappingForKeyPath:@"id"];
    [[[mockProvider expect] andReturn:nil] objectMappingForKeyPath:@"name"];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    [mapper performMapping];    
    [mockProvider verify];
}

- (void)itShouldMapRegisteredSubKeyPathsOfAnUnmappableDictionaryAndReturnTheResults {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    id mockProvider = [OCMockObject niceMockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider stub] andReturn:nil] objectMappingForKeyPath:nil];
    [[[mockProvider stub] andReturn:mapping] objectMappingForKeyPath:@"user"];
    
    id userInfo = RKSpecParseFixtureJSON(@"nested_user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    NSDictionary* dictionary = [mapper performMapping];
    [expectThat([dictionary isKindOfClass:[NSDictionary class]]) should:be(YES)];
    RKExampleUser* user = [dictionary objectForKey:@"user"];
    [expectThat(user) shouldNot:be(nil)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

#pragma mark Mapping Error States

// TODO: Change to an error...
- (void)itShouldRaiseAnExceptionWhenYouTryToMapAnArrayToATargetObject {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingFromElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingFromElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    id mockProvider = [OCMockObject mockForProtocol:@protocol(RKObjectMappingProvider)];
    [[[mockProvider expect] andReturn:mapping] objectMappingForKeyPath:nil];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    mapper.targetObject = [[RKExampleUser new] autorelease];
    NSException* mappingException = nil;
    @try {
        [mapper performMapping];
    }
    @catch (NSException* exception) {
        mappingException = exception;
    }
    @finally {
        [expectThat(mappingException) shouldNot:be(nil)];
    }
}

- (void)itShouldAddAnErrorWhenAttemptingToMapADictionaryWithoutAnObjectMapping {
    id mockProvider = [OCMockObject niceMockForProtocol:@protocol(RKObjectMappingProvider)];
    
    id userInfo = RKSpecParseFixtureJSON(@"user.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
    [expectThat([[mapper.errors objectAtIndex:0] localizedDescription]) should:be(@"Could not find an object mapping for keyPath: (null)")];
}

- (void)itShouldAddAnErrorWhenAttemptingToMapACollectionWithoutAnObjectMapping {
    id mockProvider = [OCMockObject niceMockForProtocol:@protocol(RKObjectMappingProvider)];
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    [mapper performMapping];
    [expectThat([mapper errorCount]) should:be(1)];
    [expectThat([[mapper.errors objectAtIndex:0] localizedDescription]) should:be(@"Could not find an object mapping for keyPath: (null)")];
}

- (void)itShouldInformTheDelegateOfError {
    id mockProvider = [OCMockObject niceMockForProtocol:@protocol(RKObjectMappingProvider)];
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKObjectMapperDelegate)];    
    
    id userInfo = RKSpecParseFixtureJSON(@"users.json");
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:userInfo atKeyPath:nil mappingProvider:mockProvider];
    [[mockDelegate expect] objectMapper:mapper didAddError:[OCMArg isNotNil]];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

#pragma mark RKObjectMapperDelegate Specs

- (void)itShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPath {
    
}

- (void)itShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsSuccessful {
    
}

// TODO: Map an array of strings back to the object
// TODO: Map with registered object types

#pragma mark - RKObjectManager specs

// TODO: TH
- (void)itShouldImplementKeyPathToObjectMappingRegistrationServices {
    // Here we want it to find the registered mapping for a class and use that to process the mapping
}

- (void)itShouldSetSelfAsTheObjectMapperDelegateForObjectLoadersCreatedViaTheManager {
    
}

@end
