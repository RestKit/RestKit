# Object Mapping

This document details the design of object mapping in RestKit as of version 0.9.3

## The Object Mapper is Designed to...
- Take parsing responsibilities out of the mapper entirely
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
attributes. The process is composed of three steps:

1. Identification: An `RKObjectMapper` is initialized with an arbitrary collection of key-value coding
compliant data, a keyPath the object resides at (can be nil), and a mapping provider. The mapping provider
supplies the mapper with mappable keyPaths 
1. Processing of Mappable Objects: If a dictionary or array is found and a corresponding object mapping is
available for the keyPath, an `RKObjectMappingOperation` is created to process the data. 
1. Attribute & Relationship Mapping: Each attribute or relationship mapping within the object mapping definition 
is evaluated against the mappable data and the result is set on the target object.

## Class Hierarchy
- **RKObjectManager** - The external client interface for performing object mapping operations on resources
loaded from the network. The object manager is responsible for creating object loaders and brokering interactions
between the application and object mapping subsystem.
- **RKObjectLoader** - A subclass of RKRequest that sends an HTTP request and performs an object mapping operation
on the resulting payload. Responsible for parsing the payload appropriately and initializing an `RKObjectMapper` to handle the mapping.
- **RKObjectMappingProvider** - Responsible for providing keyPaths and RKObjectMapping objects to instances of `RKObjectMapper`.
An instance of the mapping provider is available via the `mappingProvider` property of `RKObjectManager`. This mapping provider
is automatically assigned to all `RKObjectLoader` instances instantiated through the object manager.
- **RKObjectMapping** - A definition of an object mapping for a particular class. Contains a collection of attribute mappings
defining how attributes in a particular mappable object should be mapped onto the target class. Also contains relationship mappings
specifying how to map nested object structures into one-to-one or one-to-many relationships. Object mappings are registered with the
mapping provider to define rules for mapping and serializing objects.
- **RKObjectAttributeMapping** - Defines a mapping from a source keyPath to a destination keyPath within an object mapping
definition. For example, defines a rule that the NSString attribute at the `created_at` keyPath maps to the NSString property at 
the `createdAt` keyPath on the destination object.
- **RKObjectRelationshipMapping** - A subclass of `RKObjectAttributeMapping` that defines a mapping to a related mappable object.
Includes an objectMapping property defining the rules for mapping the related object. Used for transforming nested arrays and dictionaries into
related objects.
- **RKObjectMapper** - The interface for performing object mapping on mappable data. The mapper evaluates the type of the object
and obtains the appropriate object mapping from an `RKObjectMappingProvider` and applies it by creating instances of `RKObjectMappingOperation`.
- **RKObjectMappingOperation** - Responsible for applying an object mapping to a particular mappable dictionary. Evaluates the attribute mappings
contained in the `RKObjectMapping` against the mappable dictionary and assigns the results to the target object. Recursively creates child mapping
operations for all relationships and continues on until a full object graph has been constructed according to the mapping rules.
- **RKObjectMappingResult** - When `RKObjectMapper` has finished its work, it will either return nil to indicate an unrecoverable error occurred or
will return an instance of `RKObjectMappingResult`. The mapping result enables you to coerce the mapped results into the format you wish to work with.
The currently available result coercions are: 
    1. `asObject` - Return the result as a single object. Useful when you know you have mapped a single object back (i.e. used `postObject`).
    1. `asCollection` - Return the result as a collection of mapped objects. This will take all the mapped keyPaths and combine all mapped objects
        under those keyPaths and return it as a single array of objects.
    1. `asDictionary` - Return the result as a dictionary of keyPaths and mapped object pairs. Useful when you want to identify your results by keyPath.
    1. `asError` - Return the result as an NSError. The error is constructed by coercing the result into a collection, then calling `description` on all
        mapped objects to turn them into a string. The collection of error message strings are then joined together with the ", " delimiter to construct
        the localizedDescription for the error. The raw error objects the error was mapped from is available on the userInfo of the NSError instance. This
        is useful when you encountered a server side error and want to coerce the mapping results into an NSError. This is how `objectLoader:didFailWithError`
        returns server side error messages to you.
- **RKObjectRouter** - Responsible for generating resource paths for accessing remote representations of objects. Capable of generating a resource
path by interpolating property values into a string. For example, a path of "/articles/(articleID)" when applied to an Article object with a `articleID` property
with the value 12345, would generate "/articles/12345". The object router is used to generate resource paths when getObject, postObject, putObject and deleteObject
are invoked.
- **RKErrorMessage** - A simple class providing for the mapping of server-side error messages back to NSError objects. Contains a single `errorMessage` property. When an
RKObjectManager is initialized, object mappings from the "error" and "errors" keyPaths to instances of RKErrorMessage are registered with the mapping provider. This
provides out of the box mapping support for simple error messages. The mappings can be removed or replaced by the developer to handle more advanced error return values,
such as containing a server side error code or other metadata.
- **RKObjectPropertyInspector** - An internally used singleton object responsible for cacheing the properties and types of a target class. This is used during object mapping
to transform values at mapping time based on the source and destination types.
- **RKObjectSerializer** - Responsible for taking Cocoa objects are serializing them for transport via HTTP to a remote server.  The serializer takes an instance of an object
and maps it back into an NSDictionary representation by creating an `RKObjectMappingOperation`. During the mapping process, certain types are transformed into serializable
representation (i.e. NSDate & NSDecimalNumber objects are coerced into NSString instances). Once mapping is complete, the NSDictionary instance is encoded into a wire format
and returned as an `RKRequestSerializable` object. The serializer is invoked for you automatically when `postObject` and `putObject` are invoked on the object manager. The
appropriate mapping is selected by consulting the `objectMappingForClass:` method of the `RKObjectMappingProvider` instance configured on the object manager. Currently serialization to form encoded and JSON is supported.
- **RKParserRegistry** - Responsible for maintaining the association between MIME Types and the `RKParser` object responsible for handling it. There is a singleton
sharedRegistry instance that is automatically configured at library initialization time to handle the application/json and application/xml MIME types. Runtime detection
of the parser classes is utilized to configure the registry appropriately. For JSON, autoconfiguration searches for JSONKit, then YAJL, and then SBJSON.

## Tasks

### Configuring an Object Mapping
```objc
    // In this use-case Article is a vanilla NSObject with properties
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[Article class]];
    
    // Add an attribute mapping to the object mapping directly
    RKObjectAttributeMapping* titleMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"title" toKeyPath:@"title"];
    [mapping addAttributeMapping:titleMapping];
    
    // Configure attribute mappings using helper methods
    [mapping mapAttributes:@"title", @"body", nil]; // Define mappings where the keyPath and target attribute have the same name
    [mapping mapKeyPath:@"created_at" toAttribute:@"createdAt"]; // Map a differing keyPath and attribute
    [mapping mapKeyPathsToAttributes:@"some.keyPath", @"targetAttribute1", @"another.keyPath", @"targetAttribute2", nil];
    
    // Configure relationship mappings
    RKObjectMapping* commentMapping = [[RKObjectManager sharedManager] objectMappingForClass:[Comment class]];
    // Direct configuration of instances
    RKObjectRelationshipMapping* articleCommentsMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"comments" toKeyPath:@"comments" objectMapping:commentMapping];
    [mapping addRelationshipMapping:articleCommentsMapping];
    
    // Configuration using helper methods
    [mapping mapRelationship:@"comments" withObjectMapping:commentMapping];
    [mapping hasMany:@"comments" withObjectMapping:commentMapping];
    [mapping belongsTo:@"user" withObjectMapping:userMapping];    
    
    // Register the mapping with the object manager
    [objectManager.mappingProvider setMapping:mapping forKeyPath:@"article"];
```

### Configuring a Core Data Object Mapping
TODO - Finish up
```objc
    // TODO: Not yet implemented.
    [mapping belongsTo:@"author" withObjectMapping:[User objectMapping] andPrimaryKey:@"author_id"];
```

### Loading Using KeyPath Mapping Lookup
```objc
    RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/objects" delegate:self];
    // The object mapper will try to determine the mappings by examining keyPaths in the loaded payload
```

### Load using an explicit mapping
```objc
    RKObjectMapping* articleMapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[Article class]];
    RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/objects" withMapping:articleMapping delegate:self];
    loader.mappingDelegate = self;
```

### Configuring the Serialization Format
```objc
    // Serialize to Form Encoded
    [RKObjectManager sharedManager].serializationMIMEType = RKMIMETypeFormURLEncoded;

    // Serialize to JSON
    [RKObjectManager sharedManager].serializationMIMEType = RKMIMETypeJSON;
```

### Serialization from an object to a Dictionary
This is handled for you when using postObject and putObject, presented here for reference

```objc
    RKUser* user = [User new];
    user.firstName = @"Blake";
    user.lastName = @"Watters";
    
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [mapping mapAttributes:@"firstName", @"lastName", nil];
    
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:serializationMapping];
    NSError* error = nil;
    id serialization = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
```

### Performing a Mapping
This is handled for you when using loadObjectAtResourcePath:, presented here for reference:

```objc
    NSString* JSONString = @"{ \"name\": \"The name\", \"number\": 12345}";
    NSString* MIMEType = @"application/json";
    NSError* error = nil;
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
    id parsedData = [parser objectFromString:JSONString error:error];
    if (parsedData == nil && error) {
        // Parser error...
    }
    
    RKObjectMappingProvider* mappingProvider = [RKObjectManager sharedManager].mappingProvider;
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
    RKObjectMappingResult* result = [mapper performMapping];
    if (result) {
        // Yay! Mapping finished successfully
    }
```

### Registering a Parser
```objc
    [[RKParserRegistry sharedRegistry] setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
```
