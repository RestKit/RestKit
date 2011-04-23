# Object Mapping 2.0


## Goals
- Support arbitrary JSON structures
- Provide hooks into the mapping process for easier tracing and debugging
- Simplify the mapping operations. Clean up the code in RKObjectMapper thoroughly
- Allow mapping directly to NSObject and NSManagedObject??? _Maybe._

## New Classes
- RKObjectMappable -> Returns an + (RKObjectMapping*)objectMapping defining how to transform a dictionary into an instance of the type
- RKObjectMapping
- RKObjectMapper -> No longer a singleton instance. A new mapper is created to process each dictionary encountered.
- RKObjectLoader

## Tasks

### Initialize the object manager
    RKObjectManager* objectManager = [RKObjectManager managerWithBaseURL:@"http://restkit.org"];
    [objectManager setParser:[RKJSONKitParser class] forMIMEType:@"application/json"]; // TODO: Should this be settable on the object loader??

### Registering an Explicit Mapping
    // In this use-case Article could be an NSObject or NSManagedObject class. Take RestKit out of the inheritance hierarchy.
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[Article class]];
    [mapping mapElements:@"title", @"body", nil];
    [mapping mapElementsToProperties:@"created_at", @"createdAt", nil];
    [mapping mapElement:@"comments" toMany:[Comment class]];
    [mapping mapElement:@"author" toOne:[User class] withPrimaryKey:@"author_id"];
    [mapping serializeRelationships:@"comments", nil];
    [objectManager registerMapping:mapping forElement:@"article"]; // TODO: forKeyPath: instead of forElement: / forElementNamed:

### Configure a Mappable class. 
    // In this use case the mapping is returned from the class and registered with the object manager.
    @interface Article : RKObject {        
    }
    @end
    
    @implementation Article
    
    + (RKObjectMapping*)objectMapping {
        return [RKObjectMapping mappingForClass:self withBlock:^(RKObjectMapping* article) {
            [article mapElements:@"title", @"body", nil];
            [article belongsTo:@"user" objectClass:[User class] andPrimaryKey:@"user_id"];
            [article hasMany:@"comments" withClass:[Comment class]];
        }];
    }
    
    @end
    
    [objectManager registerMappable:[RKArticle class] forElement:@"article"];

### Automatic Mapping Generation
    // This method will generate a mapping for a class defining element to property mappings for the public properties
    RKObjectMapping* mapping = [RKObjectMapping generateMappingForClass:[Article class]];
    [objectManager registerMapping:mapping forElement:@"article"];

### Load Mapping from a Property List
    // TODO: Do we want to support this?
    NSArray* mappings = [RKObjectMapping loadMappingsFromPropertyList:@"article.plist"];

### Performing a Mapping
    // RKObjectMapper always returns a single mapped structure from a dictionary. Arrays are handled by iterating and returning 
    @implementation RKObjectLoader
    
    - (void)didFinishLoad {
        id payload = [self.parser parseString:[self bodyAsString]];
        if ([payload isKindOfClass:[NSArray class]]) {
            for (id object in payload) {
                [RKObjectMapper initWithDictionary:object mapping:self.mapping];
            }
        } else if ([payload isKindOfClass:[NSDictionary class]]) {
            RKObjectMapper* mapper = [RKObjectMapper initWithDictionary:object mapping:self.mapping];
            mapper.delegate = self.mappingDelegate;
            id results = [mapper performMapping];
            return results;
        }
    }    

### Loading Using Registered Mapping
    RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/objects" delegate:self];

### Loading to a Registered Class
    // TODO: Do we need this? Just call `[Article objectMapping]` instead???
    RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/objects" toClass:[Article class] delegate:self];

### Load using an explicit mapping
    RKObjectLoader* loader = [RKObjectManager loadObjectsAtResourcePath:@"/objects" withMapping:mapping delegate:self];
    loader.mappingDelegate = self;

## RKObjectLoader Changes
- keyPath -> Can we eliminate this?
- MIMETypesToParserMappings -> Copied down from the object manager, settable on a per-object basis (YAGNI???)
- resourcePath
- mapping (or nil). If nil, the payload is parsed and each element name is looked up and mapped.
- mappingDelegate / mapperDelegate. A delegate to assign to the mapper as processing happens
    