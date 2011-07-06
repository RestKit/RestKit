# Object Mapping

This document details the design of object mapping in RestKit as of version 0.9.3

## Object Mapping Overview

RestKit's key differentiating feature from other HTTP toolkits in the iOS space is the
tightly integrated support for object mapping. Object mapping is the process of taking a representation
of data in one format and transforming it into another form. This mechanism is used extensively within 
RestKit to streamline the serialization and deserialization of resources exchanged with a remote
backend application server via HTTP. Object mapping operations are performed when you load a remote 
resource via an instance of `RKObjectManager` and when a local object is sent to the backend for processing. 

### Key-Value Coding

Object mapping is built on top of the key-value coding pattern that permeates the Cocoa frameworks. KVC is a mechanism
for expressing read and write operations on an object graph in terms of simple strings. RestKit relies on KVC to identify
mappable content within a parsed response body and dynamically update the attributes and relationships of your local domain
objects with the appropriate content. An understanding of key-value coding is essential to fully understand and leverage the
capabilities of the RestKit framework. Before diving into the details of RestKit's object mapping system, be sure to get a firm
grasp on KVC.

## Object Mapping by Example

To understand the object mapping subsystem of RestKit, let's consider an example. Imagine that we are building an app 
that loads a collection of news articles from a remote system. Each article has a title, a body,
an author, and a publication date. We expect our JSON to come back something like this:

```json
    { "articles": [
        { "title": "RestKit Object Mapping Intro",
          "body": "This article details how to use RestKit object mapping...",
          "author": "Blake Watters",
          "publication_date": "7/4/2011"
        },
        { "title": "RestKit 1.0 Released",
          "body": "RestKit 1.0 has been released to much fanfare across the galaxy...",
          "author": "Blake Watters",
          "publication_date": "9/4/2011"
        }]
    }
```

Within our iOS application, we are going to have a table view showing the same information. We have an Objective-C
class to hold this data that looks like the following:

```objc
    @interface Article : NSObject
        @property (nonatomic, retain) NSString* title;
        @property (nonatomic, retain) NSString* body;
        @property (nonatomic, retain) NSString* author;
        @property (nonatomic, retain) NSDate*   publicationDate;
    @end
```

Our goal is to leverage RestKit's object mapping capabilities to turn the above JSON into an array of Article instances. To make
this happen, we must first become familiar with a few RestKit classes:

1. **RKObjectMapping**: An object mapping defines the rules for transforming a parsed data payload into a local domain object. 
Each object mapping is composed of a collection of attribute and relationship mappings that define how to transform key paths in the 
source data into properties on the local object.
1. **RKObjectMappingProvider**: The object mapping provider defines the rules for what key paths in a loaded set of data correspond to
an object mapping.

Let's take a look at how we would configure RestKit to perform this operation:

```objc
    RKObjectMapping* articleMapping = [RKObjectMapping mappingForClass:[Article class]];
    [article mapKeyPath:@"title" toAttribute:@"title"];
    [article mapKeyPath:@"body" toAttribute:@"body"];
    [article mapKeyPath:@"author" toAttribute:@"author"];
    [article mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];
    
    [[RKObjectManager sharedManager].mappingProvider setObjectMapping:articleMapping forKeyPath:@"articles"];
```

Let's consider what we've done here. In the first line, we created an instance of `RKObjectMapping` defining a mapping
for the `Article` class. We then configured the mapping to define rules for transforming data within the parsed payload to attributes
on an instance of `Article`. Finally, we instructed the mapping provider to use `articleMapping` whenever it encounters data at the `@"articles"`
key path. 

Recall the importance of key-value coding to the process. When we load the example JSON above via RestKit with the articleMapping configuration in
place, the following things are going to happen:

1. RestKit will create an instance of `RKObjectMapper` with the parsed JSON payload and the mapping provider. The mapper is responsible for figuring
out how to map an opaque collection of potentially mappable data.
1. The `RKObjectMapper` instance will ask the mapping provider for a list of mappable key paths. Each key path will be evaluated against the parsed
payload using valueForKeyPath:. Since we configured a mapping for the `@"articles"` key path, RestKit will invoke `valueForKeyPath:@"articles"` on the
parsed data and find the mappable data.
1. RestKit now knows that there is interesting data in the payload that needs to be mapped. `RKObjectMapper` notes that the mappable data is an array
and iterates over the collection, mapping each dictionary within the array in turn. An instance of RKObjectMappingOperation is created for each element
in the array. Each mapping operation targets one of dictionaries contained in the array returned from the `@"articles"` key path. For the example above, this
means that we would generate two object mapping operations:

```json
    // This dictionary will processed in one mapping operation
    { "title": "RestKit Object Mapping Intro",
      "body": "This article details how to use RestKit object mapping...",
      "author": "Blake Watters",
      "publication_date": "7/4/2011"
    }

    // This dictionary will be processed in another mapping operation
    { "title": "RestKit 1.0 Released",
      "body": "RestKit 1.0 has been released to much fanfare across the galaxy...",
      "author": "Blake Watters",
      "publication_date": "9/4/2011"
    }
```

1. Once the object mapping operation takes over, a new set of KVC key paths is examined. The attribute mappings we defined via the calls to
`mapKeyPath:toAttribute:` are now evaluated against the dictionary. RestKit will invoke `valueForKeyPath:@"title"`, `valueForKeyPath:@"body"`,
`valueForKeyPath:@"author"`, and `valueForKeyPath:@"publication_date"` against the dictionary to determine if there is any data available for
mapping. If any data is found, it will set the data on the target object by invoking `setValue:forKeyPath:`. In the above example, RestKit will
find the data for the title via `valueForKeyPath:@"title"` and then set the title attribute of our Article object to 
"RestKit Object Mapping Intro" and "RestKit 1.0 Released", respectively. This process is repeated for all the attributes and relationships
defined in the object mapping. It is worth noting that although the key paths are often symmetrical between the source and destination objects
(i.e. mapping a title to a title), they do not have to be and you can store your data in more logical or idiomatic names as appropriate (i.e. 
we mapped `publication_date` to `publicationDate` so that it fits better with Cocoa naming conventions).

From this example, it should now be clear that object mapping can be thought of as a declarative, key-value coding chainsaw for your JSON/XML
data.  We have declared that any time data is found underneath the `@"articles"` keyPath, it should be processed using the `articleMapping` and thus
transformed into one or more instances of the `Article` class. Once mappable data is found, we have declared that values existing at a given source
key path should be assigned to the target object at the destination key path. This is the fundamental trick of object mapping and all other features
are built upon this foundation.

## Object Mapping Fundamentals

Now that we have established a foundation for the basics of object mapping, we can explore the remaining portions of the system. We'll examine
various use-cases of object mapping in turn with brief discussion and code samples.

### Type Transformation

One of the notable features of object mapping is that it infers a great deal of information about your intentions by leveraging the dynamic
features of the Objective-C runtime. RestKit will examine the source and destination types of your attribute at mapping time and perform a
variety of type transformations for you. This feature eliminates a great deal of glue code that you would otherwise have to write if you
were assigning a parsed data structure to your object model manually. The following table enumerates a number of available transformations 
from a source type to a destination type that are automatically applied when you define an attribute mapping:

<table>
    <tr style="font-weight: bold;">
        <th>Source Type</th>
        <th>Destination Type</th>
        <th>Discussion</th>
    </th>
    <tr>
        <td>NSString</td>
        <td>NSDate</td>
        <td>NSString values are mapped to NSDate properties by applying the date format strings from the RKObjectMapping instance.</td>
    </tr>
    <tr>
        <td>NSString</td>
        <td>NSURL</td>
        <td>NSString values are mapped to NSURL properties via <pre><code>[NSURL URLWithString:(NSString*)value]</pre></code></td>
    </tr>
    <tr>
        <td>NSString</td>
        <td>NSDecimalNumber</td>
        <td>NSString values are mapped to NSDecimalNumber properties via <pre><code>[NSDecimalNumber decimalNumberWithString:(NSString*)value]</pre></code></td>
    </tr>
    <tr>
        <td>NSString</td>
        <td>NSNumber</td>
        <td>NSString values are mapped to NSNumber properties via <pre><code>[NSNumber numberWithDouble:[(NSString*)value doubleValue]]</pre></code></td>
    </tr>
    <tr>
        <td>NSString containing YES, NO, true, false, t, f</td>
        <td>NSNumber</td>
        <td>NSString values containing a known boolean string are mapped to NSNumber properties via <pre><code>[NSNumber numberWithBool:boolValueFromString]</pre></code></td>
    </tr>
    <tr>
        <td>NSSet</td>
        <td>NSArray</td>
        <td>NSSet values are mapped to NSArray properties via <pre><code>[(NSSet*)value allObjects]</pre></code></td>
    </tr>
    <tr>
        <td>NSArray</td>
        <td>NSSet</td>
        <td>NSArray values are mapped to NSSet properties via <pre><code>[NSSet setWithArray:value]</pre></code></td>
    </tr>
    <tr>
        <td>NSNumber</td>
        <td>NSDate</td>
        <td>NSNumber values are mapped to NSDate properties via <pre><code>[NSDate dateWithTimeIntervalSince1970:[(NSNumber*)value intValue]]</pre></code></td>
    </tr>
    <tr>
        <td>NSCFBoolean</td>
        <td>NSString</td>
        <td>Boolean literals true and false parsed from JSON are mapped to NSString properties as @"true" and @"false"</td>
    </tr>
    <tr>
        <td>NSNull</td>
        <td>Anything</td>
        <td>NSNull entries (null in JSON) are mapped to nil for any destination property.</td>
    </tr>
    <tr>
        <td>respondsToSelector:@selector(stringValue)</td>
        <td>NSString</td>
        <td>Any mappable value can be mapped to an NSString property if the object responds to the stringValue selector. This works for NSNumbers, etc.</td>
    </tr>
</table>

### Relationships

In addition to mapping simple attributes, RestKit is also capable of mapping arbitrarily complex object graphs. Relationship mappings are configured
very similarly to attribute mapping, but with one notable addition: they are initialized with an object mapping for the relationship. To understand this, let's
extend our previous articles JSON to contain some nested relationship data:

```json
    { "articles": [
        { "title": "RestKit Object Mapping Intro",
          "body": "This article details how to use RestKit object mapping...",
          "author": {
              "name": "Blake Watters",
              "email": "blake@restkit.org"
          },
          "publication_date": "7/4/2011"
        }]
    }
```

Notice that we have changed the structure of the "author" field. Rather than being a simple string, it now contains a nested dictionary. We want
to represent this nested dictionary as a new type in our object model -- the Author class. Let's pull together a data model for our author data:

```objc
    @interface Author : NSObject
        @property (nonatomic, retain) NSString* name;
        @property (nonatomic, retain) NSString* email;
    @end
```

Now we just need to configure RestKit to map the data appropriately. Let's extend our previous articleMapping to include the new author relationship:

```objc
    // Create our new Author mapping
    RKObjectMapping* authorMapping = [RKObjectMapping mappingForClass:[Author class]];
    // NOTE: When your source and destination key paths are symmetrical, you can use mapAttributes: as a shortcut
    [authorMapping mapAttributes:@"name", @"email", nil];
    
    // Now configure the Article mapping
    RKObjectMapping* articleMapping = [RKObjectMapping mappingForClass:[Article class]];
    [article mapKeyPath:@"title" toAttribute:@"title"];
    [article mapKeyPath:@"body" toAttribute:@"body"];
    [article mapKeyPath:@"author" toAttribute:@"author"];
    [article mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];
    
    // Define the relationship mapping
    [article mapKeyPath:@"author" toRelationship:@"author" withObjectMapping:authorMapping];
    
    [[RKObjectManager sharedManager].mappingProvider setObjectMapping:articleMapping forKeyPath:@"articles"];
```

That's all there is to it. RestKit is now configured to map the above JSON into an array of Article objects, each of which has a related Author object. The
configuration is the same for a nested array of data -- if RestKit encounters an array at mapping time it will map each element in the array using the supplied
mapping and assign the mapped collection back to the destination property.

### Object Serialization

Until now we have been concerned with loading remote object representations into our applications and mapping them into local objects. RestKit also supports
an object mapping powered mechanism for serializing local objects into a textual format for submission back to your backend system for processing. This facility
is provided by the `RKObjectSerializer` class. It is important to note that serialization is just another object mapping operation -- it leverages the same core
engine that is used to map parsed objects into local domain objects. The fundamental difference is that the target output of a serialization operation is an 
NSMutableDictionary. The attributes and relationships of your local domain objects are mapped into an intermediate dictionary implementation so that they can
then be run through an encoder to produce URL Form Encoded or JSON data to be sent in the body of the request.

Enough theory, let's take a look at how we configure object serialization. In addition to its duties in providing the object mapper with mappings for key paths,
`RKObjectMappingProvider` has a secondary responsibility of providing the appropriate mapping for serializing an object of a given type. There are a couple of 
options for configuring serialization that are best understood through code:

```objc
    // Configure a serialization mapping for our Article class. We want to send back title, body, and publicationDate
    RKObjectMapping* articleSerializationMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [articleSerializationMapping mapAttributes:@"name", @"body", @"publicationDate", nil];
    
    // Now register the mapping with the provider
    [[RKObjectManager sharedManager].mappingProvider setSerializationMapping:articleSerializationMapping forClass:[Article class]];
```

We have now built an object mapping that can take our local `Article` objects and turn them back into `NSMutableDictionary` instances and 
we have told the mapping provider how the mapping and classes are related. Life is good -- let's see how it comes into play in the app:

```objc
    // Create a new Article and POST it to the server
    Article* article = [Article new];
    article.title = @"This is my new article!";
    article.body = @"RestKit is pretty cool. This is kinda slick.";
    [[RKObjectManager sharedManager] postObject:article delegate:self];
```

So how do these pieces connect, you may be asking? When we use postObject:, we are essentially asking RestKit to create and perform an 
object serialization on our behalf. Behind the scenes, the following things have just happened:

1. `RKObjectManager` initializes an `RKObjectLoader` instance with a sourceObject property targeting our article object.
1. The `serializationMIMEType` property of the `RKObjectLoader` is set to value of the `serializationMIMEType` property on `RKObjectManager`. This
establishes the destination format to serialize the object into (either URL Form Encoded or JSON, as of this writing). More on this in a moment.
1. `RKObjectManager` asks the `mappingProvider` for the `serializationMappingForClass:[Article class]` to obtain the serialization mapping
for the source object. The serialization mapping is assigned to the `RKObjectLoader` instance on the `serializationMapping` property.
1. The `RKObjectLoader` notices that it has a sourceObject and is performing a POST or PUT request. This triggers serialization to kick in.
1. The `RKObjectLoader` instance initializes an `RKObjectSerializer` with the `sourceObject` and `serializationMapping` configured on the loader.
1. The `RKObjectSerializer` is invoked to build and return a serialized representation of the object in the `serializationMIMEType` format and that
value is assigned to the body of the loader.
1. The asynchronous request is sent off for processing with the serialized data in tow.

We have packed quite a bit of power into just a few lines of code. Let's fill in some of the missing details. As mentioned above, the format the data
takes when being assigned to the request is determined by the value of the `serializationMIMEType` property. We can change this easily:

```objc
    // Globally use JSON as the wire format for POST/PUT operations
    [RKObjectManager sharedManager].serializationMIMEType = RKMIMETypeJSON;
    
    // Or switch on a per request basis
    RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderForObject:article method:RKRequestMethodPOST delegate:self];
    objectLoader.serializationMIMEType = RKMIMETypeFormURLEncoded;
    [objectLoader send];
```

Because serialization uses `NSMutableDictionary` as the intermediate format, new MIME Types such as XML, Protocol Buffers, BSON, etc. can be added
down the line without major changes to the serializer. We'll examine how this all works in greater depth in the `RKParser` discussion.

Something else you may have noticed when configuring the serialization mapping is that most of the time our serialization mappings are extremely similar
to our object mappings -- except the source and destination key paths are reversed and the destination class is always `NSMutableDictionary`. RestKit 
understands and recognizes this relationship between our mappings and provides some extremely convenient shortcuts for configuring serialization:

```objc
    // Our familiar articlesMapping from earlier
    RKObjectMapping* articleMapping = [RKObjectMapping mappingForClass:[Article class]];
    [article mapKeyPath:@"title" toAttribute:@"title"];
    [article mapKeyPath:@"body" toAttribute:@"body"];
    [article mapKeyPath:@"author" toAttribute:@"author"];
    [article mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];
    
    // Build a serialization mapping by inverting our object mapping. Includes attributes and relationships
    RKObjectMapping* articleSerializationMapping = [articleMapping inverseMapping];
    // You can customize the mapping here as necessary -- adding/removing mappings
    [[RKObjectManager sharedManager].mappingProvider setSerializationMapping:articleSerializationMapping forClass:[Article class]]; 
```
    
### Mapping without KVC
    TODO: new registerMapping method
### Core Data
    primary keys
    default values
### Handling Dynamic Nesting Attributes
### Key-value Validation

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
