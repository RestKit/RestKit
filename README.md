Introduction
=========================

RestKit is a Cocoa framework for interacting with RESTful web services in Objective C on iOS and Mac OS X. It provides a set of primitives for interacting with web services wrapping GET, POST, PUT and DELETE HTTP verbs behind a clean, simple interface. RestKit also provides a system for modeling remote resources by mapping them from JSON (or XML) payloads back into local domain objects. Object mapping functions with normal NSObject derived classes with properties. There is also an object mapping implementation included that provides a Core Data backed store for persisting objects loaded from the web.

RestKit was first publicly introduced in April of 2010.

To get started with installation, skip down the document below the Design & Dependencies section.

Design
-------------------------

RestKit is composed of three main components: **Network**, **Object Mapping**, and **Core Data**. Each layer provides a higher level of abstraction around the problem of accessing web services and representing the data returned as an object. The primary goal of RestKit is to allow the application programmer to think more in terms of their application's data model and less about the details of fetching, parsing, and representing resources. Functionally, each piece provides...

1. **Network** - The network layer provides a request/response abstraction on top of NSURLConnection. The main interface for the end developer is the *RKClient*, which provides an interface for sending GET, POST, PUT, and DELETE requests asynchronously. This wraps the construction and dispatch of *RKRequest* and *RKResponse* objects, that provide a nice interface for working with HTTP requests. Sending parameters with your request is as easy as providing an NSDictionary of key/value pairs. File uploading support from NSData and files is supported through the use of an *RKParams* object, which serializes into a multipart form representation suitable for submission to a remote web server for processing. SSL & HTTP AUTH is fully supported for requests. *RKResponse* objects provide access to the string of JSON parsed versions of the response body in one line of code. There are also a number of helpful method for inspecting the request and response such as isXHTML, isJSON, isRedirect, isOK, etc.
1. **Object Mapping** - The object mapping layer provides a simple API for turning remote JSON/XML responses into local domain objects declaratively. Rather than working directly with *RKClient*, the developer works with *RKObjectManager*. *RKObjectManager* provides support for loading a remote resource path (see below for discussion) and calling back a delegate with object representations of the data loaded. Remote payloads are parsed to an NSDictionary representation and are then mapped to local objects using Key-Value Coding. Any KVC compliant class can be targeted for object mapping. RestKit also provides support for serializing local objects back into a wire format for submission back to your remote backend system. Local domain objects can be serialized to JSON or URL Form Encoded string representations for transport. To simplify the generation of URL's that identify remote resources, RestKit ships with an object routing implementation that can
generate an appropriate URL based on the object and HTTP verb being utilized. Object mapping is a deep topic and is explored thoroughly in the [Object Mapping Design Document].
1. **Core Data** - The Core Data layer provides additional support on top of the object mapper for mapping from remote resources to persist local objects. This is useful for providing offline support, holding on to transient data, and speeding up user interfaces by avoiding expensive trips to the web server. The Core Data support requires that you initialize an instance of *RKManagedObjectStore* and assign it to the *RKObjectManager*. RestKit includes a library of extensions to NSManagedObject that provide an Active Record pattern on top of the Core Data primitives. See the Examples/ subdirectory for examples of how to get this running. The Core Data support also provides *RKManagedObjectSeeder*, a tool for creating a local "seed database" to bootstrap an object model from local JSON files. This allows you to ship an app to the store that already has data pre-loaded and then synchronize with the cloud to keep your clients up to date.

### Base URL and Resource Paths

RestKit utilizes the concepts of the Base URL and resource paths throughout the library. Basically the base URL is a prefix URL that all requests will be sent to. This prevents you from spreading server name details across the code base and repeatedly constructing URL fragments. The *RKClient* and *RKObjectManager* are both initialized with a base URL initially. All other operations dispatched through these objects work of a resource path, which is basically just a URL path fragment that is appended to the base URL before constructing the request. This allows you to switch between development, staging, and production servers very easily and reduces redundancy.

Note that you can send *RKRequest* objects to arbitrary URL's by constructing them yourself.

Dependencies
-------------------------

RestKit provides JSON parser implementations using JSONKit, SBJSON & YAJL. The recommended parser is JSONKit (as it is known to be the fastest JSON implementation available), but you may choose whatever parser you like and they can be changed at runtime.

The sources for JSONKit, SBJSON and YAJL are included in the Vendor/ subdirectory. The headers are copied into the RestKit headers path at build time and can be imported into your project via:

    #import <RestKit/Support/JSON/JSONKit/JSONKit.h>
    #import <RestKit/Support/JSON/SBJSON/JSON.h>
    #import <RestKit/Support/JSON/YAJL/YAJL.h>

Currently bundled version of these dependencies are:

* **JSONKit** - 1.4
* **YAJLIOS** - 0.2.21
* **SBJSON** - 2.3.1

If you currently link against or include JSONKit, SBJSON or YAJL in your project, you can disable the RKJSONParser targets and compile the appropriate RKJSONParser sources directly into your application.

XML parsing is supported via a custom, bundled parser written against LibXML.

Additional parsing backend support is expected in future versions.

Documentation & Example Code
-------------------------

Documentation and example code is being added as quickly as possible. Please check the Docs/ and Examples/ subdirectories to see what's available. The [RestKit Google Group](http://groups.google.com/group/restkit) is an invaluable resource for getting help working with the library.

RestKit has API documentation available on the web. You can access the documentation in several ways:

1. Online in your web browser. Visit http://restkit.org/api/
1. Directly within Xcode. Visit your Xcode Preferences and view the Documentation tab. Click + and add the RestKit feed: feed://restkit.org/api/org.restkit.RestKit.atom
1. Generate the documentation directly from the project source code. Run `rake docs` to generate and `rake docs:install` to install into Xcode

Installation
=========================

Quick Start (aka TL;DR)
-----------

1. Add Git submodule to your project: `git submodule add git://github.com/RestKit/RestKit.git RestKit`
1. Add cross-project reference by dragging **RestKit.xcodeproj** to your project
1. Open build settings editor for your project
1. Add **Other Linker Flags** for `-ObjC`
1. Add **Header Search Path** for `$(SOURCE_ROOT)/RestKit/Build`
1. Open target settings editor for the target you want to link RestKit into
1. Add direct dependency on the **RestKit** aggregate target
1. Link against required frameworks:
    1. **CFNetwork.framework**
    1. **CoreData.framework**
    1. **MobileCoreServices.framework** on iOS or **CoreServices.framework** on OS X
    1. **SystemConfiguration.framework**
    1. **libxml2.dylib**
1. Link against RestKit static library products:
    1. **libRestKitSupport.a**
    1. **libRestKitObjectMapping.a**
    1. **libRestKitNetwork.a**
    1. A JSON parser implementation (either **libRestKitJSONParserJSONKit.a**, **libRestKitJSONParserYAJL.a**, or **libRestKitJSONParserSBJSON.a**). We recommend JSONKit.
1. Import the RestKit headers via `#import <RestKit/RestKit.h>`
1. Build the project to verify installation is successful.

Visual Install Guide
-------------------------

An step-by-step visual install guide for Xcode 4.x is available on the RestKit Wiki: https://github.com/RestKit/RestKit/wiki/Installing-RestKit-in-Xcode-4.x

Contributing
-------------------------

Forks, patches and other feedback are always welcome. 

A Google Group for development and usage of library is available at: [http://groups.google.com/group/restkit](http://groups.google.com/group/restkit)

Follow RestKit on Twitter:[http://twitter.com/restkit](http://twitter.com/restkit)

Credits
-------------------------

RestKit is brought to you by [Blake Watters](http://twitter.com/blakewatters) and the RestKit Team.

Support is provided by the following organizations:

* [GateGuru](http://www.gateguruapp.com/)
* [Two Toasters](http://www.twotoasters.com/)

[Object Mapping Design Document]: https://github.com/RestKit/RestKit/blob/master/Docs/Object%20Mapping.md
