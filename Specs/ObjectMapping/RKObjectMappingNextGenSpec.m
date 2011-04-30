//
//  RKObjectMappingNextGenSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKJSONParser.h"

@class RKObjectElementMapping;

// Defines the mapping rules for a given target class
@interface RKObjectMapping : NSObject {
    Class _objectClass;
    NSMutableArray* _elementMappings;
}

@property (nonatomic, assign) Class objectClass;

@end

@implementation RKObjectMapping

@synthesize objectClass = _objectClass;

+ (id)mappingForClass:(Class)objectClass {
    RKObjectMapping* mapping = [RKObjectMapping new];
    mapping.objectClass = objectClass;    
    return [mapping autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _elementMappings = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_elementMappings release];
    [super dealloc];
}

- (void)addElementMapping:(RKObjectElementMapping*)elementMapping {
    [_elementMappings addObject:elementMapping];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Object class => %@: element mappings => %@", NSStringFromClass(self.objectClass), _elementMappings];
}

- (RKObjectElementMapping*)mappingForElement:(NSString*)element {
    // TODO: Return the mapping for the specified elelemt?
    for (RKObjectElementMapping* elementMapping in _elementMappings) {
        if ([[elementMapping element] isEqualToString:element]) {
            return elementMapping;
        }
    }
    
    return nil;
}

@end

////////////////////////////////////////////////////////////////////////////////

//typedef enum {
//    RKObjectElementMappingTypeProperty,
//    RKObjectElementMappingTypeRelationship
//} RKObjectElementMappingType;

// Defines the rules for mapping a particular element
@interface RKObjectElementMapping : NSObject {
    NSString* _element;
    NSString* _property;
}

@property (nonatomic, retain) NSString* element;
@property (nonatomic, retain) NSString* property;

+ (id)mappingWithElement:(NSString*)element toProperty:(NSString*)property;

@end

@implementation RKObjectElementMapping

@synthesize element = _element;
@synthesize property = _property;

+ (id)mappingWithElement:(NSString*)element toProperty:(NSString*)property {
    RKObjectElementMapping* mapping = [RKObjectElementMapping new];
    mapping.element = element;
    mapping.property = property;
    
    return [mapping autorelease];
}

- (NSString*)description {
    // TODO: Inject logging for testing???
    return [NSString stringWithFormat:@"mapping: %@ => %@", self.element, self.property];
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface RKObjectMappingOperation : NSObject {
    NSDictionary* _dictionary;
    RKObjectMapping* _mapping;
}

@property (nonatomic, readonly) NSDictionary* dictionary;
@property (nonatomic, readonly) RKObjectMapping* mapping;

- (id)initWithDictionary:(NSDictionary*)dictionary andMapping:(RKObjectMapping*)mapping;

@end

@implementation RKObjectMappingOperation

@synthesize dictionary = _dictionary;
@synthesize mapping = _mapping;

// TODO: objectMapping instead of mapping!!!
- (id)initWithDictionary:(NSDictionary*)dictionary andMapping:(RKObjectMapping*)mapping {
    self = [super init];
    if (self) {
        _dictionary = [dictionary retain];
        _mapping = [mapping retain];
    }
    
    return self;
}

- (void)dealloc {
    [_dictionary release];
    [_mapping release];
    
    [super dealloc];
}

- (id)performMapping {
    id object = [self.mapping.objectClass new];
    for (NSString* element in [_dictionary allKeys]) {
        RKObjectElementMapping* elementMapping = [self.mapping mappingForElement:element];
        if (elementMapping) {
            // element is the name
            id value = [_dictionary valueForKey:element];
            [object setValue:value forKey:elementMapping.property];
        } else {
            // TODO: Log nothing happened...
            NSLog(@"Unable to find mapping for element: %@", element);
        }
    }
        
    return object;
}

@end

////////////////////////////////////////////////////////////////////////////////

// Replacement for the object mapper. Final functionality TBD.
@interface RKNewObjectMapper : NSObject {
}

- (id)mapObjectFromElements:(id)elements withMapping:(RKObjectMapping*)mapping;

@end

@implementation RKNewObjectMapper

- (id)mapObjectFromElements:(id)elements withMapping:(RKObjectMapping*)mapping {
    NSLog(@"Asked to map data %@ with mapping %@", elements, mapping);
    
    // Get the element mappings from mapping
    // Check if data has valueForKey:mapping
    // Initialize and object and assign if so...
//    for (RKObjectElementMapping* elementMapping in mapping.el
//    for (NSString* element in [elements allKeys]) {
//        RKObjectElementMapping* mapping = [mapping mappingForElement:element];
//        if (element) {
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithDictionary:elements andMapping:mapping];
    return [operation performMapping];
//        }
//    }
    // This method assumes that data contains info that is mappable given mapping
    
    return nil;
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

- (NSString*)JSON {
    return @"{ \"id\": 31337, \"name\": \"Blake Watters\" };";
}

- (void)itShouldPerformBasicMapping {
    // Setup a mapping for the above class
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKExampleUser class]];
    RKObjectElementMapping* idMapping = [RKObjectElementMapping mappingWithElement:@"id" toProperty:@"userID"];
    [mapping addElementMapping:idMapping];
    RKObjectElementMapping* nameMapping = [RKObjectElementMapping mappingWithElement:@"name" toProperty:@"name"];
    [mapping addElementMapping:nameMapping];
    
    // Map that shit
    RKNewObjectMapper* mapper = [RKNewObjectMapper new];
    id userInfo = [[RKJSONParser new] objectFromString:[self JSON]];
    RKExampleUser* user = [mapper mapObjectFromElements:userInfo withMapping:mapping];
    [expectThat(user.userID) should:be(31337)];
    [expectThat(user.name) should:be(@"Blake Watters")];
}

@end
