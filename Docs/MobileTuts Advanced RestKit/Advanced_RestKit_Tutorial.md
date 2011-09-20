Advanced Development with RestKit
--

In this article we will continue our exploration of RestKit, an iOS framework for working with web services. It is assumed that the reader has read Part I and has a working knowledge of RestKit. Building on the foundation we established in the introduction, we will examine the advanced capabilities of the library and learn how to accelerate our iOS development efforts.

## What is covered?

* Advanced Networking: Multi-part requests, reachability, the request queue and background upload/download are all covered.
* Advanced Object Mapping: Key-value coding and relationship mapping.
* Core Data: Integration between the object mapper and Apple's Core Data persistence framework are discussed at length. This includes configuration, relationship management, database seeding, etc.
* Integration Layers: We'll briefly touch on the integration points exposed by the library for working with Ruby on Rails backends and interaction with Facebook's Three20 framework.

## Companion Example Code

To aid the reader in following the concepts presented here, an accompanying example application is provided with the RestKit distribution. Each section of the tutorial will refer you to a specific example in the __RKCatalog__ example, found in the RestKit/Examples/RKCatalog directory. 

At the time of this writing, RestKit is currently at version *0.9.2*. Library source and example code can be downloaded from the [RestKit Downloads Page](https://github.com/twotoasters/RestKit/downloads).

## Advanced Networking

We've already been introduced to the key players in the RestKit Network layer: RKClient, RKRequest, and RKResponse. These three classes provide a simple, clean API for making requests to a remote web service. In this section we'll see how RestKit scales up when things get more complicated.

### Request Serialization: Under the Hood

In the introduction to the Network layer, we learned to use RestKit to send requests using the `get`, `post`, `put` and `delete` methods. These methods abstract away the details of constructing a full URL, building a request, populating the request body, and asynchronously sending the request.

We also learned how to embed parameters into our requests by providing an NSDictionary of key/value pairs. Under the covers, RestKit takes this dictionary and constructs a URL encoded HTTP body to attach to the request. The Content-Type header is set to 'application/x-www-form-urlencoded' and the request is sent off for processing. This is a great convenience over having to construct the request bodies ourselves and it is this support that forms the basis of the object mapper.

But what about requests that can't be represented by dictionaries or be loaded into memory all at once? We must look beyond the simplicity afforded by NSDictionary and take a look at two new entities: RKRequestSerializable and RKParams.

Though we often use NSDictionary to represent the parameters for many of our requests, RestKit does not specifically bless NSDictionary. If you looked at the method signature for RKRequest's params argument, you'll note that it does not specify NSDictionary at all. Instead you'll see:

    @property(nonatomic, retain) NSObject<RKRequestSerializable>* params;

Note the RKRequestSerializable protocol here. RKRequestSerializable defines a very lightweight protocol that allows arbitrary classes to serialize themselves for use in the body of an RKRequest. When you import RestKit, it adds a category to NSDictionary providing an implementation of the RKRequestSerializable protocol. RKRequestSerializable defines just a couple of methods that you need to implement to make any object type serializable:

* **HTTPHeaderValueForContentType** - This method returns an NSString value to be used as the Content-Type header for the request. For NSDictionary, we encode the keys/values using form encoding and return 'application/x-www-form-urlencoded' for this method.
* **HTTPHeaderValueForContentLength** - This optional method returns an NSUInteger value to be used as the Content-Length header for the request. This is useful in long running upload requests for the purposes of tracking progress.
* **HTTPBody** - This method returns an NSData object containing the data you want to send as the body of the request. For NSDictionary, we walk through the key/value pairs and construct a URL encoded string. The string is then coerced into an NSData by using the NSUTF8StringEncoding encoding. This method is optional if you provide an implementation of **HTTPBodyStream** (see below).
* **HTTPBodyStream** - This method returns an NSStream object that should be used to read data for use in the request body. HTTPBodyStream will be consulted ahead of HTTPBody during request construction. HTTPBodyStream can be used to provide support for uploading files that exist on disk or are too big to fit into main memory. RestKit will efficiently stream the data off the disk and send it for processing.

### RKParams: Sending Multi-part Requests

Now that we understand how RestKit coerces arbitrary objects into serializable representations, we can look at another implementation of RKRequestSerializable that ships with the library: RKParams. RKParams provides a simple interface for building more complex multi-part requests. You can think of RKParams as an HTTP-aware dictionary implementation. In addition to providing simple objects for the values in our parameters, RKParams also allows us to provide NSData and paths to files on disk. We are also able to set the file name and MIME type of each parameter individually. To illustrate how this works, let's look at some code:

    NSString* myFilePath = @"/some/path/to/picture.gif";
    RKParams* params = [RKParams params];

    // Set some simple values -- just like we would with NSDictionary
    [params setValue:@"Blake" forParam:@"name"];
    [params setValue:@"blake@restkit.org" forParam:@"email"];

    // Create an Attachment
    RKParamsAttachment* attachment = [params setFile:myFilePath forParam:@"image1"];
    attachment.MIMEType = @"image/gif";
    attachment.fileName = @"picture.gif";

    // Attach an Image from the App Bundle
    UIImage* image = [UIImage imageNamed:@"another_image.png"];
    NSData* imageData = UIImagePNGRepresentation(image);
    [params setData:imageData MIMEType:@"image/png" forParam:@"image2"];

    // Let's examine the RKRequestSerializable info...
    NSLog(@"RKParams HTTPHeaderValueForContentType = %@", [params HTTPHeaderValueForContentType]);
    NSLog(@"RKParams HTTPHeaderValueForContentLength = %d", [params HTTPHeaderValueForContentLength]);

    // Send a Request!
    [[RKClient sharedClient] post:@"/uploadImages" params:params delegate:self];

Essentially what we are doing here is creating a stack of RKParamsAttachment objects that are contained within the RKParams instance. With every call to `setValue`, `setFile`, or `setData` we are instantiating a new instance of RKParamsAttachment and adding it to the stack. Each of these methods returns the RKParamsAttachment object it has created for you so that you can further customize it if need be. We see this used to set the `MIMEType` and `fileName` properties for image. When we assign the params object to the RKRequest, it is serialized into a multipart/form-data document and read as a stream by the underlying NSURLConnection. This streaming behavior allows RKParams to be used for reading very large files off of disk without exhausting memory on an iOS device.

**Example Code** - See [RKParamsExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKParamsExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

### The Request Queue

While you have been happily sending requests and processing responses with RKClient, RKRequest, and RKResponse another part of RestKit has been quietly operating behind the scenes, without your knowledge: RKRequestQueue. The Request Queue is an important support player in the RestKit world and becomes increasingly important as your application grows in scope. RKRequestQueue has three primary responsibilities: managing request memory, ensuring the network does not get overly burdened, and managing request life cycle.

Memory management can become very tiresome in Cocoa applications, as so much work happens asynchronously. RestKit is all about reducing the complexity and ceremony associated with working with web services in Cocoa and as such provides RKRequestQueue to shift the memory management concerns away from the application developer and into the framework. Recall what a typical RestKit request/response looks like:

    - (void)sendARequest {
      RKRequest* request = [[RKClient sharedClient] get:@"/some/path" delegate:self];
      NSLog(@"Sent a request! %@", request);
    }

    - (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
      if ([response isJSON]) {
        NSLog(@"Got a JSON response back!");
      }
    }

Notice that there isn't a single call to retain, release or autorelease anywhere in sight. This is where the request queue comes into play. When we ask to send an RKRequest object, it isn't immediately dispatched. Instead it is retained by the RKClient's requestQueue instance and sent as soon as possible. RestKit watches for notifications generated by RKRequest & RKResponse and releases its hold on the request after processing has completed. This allows us to work with web services with very little thought about the memory management.

In addition to retaining & releasing RKRequest instances, RKRequestQueue also serves as a gatekeeper to the network access itself. When the application is first launched or returns from a background state, RestKit uses its integration with the System Configuration Reachability API's to determine if any network access is available. When talking to a remote server by hostname, there can be a delay between launch and the determination of network availability. During this time, RestKit is in an indeterminate reachability state and RKRequestQueue will defer sending any requests until network reachability can be determined. Once reachability is determined, RKRequestQueue prevents the network from becoming overburdened by limiting the number of concurrent requests to five.

Once your user interfaces begin spanning multiple controllers and users are navigating the controller stack quickly, you may begin generating a number of requests that do not need to be completed because the user has dismissed the view. Here we turn to ___RKRequestQueue___ as well. Let's imagine that we have a controller that immediately begins loading some data when the view appears. But the controller also has a number of buttons that the user can quickly access to change perspectives, making the request we kicked off no longer of interest. We can either hold on to the instances of RKRequest that we generate or we can let ___RKRequestQueue___ do the work for us. Let's see how this would work:

    - (void)viewWillAppear:(BOOL)animated {
      /**
       * Ask RKClient to load us some data. This causes an RKRequest object to be created
       * transparently pushed onto [RKClient sharedClient].requestQueue instance
       */
      [[RKClient sharedClient] get:@"/some/data.json" delegate:self];
    }

    // We have been dismissed -- clean up any open requests
    - (void)dealloc {
      [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
      [super dealloc];
    }

    // We have been obscured -- cancel any pending requests
    - (void)viewWillDisappear:(BOOL)animated {
      [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    }

Rather than managing the request ourselves and doing the housekeeping, we can just ask RKRequestQueue to cancel any requests that we are the delegate for. If there are none currently processing, no action will be taken.

A requestQueue instance is created for you at RKClient initialization time. It is also possible to create additional ad-hoc queues to manage groups of requests
more granularly. For example, an ad-hoc queue could be useful for downloading or uploading content in the background, while keeping the main shared queue free for responding to user actions. Let's take a look at an example of using an ad-hoc queue:

    - (IBAction)queueRequests {
        RKRequestQueue* queue = [[RKRequestQueue alloc] init];
        queue.delegate = self;
        queue.concurrentRequestsLimit = 1;
        queue.showsNetworkActivityIndicatorWhenBusy = YES;

        // Queue up 4 requests
        [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];
        [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];
        [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];
        [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];

        // Start processing!
        [queue start];
    }

In this example we have created an ad-hoc queue that dispatches one request at a time and spins the system network activity indicator. There are a number of delegate methods available for the request queue to make managing groups of requests easier. Check out the RKRequestQueue example in RKCatalog for detailed examples. 

**Example Code** - See [RKRequestQueueExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKRequestQueueExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

### Reachability

As iOS developers, one of the annoying realities we face and must deal with is that of intermittent connectivity. As our users move throughout their world with our applications, connectivity is guaranteed to come and go. Coding for this reality can complicate our logic and distort the intent in our code with conditional logic.

To make matters worse, the SCReachability API's available to us for monitoring network status are implemented as low level C API's. To help ease this burden and provide a platform for higher level functionality, RestKit ships with a wrapper around the low level SCReachability API's: RKReachabilityObserver.

RKReachabilityObserver abstracts away the SCReachability C API's and instead presents a very straight-forward Objective-C interface for determining network status. Let's take a look at some code:

    - (void)workWithReachability {
      /**
       * Initialize an observer against a hostname. Note that we can also provide an IP address in the hostname
       * string and RestKit will configure the observer to watch the network address instead of the host
       */   
      RKReachabilityObserver* observer = [RKReachabilityObserver reachabilityObserverWithHostName:@"restkit.org"];

      // Let the run-loop execute so reachability can be determined
      [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

      if ([observer isNetworkReachable]) {
        NSLog(@"We have network access! Huzzah!");

        if ([observer isConnectionRequired]) {
          NSLog(@"Network is available if we open a connection...");
        }

        if (RKReachabilityReachableViaWiFi == [observer networkStatus]) {
          NSLog(@"Online via WiFi!");
        } else if (RKReachabilityReachableViaWWAN == [observer networkStatus]) {
          NSLog(@"Online via 3G or Edge...");
        }
      } else {
        NSLog(@"No network access.");
      }
    }

Now that we've seen how to initialize and work with RKReachabilityObserver, it's worth noting that most of the time we don't have to! When you initialize RKClient or RKObjectManager with a base URL, RestKit goes ahead and initializes an instance of RKReachabilityObserver targeted at the hostname specified in your base URL. This observer is available to you via the `baseURLReachabilityObserver` property on RKClient. RKReachabilityObserver also emits notifications whenever network state changes. Typically these events are all that you are interested in. Observing the reachability events is easy:

    @implementation ReachabilityInterestedClass

    - (id)init {
      if ((self = [super init])) {
          [[NSNotificationCenter defaultCenter] addObserver:self
                                                    selector:@selector(reachabilityChanged:)
                                                    name:RKReachabilityStateChangedNotification
                                                    object:nil];
      }

      return self;
    }

    - (void)reachabilityChanged:(NSNotification*)notification {
      RKReachabilityObserver* observer = (RKReachabilityObserver*)[notification object];

      if ([observer isNetworkReachable]) {
        NSLog(@"We're online!");
      } else {
        NSLog(@"We've gone offline!");
      }
    }

    @end

**Example Code** - See [RKReachabilityExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKReachabilityExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

We'll explore how RestKit leverages Reachability internally to provide transparent offline access in the Core Data object caching section.

### Background Upload/Download

With iOS 4.0, Apple introduced multi-tasking support for applications. The multi-tasking support relies on putting apps into a background state, where they can be quickly restored to full interactive mode, but not consume resources while in the background. This can present a problem for network applications such as those built with RestKit: important long-running requests can be interrupted by the user switching out of the app. Thankfully Apple also provided limited support for extending the life of your process by creating a background task using the `beginBackgroundTaskWithExpirationHandler` method on `UIApplication`. This method accepts an Objective-C block and returns a `UIBackgroundTaskIdentifier` value for the background task that was created. Care must be taken when creating the background task so that backward compatibility with iOS 3.0 deployments is maintained.

RestKit seeks to ease this burden on the developer by providing simple, transparent support for background tasks during the request cycle. Let's take a look at some code:

    - (void)backgroundUpload {
      RKRequest* request = [[RKClient sharedClient] post:@"somewhere" delegate:self];
      request.backgroundPolicy = RKRequestBackgroundPolicyNone; // Take no action with regard to backgrounding
      request.backgroundPolicy = RKRequestBackgroundPolicyCancel; // If the app switches to the background, cancel the request
      request.backgroundPolicy = RKRequestBackgroundPolicyContinue; // Continue the request in the background
      request.backgroundPolicy = RKRequestBackgroundPolicyRequeue; // Cancel the request and place it back on the queue for next activation
    }

The default policy is RKRequestBackgroundPolicyNone. Once you have set your policy and sent your request, RestKit handles the rest -- switching in and out of the app will cause the appropriate action to happen.

**Example Code** - See [RKBackgroundRequestExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKBackgroundRequestExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

## Advanced Object Mapping

In part one of our series, we introduced the concept of Object Mapping -- the RestKit process for converting JSON payloads into local domain objects. In its most simple form, Object Mapping reduces the tedium associated with parsing simple fields out of a dictionary and assigning them to a target object. But that's not the end of the story for the object mapper.

RestKit also provides support for mapping hierarchies of objects expressed through relationships. This is a powerful feature for importing a large amount of data via a single HTTP request. In this section we'll explore relationship mapping in detail and look at how RestKit supports non-idiomatic JSON structures via key-value coding.

### Dealing with Alternate JSON Structures

Most of the object mapping examples we have examined so far have performed simple mappings from one field to another (i.e. created_at becomes createdAt). If you have complete control over the JSON output of the backend system or are exactly modeling the server side output, this may be all that you ever need to do. But sometimes the realities of the backend system we need to integrate with do not fit so neatly with RestKit's view of the world. If your target JSON contains nested data that you wish to access without decomposing the structures into multiple object types, you will need to leverage the power of key-value coding in your mappings.

Key-value coding is a mechanism for accessing data indirectly in Cocoa by use of a string containing property names, rather than invoking accessor methods or directly accessing instance variables. Key-value coding is one of the most important patterns in Cocoa and is the foundation of RestKit's object mapping system. When RestKit encounters a data payload it knows how to handle, the payload is handed off to the parser for evaluation. The parser then evaluates the data and returns a key-value coding compliant representation of the data in the form of arrays, dictionaries, and basic types. From here, the object mapper begins analyzing the representation and using key-value accessors to retrieve data and assign it to the target object instance. Every time you register an element to class mapping or define an element to property mapping, you are providing a Key-value coding compliant key path to the mapper. This is an important point -- you have the full power of the key-value pattern at your disposal. For example, you can traverse the object graph via dot notation syntax and utilize collection operators to perform actions on collections within your payload.

Let's take a look at some code to get a better understanding of how key-value coding works within RestKit. Consider the following JSON structure for a simplified bank account application:

    {
        "id": 1234,
        "name": "Personal Checking",
        "balance": 5013.26,
        "transactions": [
          {"id": 1, "payee": "Joe Blow", "amount": 50.16},
          {"id": 2, "payee": "Grocery Store", "amount": 200.15},
          {"id": 3, "payee": "John Doe", "amount": 325.00},
          {"id": 4, "payee": "Grocery Store", "amount": 25.15}]
    }

We are going to use key-value coding to access some information within the payload: the number of transactions, the average amount of the transactions, and the distinct group of payees in the transactions list. Here is our model:

    @interface SimpleAccount : RKObject {
      NSNumber* _accountID;
      NSString* _name;
      NSNumber* _balance;
      NSNumber* _transactionsCount;
      NSNumber* _averageTransactionAmount;
      NSArray*  _distinctPayees;
    }
    
    @property (nonatomic, retain) NSNumber* accountID;
    @property (nonatomic, retain) NSString* name;
    @property (nonatomic, retain) NSNumber* balance;
    @property (nonatomic, retain) NSNumber* transactionsCount;
    @property (nonatomic, retain) NSNumber* averageTransactionAmount;
    @property (nonatomic, retain) NSArray*  distinctPayees;
    
    @end
    
    @implementation SimpleAccount
    
    + (NSDictionary*)elementToPropertyMappings {
      return [NSDictionary dictionaryWithKeysAndObjects:
              @"id", @"accountID",
              @"name", @"name",
              @"balance", @"balance",
              @"transactions.@count", @"transactionsCount",
              @"transactions.@avg.amount", @"averageTransactionAmount",
              @"transactions.@distinctUnionOfObjects.payee", @"distinctPayees",
              nil];
    }
    
    @end
    
    // -- snip --
    
    - (void)workWithKVC {
      [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/accounts.json" objectClass:[SimpleAccount class] delegate:self];
    }
    
    - (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
      SimpleAccount* account = [objects objectAtIndex:0];
      
      // Will output "The count is 4"
      NSLog(@"The count is %@", [account transactionsCount]);
      
      // Will output "The average transaction amount is 150.115"
      NSLog(@"The average transaction amount is %@", [account averageTransactionAmount]);
      
      // Will output "The distinct list of payees is: Joe Blow, Grocery Store, John Doe"
      NSLog(@"The distinct list of payees is: %@", [[account distinctPayees] componentsJoinedByString:@", "]);
    }

Now things are getting interesting. Note the new syntax utilized after the balance mapping is defined. We have used key-value coding to traverse down to the transactions array and perform operations on the data. From here, we see the use of several Key-value collection operators. These operators are provided to us by Cocoa and detailed in the "Key-Value Coding Programming Guide" available in the Xcode documentation. The key lesson here is to remember that the object mapper is built with key-value coding in mind and there is additional firepower available beyond simple one-to-one mappings.

Taking advantage of key-value coding in your mappings becomes very useful when working with large, complex JSON payloads where you only care about a subset of the data. But sometimes we actually do care about all that extra information -- we just wish it was available in a more accessible format. In these circumstances we can instead turn to the use of relationship modeling to help RestKit transform a big data payload into an object graph.

**Example Code** - See [RKKeyValueMappingExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKKeyValueMappingExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

### Modeling Relationships

Relationship modeling is expressed via the ___elementToRelationshipMappings___ method on the RKObjectMappable protocol. This method instructs the mapper to take a nested JSON dictionary, perform mapping operations, and assign the result object (or objects) to the property with the given name. This is process is repeated for each mapping operation, allowing object graphs of arbitrary depth to be constructed.

To understand how this works, let's take a look at an example. We are going to walk through the implementation of a Task List data model to illustrate the principles of relationship modeling. The task list example code is contained within the RKRelationshipMappingExample code in the RKCatalog application. Within RKRelationshipMappingExample, there are three data models that are related to one another: Users, Projects, and Tasks. Users are people working within the system. Projects contain a discrete set of steps that work toward a concrete goal that can be completed. Tasks represent each of these concrete steps within a Project. The relationships between them are:

* User has many Projects
* Each Project belongs to a single User
* Each Task belongs to a single Project
* Each Task can be assigned to a single User

The data models can be found in the Code/Models directory of the sample application.

Our application is very simple from a user interface standpoint. We have a single table view that shows all the Projects in the system and the name of the User who created the Project. Clicking on the Project pushes a secondary table view into view that shows all the Tasks contained in the Project. Rather than making multiple requests to individual resource collections to build the view, we are going to request the entire object graph from a single resource path '/task_list'. The JSON returned by the resource path looks like:

      [{"project": {
          "id": 123,
          "name": "Produce RestKit Sample Code",
          "description": "We need more sample code!",
          "user": {
              "id": 1,
              "name": "Blake Watters",
              "email": "blake@twotoasters.com"
          },
          "tasks": [
              {"id": 1, "name": "Identify samples to write", "assigned_user_id": 1},
              {"id": 2, "name": "Write the code", "assigned_user_id": 1},
              {"id": 3, "name": "Push to Github", "assigned_user_id": 1},
              {"id": 4, "name": "Update the mailing list", "assigned_user_id": 1}
          ]
      }},
      {"project": {
          "id": 456,
          "name": "Document Object Mapper",
          "description": "The object mapper could really use some docs!",
          "user": {
              "id": 2,
              "name": "Jeremy Ellison",
              "email": "jeremy@twotoasters.com"
          },
          "tasks": [
              {"id": 5, "name": "Mark up methods with Doxygen markup", "assigned_user_id": 2},
              {"id": 6, "name": "Generate docs and review formatting", "assigned_user_id": 2},
              {"id": 7, "name": "Review docs for accuracy and completeness", "assigned_user_id": 1},
              {"id": 8, "name": "Publish to Github", "assigned_user_id": 2}
          ]
      }},
      {"project": {
          "id": 789,
          "name": "Wash the Cat",
          "description": "Mr. Fluffy is looking like Mr. Scruffy! Time for a bath!",
          "user": {
              "id": 3,
              "name": "Rachit Shukla",
              "email": "rachit@twotoasters.com"
          },
          "tasks": [
              {"id": 9, "name": "Place cat in bathtub", "assigned_user_id": 3},
              {"id": 10, "name": "Run water", "assigned_user_id": 3},
              {"id": 11, "name": "Try not to get scratched", "assigned_user_id": 3}
          ]
      }}]


This JSON collection is oriented around an array of Project models, with nested relationship structures. Let's look at the implementation of our Project class:

      @interface Project : RKObject {
        NSNumber* _projectID;
        NSString* _name;
        NSString* _description;
        User* _user;
        NSArray* _tasks;
      }

      @property (nonatomic, retain) NSNumber* projectID;
      @property (nonatomic, retain) NSString* name;
      @property (nonatomic, retain) NSString* description;
      @property (nonatomic, retain) User* user;
      @property (nonatomic, retain) NSArray* tasks;

      @end

      @implementation Project

      + (NSDictionary*)elementToPropertyMappings {
        return [NSDictionary dictionaryWithKeysAndObjects:
                @"id", @"projectID",
                @"name", @"name",
                @"description", @"description", 
                nil];
      }

      + (NSDictionary*)elementToRelationshipMappings {
        return [NSDictionary dictionaryWithKeysAndObjects:
                @"user", @"user",
                @"tasks", @"tasks",
                nil];
      }

      @end

Here we see the new invocation to elementToRelationshipMappings. If you glance back at the JSON structure, you can see that the declaration is instructing the object mapper to take the data contained in 'user' and 'tasks' sub-dictionaries, map them into objects, and assign the User and array of Task objects to the Project. When all of this has been completed, the object mapper will return the results and the complete object graph will be sent to your object loader delegate for processing.

**Example Code** - See [RKRelationshipMappingExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKRelationshipMappingExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

## Persistence with Core Data

**NOTE** - It is assumed for the purposes of this tutorial that the reader is familiar with Core Data.

Perhaps the most powerful weapon in RestKit's arsenal is the seamless integration with Apple's Core Data technology. Core Data provides a queryable, object persistence framework that is available on OS X and iOS. Building on the foundation of object mapping, RestKit enables the developer to create a persistent mirror of data contained within a remote backend system with very little code. There are a lot of moving pieces involved in providing such a high level of abstraction, so let's meet the key players before diving into the details:

* **RKManagedObjectStore** - The object store wraps the initialization and configuration of internal Core Data classes including NSManagedObjectModel, NSPersistentStoreCoordinator, and NSManagedObjectContext. The object store is also responsible for managing object contexts for each thread and managing changes between threads. In general, the object store seeks to remove as much boilerplate Core Data code as possible from the main application.
* **RKManagedObject** - The superclass of all RestKit persistent objects. RKManagedObject inherits from NSManagedObject and extends the API with a number of helpful methods. This is an RKObjectMappable class and is configured for mapping in the same way as transient RKObject instances.
* **RKManagedObjectLoader** - When Core Data support has been linked into your application, this descendant of
RKObjectLoader handles the processing of object load requests. It knows how to uniquely identify Core Data backed objects and hides the complexities of passing NSManagedObject's across threads. Also responsible for deleting objects from the local store when a DELETE is processed successfully.
* **RKManagedObjectCache** - The object cache protocol defines a single method for mapping resource paths to a collection of fetch requests for pulling local copies of objects that 'live' at a given resource path. We'll cover this in detail below.
* **RKManagedObjectSeeder** - The object seeder provides an interface for creating a SQLite database that is loaded with local copies of remote objects. This can be used to bootstrap a large local database so that no lengthy synchronization process is necessary when the app is first downloaded from the App Store. Seeding is covered in detail below as well.

It is worth noting that there is nothing special about RestKit's utilization of Core Data. The framework uses standard API's and streamlines common tasks. You can integrate RestKit into an existing Core Data backed application without much trouble. Once integrated, you can use all the familiar Core Data API's -- you don't have to stick to what RestKit exposes via RKManagedObject.

### Getting Started with Core Data

Enabling persistent object mapping is a relatively straight-forward process. It differs from transient object mapping in only a few ways:

1. libRKCoreData.a must be linked into your target
1. Apple's CoreData.framework must be linked to your target
1. A Data Model Resource must be added to your target and configured within Xcode
1. The RestKit Core Data headers must be imported via `#import <RestKit/CoreData/CoreData.h>`
1. An instance of RKManagedObjectStore must be configured and assigned to the object manager
1. Persistent models inherit from RKManagedObject rather than RKObject
1. A Primary Key property must be defined on each persistent model by implementing the `primaryKeyProperty` method
1. Implementation for properties on managed objects are generated via @dynamic rather than @synthesize

Once these configuration changes have been completed, RestKit will load & map payloads into Core Data backed classes. 

There are a couple of common gotchas and things to keep in mind when working with Core Data:

1. You can utilize a mix of persistent and transient models within the application -- even within the same JSON payload. RestKit will determine if the target object is backed by Core Data at runtime and will
return managed and unmanaged objects as appropriate.
1. RestKit expects that each instance of an object be uniquely identifiable via a single primary key that is present in the payload. This allows the mapper to differentiate between new, updated and removed objects.
1. When configuring your Data Model resource, care must be taken to ensure that the destination class is set to your desired model class. It defaults to NSManagedObject and must be updated appropriately. Failure to do this will result in exceptions from within the mapper when RestKit methods are invoked on an instance of NSManagedObject.
1. Use of threading in Core Data requires some special care. You cannot safely pass managed object instances across thread boundaries. They must be serialized to NSManagedObjectID and handed off between threads and then refetched from the managed object context. RKObjectLoader performs JSON parsing and object mapping on background threads and handles the thread jumping & object fetching for you. But you must take care if you introduce threading (including the use of performSelector:withDelay:) in your application code.
1. Apple recommends utilizing one managed object context instance per thread. When you retrieve a managed object context from RKManagedObjectStore, a new instance is created and stored onto thread local storage if the calling thread is not the main thread. You don't need to worry about managing the life-cycle of the managed object contexts or merging changes -- the object store observes these thread-local contexts and handles merging changes back into the main object context.
1. RestKit makes some blanket assumptions about how you are using Core Data that may not be appropriate for your application. This includes the merge policy used on object contexts, the options provided during initialization of the persistent store coordinator, etc. If you need more flexibility than is provided out of the box, reach out to the team and we'll help loosen up these assumptions.
1. RestKit assumes that you use an entity with the same name as your model class in the data model.
1. There is not currently any framework level help for working with store migrations.

For help getting started with Core Data, please refer to the RKTwitter and RKTwitterCoreData projects in the Examples/ directory of the RestKit distribution. These projects provide identical implementations of a simple modeling of the Twitter timeline except that one is persistently backed by Core Data.

### Working with Core Data

Now that we have a grounding in the basic requirements for adding Core Data to a RestKit project, let's take a look at some code to help us make things happen. All the code in this section is contained in the Examples/RKCoreDataExamples project for reference. Please pop the project open and follow along as we work through the examples.

First, we need to actually get RestKit and Core Data initialized. Open RKCDAppDelegate.m and note the following snippets of code:
    
    // Import RestKit's Core Data support
    #import <RestKit/CoreData/CoreData.h>
    
    RKObjectManager* manager = [RKObjectManager objectManagerWithBaseURL:@"http://restkit.org"];
    manager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKCoreDataExamples.sqlite"];

What we have done here is instantiated an instance of the object manager and an instance of the managed object store. Within the internals of RKManagedObject, an NSManagedObjectModel and NSPersistentStoreCoordinator has been created for you. A persistent store file is created or reopened for you within the application's documents directory and is configured to use SQLite as the backing technology. From here you have a working Core Data environment ready to go.

Now let's take a look at the rather anemic model in Examples/RKCatalog/Examples/RKCoreDataExample/RKCoreDataExample.m:

    @implementation Article
    
      + (NSDictionary*)elementToPropertyMappings {
        return [NSDictionary dictionaryWithKeysAndObjects:
                @"id", @"articleID",
                @"title", @"title",
                @"body", @"body",
                nil];
      }
    
      + (NSString*)primaryKeyProperty {
        return @"articleID";
      }
    
    @end

Here we see the familiar elementToPropertyMappings method from RKObjectMappable. The only thing new here is the implementation of a method indicating the primary key. This allows the object mapper to know that when working with instances of Article, it should consult the `articleID` property to obtain the primary key value for the instance. This allows RestKit to update the properties for this object no matter what resource path it is loaded from.

Now let's explore some of the API's exposed via RKManagedObject. Loading all objects of a given type is trivial:

    - (void)loadAllObjects {
        NSArray* objects = [Article allObjects];
        NSLog(@"We loaded %d objects", [objects count]);
    }

Here we are retrieving all the objects for a given class from Core Data. This wraps the initialization, configuration and execution of a fetch request targeting the entity for our class. We can also configure our own fetch requests or utilize a number of helper methods to quickly perform common tasks:

    - (void)funWithFetchRequests {
        // Grab a fetch request configured to target the Article entity
        NSFetchRequest* fetchRequest = [Article fetchRequest];
        NSLog(@"My fetch request is: %@", fetchRequest);

        // Configure a fetch request to sort the results by title
        NSFetchRequest* sortedRequest = [Article fetchRequest];
        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [sortedRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        NSArray* sortedObjects = [Article objectsWithFetchRequest:fetchRequest];
        NSLog(@"Here are the objects sorted: %@", sortedObjects);

        // Fetch an object by primary key
        Article* firstArticle = [Article objectWithPrimaryKeyValue:[NSNumber numberWithInt:1]];
        NSLog(@"This is the Article with ID 1: %@", firstArticle);

        // Find Articles where the body contains the word 'something' case insensitively
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"body CONTAINS[c] %@", @"something"];
        NSArray* matches = [Article objectsWithPredicate:predicate];
        NSLog(@"Found the following Articles that match: %@", matches);
    }

All of these methods are defined on RKManagedObject and provide short-cuts for features provided directly by Core Data. You can certainly configure your own fetch request entirely:

    - (NSFetchRequest*)constructMyOwnFetchRequest {
        NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
      	NSEntityDescription *entity = [Article entity]; // The entity is available via RKManagedObject helper method...
      	[fetchRequest setEntity:entity];
      	return fetchRequest;
    }

These Core Data helpers methods are used to drive a simple table view in the RKCoreDataExample in RKCatalog.

**Example Code** - See [RKCoreDataExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKCoreDataExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

### Automagic Relationship Management

One of nicest benefits of using Core Data with RestKit is that you wind up with a nicely hydrated object graph that let's you traverse object relationships naturally. Relationship population is handled through the use of the `elementToRelationshipMappings` method we introduced in the previous section on modeling relationships. Recall that `elementToRelationshipMappings` instructs
the mapper to look for associated objects nested as a sub-dictionary within the JSON payload. But this can present a problem for a Core Data backed app -- if you do not return all the relationships you have modeled within your payload, the graph can become stale and out of sync with the server. And not to mention that returning all relationships is often incorrect from an API design or performance perspective. So what are we to do?

RestKit solves this problem by introducing a new mapper configuration directive specific to Core Data objects: `relationshipToPrimaryKeyPropertyMappings`. The relationship to primary key mappings definition instructs the mapper to connect a Core Data relationship by using the value stored in another property to lookup the target object. This is easily understood by returning to the Task List data model we explored earlier. Recall that the JSON for an individual task looked like this:

    {"id": 5, "name": "Place cat in bathtub", "assigned_user_id": 3}

Note the `assigned_user_id` element in the payload -- this is the primary key value for the User object that the Task has been assigned to. Let's look at the code:
    
    @interface Task : RKManagedObject {
    }

    @property (nonatomic, retain) NSNumber* taskID;
    @property (nonatomic, retain) NSString* name;
    @property (nonatomic, retain) NSNumber* assignedUserID;
    @property (nonatomic, retain) User* assignedUser;

    @end

    @implementation Task

    + (NSDictionary*)elementToPropertyMappings {
      return [NSDictionary dictionaryWithKeysAndObjects:
              @"id", @"taskID",
              @"name", @"name",
              @"assigned_user_id", @"assignedUserID", 
              nil];
    }

    + (NSDictionary*)relationshipToPrimaryKeyPropertyMappings {
      return [NSDictionary dictionaryWithObject:@"assignedUserID" forKey:@"assignedUser"];
    }

    @end

Note the definition of `relationshipToPrimaryKeyPropertyMappings` -- we have informed the mapper that the `assignedUserID` property contains the value of the primary key for the `assignedUser` relationship. When the mapper sees this, it will reflect on the relationship to determine it's type (in this case, a User) and assign `object.user = User.findByPrimaryKeyValue(object.assignedUserID)`. The target object must exist within the local data store or the relationship will be set to nil.

**Example Code** - See [RKRelationshipMappingExample](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog/Examples/RKRelationshipMappingExample) in [RKCatalog](https://github.com/twotoasters/RestKit/blob/master/Examples/RKCatalog)

### Going Offline: Using the Object Cache

A primary use case for RestKit's Core Data integration is to provide offline access to remote content. In fact it was from this need that RestKit was born -- when development began on GateGuru (an excellent, essential app for the iPhone wielding airline traveler) a primary requirement was the ability to access information at 30,000 feet. What we really wanted was a common programming interface that would work regardless of online or offline status -- if we have network connectivity, ping the remote server and give me the results, otherwise hit the cache and give me the most recent local results available. Because we designed our web services RESTfully, we could easily construct URL's that would access the data for a particular airport, terminal, etc. We realized that we could reach our API nirvana by utilizing the resource path we load remote objects for as a key into our persistent store. This is precisely what the `RKManagedObjectCache` protocol allows you to do:

    /**
     * Must return an array containing NSFetchRequests for use in retrieving locally
     * cached objects associated with a given request resourcePath.
     */
    - (NSArray*)fetchRequestsForResourcePath:(NSString*)resourcePath;

To utilize the object cache, you need to provide an implementation of `RKManagedObjectCache` and assign it to the managed object store. The implementation of the method needs to parse the resource path and construct one or more fetch requests that can be used to retrieve objects that 'live' at that resource path. For example, in an app like GateGuru that has a collection of airport objects, your implementation might look something like this:
  
    @interface MyObjectCache : NSObject <RKManagedObjectCache> {
    
    }
  
    @end

    @implementation MyObjectCache
  
    - (NSArray*)fetchRequestsForResourcePath:(NSString*)resourcePath {
      if ([resourcePath isEqualToString:@"/airports"]) {
        NSFetchRequest* fetchRequest = [Airport fetchRequest]; // A fetch request with an entity set, but nothing else fetches all objects
        return [NSArray arrayWithObject:fetchRequest];
      }
    
      return nil;
    }
  
    @end
  
    MyObjectCache* cache = [[MyObjectCache alloc] init];
    [RKObjectManager sharedManager].objectStore.managedObjectCache = cache;
    [cache release];

An array of fetch requests is returned to support the case where your remote endpoint returns objects of more than one type -- Core Data fetch requests can only target a single entity. Once you have provided an implementation and covered all your resource paths, you can retrieve the locally cached objects for a resource path from the object store:

    NSArray* objects = [[RKObjectManager sharedManager].objectStore objectsForResourcePath:@"/airports"];
    
The object cache is used extensively within the Three20 integration layer we will discuss in more detail below. In summary, if you are using Three20 in your application RestKit ships with an object cache aware implementation of TTModel that can be used to populate a table with data from an object loader or the cache.

### Handling Remote Object Deletion

In addition to providing the basis for offline support, the object cache provides another important feature: intelligent handling of server-side object deletion. If you have provided an implementation of the object cache in your application, RestKit will prune objects that currently exist in the local store but have disappeared from the remote payload for a cached resource path. If your application has many resource paths that can load the same objects, it is important that you handle each path and return fetch requests covering all the objects.

If you are not using the object cache, you must manually handle object server-side object deletion by some other means.

### Database Seeding

In a Core Data backed application, it can be highly desirable to ship your application to the App Store with content already available in the local store. RestKit includes a simple object seeding implementation for this purpose via the `RKObjectSeeder` class. `RKObjectSeeder` provides an interface for opening one or more JSON files stored in the local bundle, processing them with the mapper, and then outputting instructions for how to obtain the seed database for use in your application. The seeding process typically looks like this:

1. Generate a dump file for each of your persistent object types from your backend system in JSON format.
1. Duplicate your existing application target and name the new target "Generate Seed Database".
1. View the Build Settings for your target and find the GCC - Preprocessing section.
1. In the section named "Preprocessor Macros", add new preprocessor macro: `RESTKIT_GENERATE_SEED_DB`. This value will be defined when we build and run the seeder target.
1. Add your JSON dump files to the "Generate Seed Database" target and ensure they are copied into the application bundle.
1. Update your application delegate to check for `RESTKIT_GENERATE_SEED_DB` and instantiate an instance of `RKObjectSeeder`.
1. Initialize an instance of `RKObjectSeeder` with your fully configured instance of `RKObjectManager`
1. Invoke the appropriate methods on the `RKObjectSeeder` instance for each of your JSON dump files.
1. When finished, invoke the `finalizeSeedingAndExit` method on the `RKObjectSeeder` instance.

The seeder is designed to be run in the Simulator on your Mac. When you invoke `finalizeSeedingAndExit`, the library will log details out to the console about where you can obtain the SQLite seed database. Once you have obtained a copy of the seed database, you add it to your project as a resource to copy into the app bundle. Once you have added the seed database to your application, you simply modify your initialization of RKManagedObjectStore to indicate that you have a seed database to start with rather than a blank slate.

Let's take a look at some example code, taken from the RKTwitterCoreData example, that highlights how to work with the seeder:

    // Database seeding is configured as a copied target of the main application. There are only two differences
    // between the main application target and the 'Generate Seed Database' target:
    //  1) RESTKIT_GENERATE_SEED_DB is defined in the 'Preprocessor Macros' section of the build setting for the target
    //      This is what triggers the conditional compilation to cause the seed database to be built
    //  2) Source JSON files are added to the 'Generate Seed Database' target to be copied into the bundle. This is required
    //      so that the object seeder can find the files when run in the simulator.
    #ifdef RESTKIT_GENERATE_SEED_DB    
        RKManagedObjectSeeder* seeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];

        // Seed the database with instances of RKTStatus from a snapshot of the RestKit Twitter timeline
        [seeder seedObjectsFromFile:@"restkit.json" toClass:[RKTStatus class] keyPath:nil];

        // Seed the database with RKTUser objects. The class will be inferred via element registration
        [seeder seedObjectsFromFiles:@"users.json", nil];

        // Finalize the seeding operation and output a helpful informational message
        [seeder finalizeSeedingAndExit];

        // NOTE: If all of your mapped objects use element -> class registration, you can perform seeding in one line of code:
        // [RKManagedObjectSeeder generateSeedDatabaseWithObjectManager:objectManager fromFiles:@"users.json", nil];
    #endif

        // Initialize object store
        objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKTwitterData.sqlite" usingSeedDatabaseName:RKDefaultSeedDatabaseFileName managedObjectModel:nil];

## Integration Layers

It is briefly worth noting that RestKit ships with some integration layers to help developers work with some complementary technology. As of this writing, there are two such integration points available:

1. RKRailsRouter - A Router implementation aware of Ruby on Rails idioms
2. RKRequestTTModel - An implementation of the TTModel protocol for Three20 that allows RestKit object loaders to drive Three20 tables

### Ruby on Rails Support

The RKRailsRouter inherits from the RKDynamicRouter introduced in the first tutorial. The Rails router alters the default routing behavior in a couple of ways:

1. Allows for registration of server side model names for the purpose of nesting attributes before sending requests
2. Prevents any parameter data from being encoded into the request body for DELETE requests

The attribute nesting is understood simply with an example. Imagine that we have a server-side model called 'Article', with two attributes 'title' and 'body'. We would configure the Rails router like so:

    RKRailsRouter* router = [[RKRailsRouter alloc] init];
    [router setModelName:@"article" forClass:[Article class]];
    [router routeClass:[Article class] toResourcePath:@"/articles/(articleID)"];
    [router routeClass:[Article class] toResourcePath:@"/articles" forMethod:RKRequestMethodPOST];
    
    Article* article = [Article object];
    article.title = @"This is the title";
    article.body = @"This is the body";
    
    [[RKObjectManager sharedManager] postObject:article delegate:self];
    
When the object is serialized for the POST request, RestKit will nest the attributes into a hash like so:

    article[title]=This is the title&
    article[body]=This is the body

This matches the format Rail's controllers expect attributes to be delivered in. The changes to the DELETE payload are self-explanatory -- Rails simply expects the params to be empty during DELETE requests and the Rails router abides.
    
### Three20 Support

At Two Toasters, the vast majority of our iOS applications are built on top of two frameworks: RestKit and Three20. We have found that Three20 greatly simplifies and streamlines a number of common patterns in our iOS applications (such as the support for URL based dispatch) and provides a rich library of UI components and helpers that make us happier, more productive programmers. And RestKit obviously makes working with data so much more pleasant. So it should come as little surprise that there integration points available between the two frameworks.

Integration between RestKit and Three20 takes the form of an implementation of the TTModel protocol. TTModel defines an interface for abstract data models to inform the Three20 user interface components of their status and provide them with data. TTModel is the basis for all Three20 table view controllers as well as a number of other components. RestKit ships with an optional `libRestKitThree20` target that provides an interface for driving Three20 table views off of a RestKit object loader via the `RKRequestTTModel` class. `RKRequestTTModel` allows us to handle all the modeling, parsing, and object mapping with RestKit and then plug our data model directly into Three20 for presentation. `RKRequestTTModel` also provides transparent offline support and periodic data refresh in our user interfaces. When you have used Core Data to back your data model and utilize `RKRequestTTModel` in your controllers, RestKit will automatically pull any objects from the cache that live at the resource path you are loading in the event you are offline. `RKRequestTTModel` can also be configured to hit the network only after a certain amount of time by configuring the `refreshRate` property.

In addition to `RKRequestTTModel`, a child class `RKRequestFilterableTTModel` is provided as well. `RKRequestFilterableTTModel` provides support for sorting and searching a collection of loaded objects and can be useful for providing client side filtering operations.

## Connecting the Dots

The Three20 support lies at the top of a large pyramid of technology and relies on nearly every part of the framework we have discussed so far. The amount of code necessary to see the full benefits of the framework at this level is daunting to include in the body of this text. A full-featured RestKit application leveraging Core Data, Ruby on Rails, and Three20 is available in the Examples/RKDiscussionBoardExample directory. Please take a close look at the Discussion Board example and join the RestKit mailing list. The community is quite active and more than happy to help new users.

## Conclusion

We hope that you have found learning about RestKit fun and rewarding. At this point we have reviewed the vast majority of framework and you should be prepared to utilize RestKit in your next RESTful iOS application. The framework is maturing quickly and iterating rapidly, so please be sure to join the mailing list or follow @RestKit on Twitter to keep up with the latest developments. Happy coding!

## Learning More
* RestKit: [http://restkit.org]()
* Github: [https://github.com/twotoasters/RestKit]()
* API Docs: [http://restkit.org/api/]()
* Google Group: [http://groups.google.com/group/restkit]()
* Brought to you by Two Toasters: [http://twotoasters.com/]()
