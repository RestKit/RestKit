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
[articleMapping mapKeyPath:@"title" toAttribute:@"title"];
[articleMapping mapKeyPath:@"body" toAttribute:@"body"];
[articleMapping mapKeyPath:@"author" toAttribute:@"author"];
[articleMapping mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];

[[RKObjectManager sharedManager].mappingProvider setMapping:articleMapping forKeyPath:@"articles"];
```

Let's consider what we've done here. In the first line, we created an instance of `RKObjectMapping` defining a mapping
for the `Article` class. We then configured the mapping to define rules for transforming data within the parsed payload to attributes
on an instance of `Article`. Finally, we instructed the mapping provider to use `articleMapping` whenever it encounters data at the `@"articles"`
key path. 

Now that we have configured our object mapping, we can load this collection:

```objc
- (void)loadArticles {
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/articles" delegate:self];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
    RKLogInfo(@"Load collection of Articles: %@", objects);
}
```

Recall the importance of key-value coding to the process. When we loaded the example JSON above via RestKit with the articleMapping configuration in
place, the following things happened:

1. RestKit created an instance of `RKObjectMapper` with the parsed JSON payload and the mapping provider. The mapper is responsible for figuring
out how to map an opaque collection of potentially mappable data.
1. The `RKObjectMapper` instance asked the mapping provider for a list of mappable key paths. Each key path was evaluated against the parsed
payload using valueForKeyPath:. Since we configured a mapping for the `@"articles"` key path, RestKit invoked `valueForKeyPath:@"articles"` on the
parsed data and found the mappable data.
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

We also need to change `author` property type in `Article` from `NSString*` to `Author*`:

```objc
@interface Article : NSObject
    @property (nonatomic, retain) NSString* title;
    @property (nonatomic, retain) NSString* body;
    @property (nonatomic, retain) Author* author;
    @property (nonatomic, retain) NSDate*   publicationDate;
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
[articleMapping mapKeyPath:@"title" toAttribute:@"title"];
[articleMapping mapKeyPath:@"body" toAttribute:@"body"];
[articleMapping mapKeyPath:@"author" toAttribute:@"author"];
[articleMapping mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];

// Define the relationship mapping
[articleMapping mapKeyPath:@"author" toRelationship:@"author" withMapping:authorMapping];

[[RKObjectManager sharedManager].mappingProvider setMapping:articleMapping forKeyPath:@"articles"];
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
[articleMapping mapKeyPath:@"title" toAttribute:@"title"];
[articleMapping mapKeyPath:@"body" toAttribute:@"body"];
[articleMapping mapKeyPath:@"author" toAttribute:@"author"];
[articleMapping mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];

// Build a serialization mapping by inverting our object mapping. Includes attributes and relationships
RKObjectMapping* articleSerializationMapping = [articleMapping inverseMapping];
// You can customize the mapping here as necessary -- adding/removing mappings
[[RKObjectManager sharedManager].mappingProvider setSerializationMapping:articleSerializationMapping forClass:[Article class]]; 
```
    
### Mapping without KVC

As should be obvious by now, RestKit is a big believer in KVC and offers a very seamless workflow if your JSON conforms
to the patterns. But sadly this is not always the case -- many web API's return their JSON without any nesting attributes that
can be used for mapping selection. In these cases you can still work with RestKit, you just have to be explicit about how your
content is to be handled. Let's consider another example: Imagine that our weblog services returning articles works just as before,
but the JSON output looks like this:

```json
[
    { "title": "RestKit Object Mapping Intro",
      "body": "This article details how to use RestKit object mapping...",
      "author": {
          "name": "Blake Watters",
          "email": "blake@restkit.org"
      },
      "publication_date": "7/4/2011"
    }
]
```

We no longer have the outer @"articles" key path to identify our content and instead have a plain old fashioned array. We'll configure
our mappings much the same, but a slight difference in the registration with the mapping provider:

```objc
// Our familiar articlesMapping from earlier
RKObjectMapping* articleMapping = [RKObjectMapping mappingForClass:[Article class]];
[articleMapping mapKeyPath:@"title" toAttribute:@"title"];
[articleMapping mapKeyPath:@"body" toAttribute:@"body"];
[articleMapping mapKeyPath:@"author" toAttribute:@"author"];
[articleMapping mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];

[[RKObjectManager sharedManager].mappingProvider addObjectMapping:articleMapping];
```

Rather than leveraging `setMapping:forKeyPath:`, we have invoked `addObjectMapping:`. This method essentially adds a retained reference
to the mapping provider so that we can easily get the mapping back later when we need it via `objectMappingForClass:`. Let's take a look at how
we'd load this array of `Article` objects:

```objc
- (void)loadArticlesWithoutKVC {
    RKObjectMapping* articleMapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[Article class]];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/articles" objectMapping:articleMapping delegate:self];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
    RKLogInfo(@"Load collection of Articles: %@", objects);
}
```

We've had to take the extra step of providing the object mapping directly to the object loader so that RestKit knows what to do with
the object. This can sometimes be necessary when using serialization as well. Consider another example: We have a system where we post an
ArticleQuery object and get back a collection of Articles. Our ArticleQuery object looks like this:

```objc
@interface ArticleQuery
@property (nonatomic, retain) NSString* searchTerm;
@property (nonatomic, retain) NSNumber* pageNumber;
@property (nonatomic, retain) NSNumber* yearPublished;
@end
```

We have configured a serialization mapping for the object and want to fetch our results:

```objc
- (void)loadArticlesUsingQuery {
    ArticleQuery* query = [ArticleQuery new];
    query.searchTerm = @"Monkey";
    query.pageNumber = [NSNumber numberWithInt:5];
    query.yearPublished = [NSNumber numberWithInt:2011];
    
    RKObjectMapping* articleMapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[Article class]];
    [[RKObjectManager sharedManager] postObject:query mapResponseWith:articleMapping delegate:self];
}
```
One inconvenience of working with non-KVC data is that RestKit is completely unable to automatically infer the appropriate mappings for you. If you
happen to be working with data where you post/put an object and receive the same object back, you can instruct RestKit to automatically select the
appropriate object mapping for you:

```objc
    [RKObjectManager sharedManager].inferMappingsFromObjectTypes = YES;
    [[RKObjectManager sharedManager] postObject:article delegate:self];
```

This will cause RestKit to search the mapping provider for the first registered mapping targeting the `Article` class and configure the
object loader to map the results with that mapping. This is provided as a convenience for users who cannot use KVC mappings and is disabled by 
default.

### Core Data

Until now we have focused on transient objects within RestKit. For many applications transient objects are completely the right choice --
if your data set is constantly changing and your use-cases can rely on the availability of network access, using transient objects is a 
simpler, easier way forward. But for some applications, you really need the full power of a queryable, persistent object model for performance,
flexibility, offline access, etc. Apple has provided a great solution in Core Data. RestKit integrates with Core Data to bridge the gap between
your remote server backend and your local object model. Since Core Data managed objects are KVC compliant, we get much of the integration "for free".
But there are some Core Data specific steps and features that you must understand to leverage the persistence.

First off, when you begin using Core Data you must import the Core Data headers, then configure an object store and connect it your object manager. 
The object store is a RestKit component that handles the details of setting of a Core Data environment that is backed with a SQLite database. Let's
take a look at how this works:

```objc
#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

RKObjectManager* objectManager = [RKObjectManager managerWithBaseURL:@"http://restkit.org"];
RKManagedObjectStore* objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"MyApp.sqlite"];
objectManager.objectStore = objectStore;
```

Now that we have set up the object store, we can configure persistent mappings. Let's say that we want to take our familiar Article object
and make it persistent. You'll have to create a Core Data Managed Object Model and add it to your project. The configuration is outside the
scope of this document, but there are great resources about how this works all over the net. Having done that, we'll update the Article 
interface & implementation, then configure a managed object mapping:

```objc
@interface Article : NSManagedObject
    @property (nonatomic, retain) NSNumber* articleID;
    @property (nonatomic, retain) NSString* title;
    @property (nonatomic, retain) NSString* body;
    @property (nonatomic, retain) NSDate*   publicationDate;
@end

@implementation Article
// We use @dynamic for the properties in Core Data
@dynamic title;
@dynamic body;
@dynamic author;
@dynamic publicationDate;
@end

// Now for the object mappings
RKManagedObjectMapping* articleMapping = [RKManagedObjectMapping objectMappingForClass:[Article class]];
[articleMapping mapKeyPath:@"id" toAttribute:@"articleID"];
[articleMapping mapKeyPath:@"title" toAttribute:@"title"];
[articleMapping mapKeyPath:@"body" toAttribute:@"body"];
[articleMapping mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];
articleMapping.primaryKeyAttribute = @"articleID";
```

The astute reader will notice a couple of things:

1. We changed our inheritance to NSManagedObject from NSObject
1. Our properties are now implemented via @dynamic instead of @synthesize
1. We have added a new property -- articleID. Typically when you load a remote object it is going to include a unique
primary key attribute that uniquely identifies that particular entity. This attribute is typically either an integer or
a string (i.e. a UUID or permalink).
1. We instantiated `RKManagedObjectMapping` instead of `RKObjectMapping`.
1. We have added a new key-path to attribute mapping specifying that we expect an "id" attribute in the payload. In our JSON,
we'd see a fragment like `"id": 12345` added to the dictionary for each Article.
1. We have a new property set on the articleMapping: `primaryKeyAttribute`. This property is significant because it helps RestKit
understand how to uniquely identify your objects and perform intelligently update existing instances. The primaryKeyAttribute is used
to look up an existing object instance by server-side primary key and map updates onto that object instance. If you do not specify a 
primaryKeyAttribute, then you will get new objects created every time you trigger object mapping.

### Handling Dynamic Nesting Attributes

A common, though somewhat annoying pattern in some JSON API's is the use of dynamic attributes as the keys for mappable object data.
This commonly shows up with JSON like the following:

```json
{ "blake": {
    "email": "blake@restkit.org",
    "favorite_animal": "Monkey"
    }
}
```

We might have a User class like the following:

```objc
@interface User : NSObject
@property (nonatomic, retain) NSString* email
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* favoriteAnimal;
@end
```

You will note that this JSON is problematic compared to our earlier examples because the `username` attribute's data
exists as the key in a dictionary, rather than a value. We handle this by creating an object mapping and using a new
type of mapping definition:

```json
RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[User class]];
[mapping mapKeyOfNestedDictionaryToAttribute:@"username"];
[mapping mapFromKeyPath:@"(username).email" toAttribute:"email"];
[mapping mapFromKeyPath:@"(username).favorite_animal" toAttribute:"favoriteAnimal"];
```

What happens with this type of object mapping is that when applied against a dictionary of data,
the keys are interpreted to contain the value for the nesting attribute (so "blake" becomes `username`). When
the remaining attribute and relationship key paths are evaluated against the parsed data, the value of the nesting attribute
is substituted into the key path before it is applied. So your @"(username).email" key path becomes @"blake.email" and the
mapping continues.

Note that there annoying limitations with this. It is common for many API's to use e-mail addresses as dynamic keys in this
fashion. This doesn't fly with KVC because the @ character is used to denote array operations.

There is also a subtlety with nesting mappings and collections like this:

```json
{
  "blake": {        
    "email": "blake@restkit.org",        
    "favorite_animal": "Monkey"    
  },    
  "sarah": {
    "email": "sarah@restkit.org",   
    "favorite_animal": "Cat"
  }
}
```

In these cases it is impossible for RestKit to automatically determine if the dictionary represents a single object or
a collection with dynamic attributes. In these cases, you must give RestKit a hint if you have a collection:

```json
RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[User class]];
mapping.forceCollectionMapping = YES;
[mapping mapKeyOfNestedDictionaryToAttribute:@"username"];
[mapping mapFromKeyPath:@"(username).email" toAttribute:"email"];
[mapping mapFromKeyPath:@"(username).favorite_animal" toAttribute:"favoriteAnimal"];
```
### Dynamic Object Mapping

Thus far we have examined clear-cut cases where the appropriate object mapping can be determined either by consulting the
key path or by the developer directly providing the mapping. Sometimes it is desirable to dynamically determine the appropriate
object mapping to use at mapping time. Perhaps we have a collection of objects with identical attribute names, but we wish
to represent them differently. Or maybe we are loading a collection of objects that are not KVC compliant, but contain a mixture
of types that we would like to model. RestKit supports such use cases via the RKObjectDynamicMapping class. 
RKObjectDynamicMapping is a sibling class to RKObjectMapping and can be added to instances of RKObjectMappingProvider and
used to configure RKObjectMappingOperation instances. RKObjectDynamicMapping allows you to hook into the mapping process
and determine an appropriate RKObjectMapping to use on a per-object basis. 

When RestKit is performing a mapping operation and the current mapping being applied is an RKObjectDynamicMapping instance,
the dynamic mapping will be sent the `objectMappingForDictionary:` message with the NSDictionary that is currently being 
mapped. The dynamic mapping is responsible for introspecting the contents of the dictionary and returning an RKObjectMapping
instance that can be used to map the data into a concrete object.

There are three ways in which the determination of the appropriate object mapping can be made:

1. Via a declarative matcher on an attribute within the mappable data. If your dynamic data contains an attribute that can
be used to infer the appropriate object type, then you are in luck -- RestKit can handle the dynamic mapping via simple 
configuration.
2. Via a delegate callback. If your data requires some special analysis or you want to dynamically construct an object mapping
to handle the data, you can assign a delegate to the RKObjectDynamicMapping and you will be called back to perform whatever
logic you need to implement the object mapping lookup/construction.
3. Via a delegate block invocation. Similar to the delegate configuration, you can assign a delegateBlock to the RKObjectDynamicMapping that will be invoked to determine the appropriate RKObjectMapping to use for the mappable data.

To illustrate these concepts, let's consider the following JSON fragment:

```json
{
    "people": [
        {
            "name": "Blake Watters",
            "type": "Boy",
            "friends": [
                {
                    "name": "John Doe",
                    "type": "Boy"
                },
                {
                    "name": "Jane Doe",
                    "type": "Girl"
                }
            ]
        },
        {
            "name": "Sarah",
            "type": "Girl"
        }
    ]
}
```

In this JSON we have a dictionary containing an array of people at the "people" key path. We want to map each of the 
people within that collection into different classes: `Boy` and `Girl`. Our meaningful attributes are the name and
the friends, which is itself a dynamic collection of people. The `type` attribute will be used to determine what
the appropriate destination mapping and class will be. Let's set it up:

```objc
// Basic setup
RKObjectMapping* boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
[boyMapping mapAttributes:@"name", nil];
RKObjectMapping* girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
[girlMapping mapAttributes:@"name", nil];
RKObjectDynamicMapping* dynamicMapping = [RKObjectDynamicMapping dynamicMapping];
[boyMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];
[girlMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];

// Connect our mapping to RestKit's mapping provider
[[RKObjectManager sharedManager].mappingProvider setMapping:dynamicMapping forKeyPath:@"people"];

// Configure the dynamic mapping via matchers
[dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
[dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];

// Configure the dynamic mapping via a delegate
dynamicMapping.delegate = self;

- (RKObjectMapping*)objectMappingForData:(id)data {
    // Dynamically construct an object mapping for the data
    if ([[data valueForKey:@"type"] isEqualToString:@"Girl"]) {
        return [RKObjectMapping mappingForClass:[Girl class] block:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    } else if ([[data valueForKey:@"type"] isEqualToString:@"Boy"]) {
        return [RKObjectMapping mappingForClass:[Boy class] block:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }
    
    return nil;
}

// Configure the dynamic mapping via a block
dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
    if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
        return boyMapping;
    } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
        return girlMapping;
    }
    
    return nil;
};
```

Notable within this code are the calls to `setObjectMapping:whenValueOfKeyPath:isEqualTo:`. This is the declarative
matcher form of dynamic configuration. When you use these matchers, RestKit will invoke `valueForKeyPath:` on your
mappable data and then attempt to compare the resulting value with the value provided in the invocation. If you have
a simple string or numeric value that can be used to differentiate your mappings, then you don't need to use the 
delegate or block callbacks at all to perform dynamic mapping.

That's all there is to it. RestKit will invoke the dynamic mapping with the data and apply whatever object
mapping is returned to that data. You can even decline the mapping of individual elements by returning a nil mapping.
This can be useful to filter out unwanted information deep within an object graph.

### Key-value Validation

RestKit supports the use of key-value validation at mapping time. This permits a number of helpful additions to your
workflow. Using KVC validation, you can:

1. Reject inappropriate values coming back from the server.
1. Perform custom transformations of values returned from the server.
1. Fail out the mapping operation using custom logic.

Unlike the vast majority of the work we have done thus far, key-value validation is performed by adding methods onto your model class. KVC validation is
a standard part of the Cocoa stack, but must be manually invoked on NSObject's. It is always performed for you on Core Data 
managed object when the managed object context is saved. RestKit provides KVC validation for you when object mapping is taking place.

Let's take a look at how you can leverage key-value validation to perform the above three tasks on our familiar Article object:

```objc
@implementation Article
- (BOOL)validateTitle:(id *)ioValue error:(NSError **)outError {
    // Force the title to uppercase
    *iovalue = [(NSString*)iovalue uppercaseString];
    return YES;
}

- (BOOL)validateArticleID:(id *)ioValue error:(NSError **)outError {
    // Reject an article ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}
 
- (BOOL)validateBody:(id *)ioValue error:(NSError **)outError {
    // If the body is blank, return NO and fail out the operation.
    if ([(NSString*)ioValue length] == 0) {
        *outError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorUnmappableContent userInfo:nil];
        return NO;
    }
    
    return YES;
}
@end
```

These three methods will get invoked when the appropriate attribute is going to be set on the Article objects being mapped. The ioValue
is a pointer to a pointer of the object reference that will be assigned to attribute. This means that we can completely change the value
being assigned to anything that we want. If we return NO from the function, the assignment will not take place. We can also return NO
and construct an error object and set the `outError`. This will cause mapping to fail and the error will bubble back up the RestKit stack.

Look at the NSKeyValueCoding.h and search the web for more info about key-value validation in general.

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
path by interpolating property values into a string. For example, a path of "/articles/:articleID" when applied to an Article object with a `articleID` property
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
RKObjectRelationshipMapping* articleCommentsMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"comments" toKeyPath:@"comments" withMapping:commentMapping];
[mapping addRelationshipMapping:articleCommentsMapping];

// Configuration using helper methods
[mapping mapRelationship:@"comments" withMapping:commentMapping];
[mapping hasMany:@"comments" withMapping:commentMapping];
[mapping belongsTo:@"user" withMapping:userMapping];    

// Register the mapping with the object manager
[objectManager.mappingProvider setMapping:mapping forKeyPath:@"article"];
```

### Configuring a Core Data Object Mapping
```objc
#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

RKObjectManager* objectManager = [RKObjectManager managerWithBaseURL:@"http://restkit.org"];
RKManagedObjectStore* objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"MyApp.sqlite"];
objectManager.objectStore = objectStore;

RKManagedObjectMapping* articleMapping = [RKManagedObjectMapping objectMappingForClass:[Article class]];
[articleMapping mapKeyPath:@"id" toAttribute:@"articleID"];
[articleMapping mapKeyPath:@"title" toAttribute:@"title"];
[articleMapping mapKeyPath:@"body" toAttribute:@"body"];
[articleMapping mapKeyPath:@"publication_date" toAttribute:@"publicationDate"];
articleMapping.primaryKeyAttribute = @"articleID";
```

### Loading Using KeyPath Mapping Lookup
```objc
RKObjectManager* objectManager = [RKObjectManager managerWithBaseURL:@"http://restkit.org"];
RKManagedObjectMapping* articleMapping = [RKObjectMapping objectMappingForClass:[Article class]];
[articleMapping mapKeyPath:@"id" toAttribute:@"articleID"];
[objectManager.mappingProvider setMapping:articleMapping forKeyPath:@"articles"];

RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/articles" delegate:self];

/**
 The object mapper will try to determine the mappings by examining keyPaths in the loaded payload. If 
 the payload contains a dictionary with data at the 'articles' key, it will be mapped
 */
```

### Load using an explicit mapping
```objc
RKObjectMapping* articleMapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[Article class]];
[RKObjectManager loadObjectsAtResourcePath:@"/objects" objectMapping:articleMapping delegate:self];
```

### Using Object Mapping Block Helpers
```objc
[[RKObjectManager sharedManager] postObject:user delegate:self block:^(RKObjectLoader* loader) {
  loader.objectMapping = [RKObjectMapping mappingForClass:[User class] block:^(RKObjectMapping* mapping) {
      mapping.rootKeyPath = @"user";
      [mapping mapAttributes:@"password", nil];
      [mapping mapKeyPath:@"passwordConfirmation" toAttribute:@"password_confirmation"];
  }];
}];
```

### Configuring the Serialization Format
```objc
// Serialize to Form Encoded
[RKObjectManager sharedManager].serializationMIMEType = RKMIMETypeFormURLEncoded;

// Serialize to JSON
[RKObjectManager sharedManager].serializationMIMEType = RKMIMETypeJSON;
```

### Object Serialization Tasks
This is handled for you when using postObject and putObject, presented here for reference

```objc
RKUser* user = [User new];
user.firstName = @"Blake";
user.lastName = @"Watters";

RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
[mapping mapAttributes:@"firstName", @"lastName", nil];

RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:serializationMapping];
NSError* error = nil;

// Turn an object into a dictionary
NSMutableDictionary* dictionary = [serializer serializedObject:&error];

// Serialize the object to JSON
NSString* JSON = [serializer serializedObjectForMIMEType:RKMIMETypeJSON error:&error];

// Turn it into a RKRequestSerializable
id<RKRequestSerializable>serializable = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
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
