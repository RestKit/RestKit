# Object Mapping

This document details the design of object mapping in RestKit. 

## Goals
- Support arbitrarily complex mapping operations
- Enable full transparency and insight into the mapping operation
- Provide a clean, clear mapping API that is easy to work on and extend
- Reduce the API foot-print of object mapping
- Enable mapping onto vanilla NSObject and NSManagedObject classes
- Enable mapping from model objects back into dictionaries and arrays (support for serialization)
- Provide simple hooks for customizing the mapping decisions
- Fully embrace key-value coding and organize the API around keyPaths
- Support mapping multiple keyPaths from a dictionary and returning a dictionary instead of requiring encapsulation
via relationships

## Discussion

Object mapping is the process RestKit uses to transform objects between representations. Object mapping
leverages key-value coding conventions to determine how to map keyPaths between object instances and
attributes. The process is composed of four steps:

1. Identification: An `RKObjectMapper` is initialized with an arbitrary collection of key-value coding
compliant data, a keyPath the object resides at (can be nil), and a mapping provider. The mapper inspects the
type of object and attempts to find mappable objects with the data.
1. Processing of Mappable Objects: If a dictionary or array is found and a corresponding object mapping is
available for the keyPath, an `RKObjectMappingOperation` is created to process the data. 
1. Attribute & Relationship Mapping: Each mapping within the object mapping definition is evaluated against the
mappable data and the result is set on the target object.
1. Sub-keyPath Mapping: If an entire dictionary is not mappable, but contains keyPaths that are mappable, these
keyPaths are mapped using a new object mapper targeted at the nested mappable data. The results of this mapping is
assigned to a results dictionary with a key set to the keyPath that was mapped. 
```
i.e. { "user": { // user data here}, "status": { // status data here } } 
=> { "user": user // RKUser instance, "status": status // RKStatus instance}
```

## Class Hierarchy
- **RKObjectManager** - The external client interface for performing object mapping operations on resources
loaded from the network. The object manager is responsible for creating object loaders and brokering interactions
between the application and object mapping subsystem.
- **RKObjectLoader** - A subclass of RKRequest that sends an HTTP request and performs an object mapping operation
on the resulting payload. Responsible for parsing the payload appropriately and initializing an `RKObjectMapper`.
- **RKObjectMappingProvider** - A protocol defining an interface for determining what object mapping is 
appropriate for a particular keyPath. A provider is required for all object mapping invocations.
- **RKObjectKeyPathMappingProvider** - A concrete implementation of `RKObjectMappingProvider` that simply registers
mappings for a particular keyPath. This is the default mapping provider configured at `RKObjectManager#mappingProvider`.
- **RKObjectMapping** - A definition of an object mapping for a particular class. Contains a collection of attribute mappings
defining how attributes in a particular mappable object should be mapped onto the target class.
- **RKObjectAttributeMapping** - Defines a mapping from a source keyPath to a destination keyPath within an object mapping
definition. For example, defines a rule that the NSString attribute at the `created_at` keyPath maps to the NSString property at 
the `createdAt` keyPath on the destination object.
- **RKObjectRelationshipMapping** - A subclass of `RKObjectAttributeMapping` that defines a mapping to a related mappable object.
Includes an objectMapping property defining the rules for mapping the related object. Used for transforming nested arrays and dictionaries.
- **RKObjectMapper** - The interface for performing object mapping on a mappable object. The mapper evaluates the type of the object
and obtains the appropriate object mapping from an `RKObjectMappingProvider` and applies it by creating instances of `RKObjectMappingOperation`.
- **RKObjectMappingOperation** - Responsible for applying an object mapping to a particular mappable dictionary. Evaluates the attribute mappings
contained in the `RKObjectMapping` against the mappable dictionary and assigns the results to the target object. 

## Tasks

### Initialize the object manager
```objc
    RKObjectManager* objectManager = [RKObjectManager managerWithBaseURL:@"http://restkit.org"];
    [objectManager setParser:[RKJSONKitParser class] forMIMEType:@"application/json"];
```

### Configuring an Object Mapping
```objc
    // In this use-case Article could be an NSObject or NSManagedObject class. Take RestKit out of the inheritance hierarchy.
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[Article class]];
    RKObjectAttributeMapping* titleMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"title" toKeyPath:@"title"];
    [mapping addAttributeMapping:titleMapping];
    
    // TODO: Couple of different ways we could grab object mappings, what's best?
    RKObjectMapping* commentsMapping = [Comment objectMapping]; // Informal protocol???
    RKObjectMapping* commentsMapping = [[RKObjectManager sharedManager] objectMappingForClass:[Comment class]];
    RKObjectRelationshipMapping* articleCommentsMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"comments" withObjectMapping:commentsMapping];
    [mapping addRelationshipMapping:articleCommentsMapping];
    
    // TODO: Improve these...
    [mapping mapAttributes:@"title", @"body", nil];
    [mapping mapAttributesWithKeyPathPairs:@"created_at", @"createdAt", nil]; // TODO: Better method signature...
    [mapping hasMany:@"comments" withMapping:[Comment objectMapping]];
    [mapping belongsTo:@"author" withObjectMapping:[User objectMapping] andPrimaryKey:@"author_id"];
    [mapping serializeRelationships:@"comments", nil];
    
    // Register the mapping with the object manager
    [objectManager setMapping:mapping forKeyPath:@"article"];
```

### Configure a Mappable class. 
```objc
    // In this use case the mapping is returned from the class and registered with the object manager.
    @interface Article : RKObject {        
    }
    @end
    
    @implementation Article
    
    + (RKObjectMapping*)objectMapping {
        return [RKObjectMapping mappingForClass:self withBlock:^(RKObjectMapping* article) {
            [article mapAttributes:@"title", @"body", nil];
            [article belongsTo:@"user" withObjectMapping:[User objectMapping] andPrimaryKey:@"user_id"];
            [article hasMany:@"comments" withObjectMapping:[Comment objectMapping]];
        }];
    }
    
    @end
    
    [objectManager setMapping:[RKArticle objectMapping] forKeyPath:@"article"];
```

### Automatic Mapping Generation
```objc
    // This method will generate a mapping for a class defining attribute + relationship mappings for the public properties
    // TODO: Do we want to bother with this?
    RKObjectMapping* mapping = [RKObjectMapping generateMappingForClass:[Article class]];
    [objectManager setMapping:mapping forKeyPath:@"article"];
```

### Load Mapping from a Property List
```objc
    // TODO: Do we want to support this?
    NSArray* mappings = [RKObjectMapping loadMappingsFromPropertyList:@"article.plist"];
```

### Performing a Mapping
```objc
    // RKObjectMapper always returns a single mapped structure from a dictionary. Arrays are handled by iterating and returning 
    @implementation RKObjectLoader
    
    - (void)didFinishLoad {
        id payload = [self.parser parseString:[self bodyAsString]];
        RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:payload atKeyPath:nil mappingProvider:self.objectManager.mappingProvider];
        id mappingResults = [mapper performMapping];
            
        [self.delegate didLoadObjects:mappingResults];
    }
```

### Tracing a Mapping
```objc
    RKNewObjectMapper* mapper = [RKNewObjectMapper mapperForObject:payload atKeyPath:nil mappingProvider:self.objectManager.mappingProvider];
    mapper.tracingEnabled = YES;
    id mappingResults = [mapper performMapping];
    // Generates log output informing you of what happened within the mapper and mapping operations
```

### Loading Using KeyPath Mapping Lookup
```objc
    RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/objects" delegate:self];
    // The object mapper will try to determine the mappings by examining keyPaths
```

### Load using an explicit mapping
```objc
    RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/objects" withMapping:[RKArticle objectMapping] delegate:self];
    loader.mappingDelegate = self;
```

### Serialization from an object to a Dictionary
// TODO: Design here is not totally fleshed out...
```objc
    RKUser* user = [User new];
    user.firstName = @"Blake";
    user.lastName = @"Watters";
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping mapAttributes:@"firstName", @"lastName", nil];
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithObject:dictionary andDictionary:user atKeyPath:nil usingObjectMapping:mapping];
    [operation performMapping];
    
    // TODO: Figure out how to get to JSON / form encoded... These are object mapping operations
```
