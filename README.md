Introduction
=========================

RestKit is a library for interacting with Restful web services in Objective C. It provides a set of primitives for interacting with web services wrapping GET, POST, PUT and DELETE HTTP verbs behind a clean, simple interface. RestKit also provides a system for modeling remote resources by mapping them from JSON payloads back into domain objects. Model mapping functions with normal NSObject derived classes with properties. There is also a model mapping implementation included that provides a Core Data backed store for persisting objects loaded from the web.

http://twotoasters.com/index.php/2010/04/06/introducing-restkit/

Dependencies
-------------------------

RestKit currently utilizes json-framework for parsing JSON payloads. The source code is directly included in the distribution.
If you currently link against or include json-framework in your project, please remove it and utilize the bundled version (currently 2.2.3).

Additional parsing backend support is expected in future versions.

Installation
-------------------------

To add RestKit to your project (you're using git, right?):

* git submodule add git://github.com/twotoasters/RestKit.git RestKit

Open RestKit.xcodeproj and drag the RestKit project file into your XCode project.

Next add RestKit as a direct dependency to your target.

Add 'RestKit' to your target's header search paths.

Add libRestKit.a to your target (checkbox)

Be sure to enable the -ObjC in your Target settings under "Build" > "Other Linker Flags"

Contributing
-------------------------

Forks, patches and other feedback are always welcome. 

A Google Group for development and usage of library is available at: [http://groups.google.com/group/restkit](http://groups.google.com/group/restkit)

### RestKit is brought to you by [Two Toasters](http://www.twotoasters.com/). ###
