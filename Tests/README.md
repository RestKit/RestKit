RestKit Test Environment
========================

RestKit ships with a testing infrastructure built around OCUnit and a Ruby testing server environment built on Sinatra. To be able to run the tests, you need to do a little bit of setup. These instructions are valid for **Xcode version 4.5 and higher**.

1. Install the Xcode **Command Line Tools** by selecting the **Xcode** > **Preferences…** menu and then navigating to the **Downloads** tab, then clicking the **Install** button next to the appropriate entry in the table.
1. After installation completes, ensure your command line Xcode installation is configured by executing `xcode-select -print-path`. If no path is returned, configure xcode-select by executing `xcode-select -switch /Applications/Xcode.app/Contents/Developer`.
1. Check out the Git submodules: `git submodule update --init --recursive`
1. Ensure that you have **Ruby 2.0.0** available. We recommend installation via [rbenv](https://github.com/sstephenson/rbenv), [RVM](https://rvm.io/) or [Homebrew](http://brew.sh/).
1. Install the Ruby Bundler Gem (if necessary): `gem install bundler`
1. Install the other required Gems via Bundler: `bundle`
1. Install the required CocoaPods: `pod install`
1. Start the Test server: `rake server`
1. Ensure that you have opened **RestKit.xcworkspace** rather than the project file. The tests leverage CocoaPods for managing dependencies, so you must execute tests from the Workspace.
1. Build and execute the tests within Xcode via the **Product** > **Test** menu or on the command line via `rake`.

If the project builds the RestKitTests target correctly and executes the suite, then you are all set. If there are any issues, you may need to reach out to us via a Github issue for help debugging.

Running Tests
-------------

### Within Xcode

By default, all tests will be executed when your run the **Test** build action. You can selectively
enable/disable which tests are run by holding down the Option Key when selecting **Product** > **Test**
(or type Apple+Option+U).

### On the Command Line

RestKit includes full support for executing the test suite via the commandline via the excellent [Xcoder](https://github.com/rayh/xcoder) gem. The suite can be run in its entirety or as individual pieces targetting subsets of the suite. Test execution is performed via the `rake` tool. A list of the available test tasks as of this writing (obtained via `rake -T test`) follows:

	rake test                  # Run all the RestKit tests
	rake test:all              # Run all tests for iOS and OS X
	rake test:logic            # Run the unit tests for iOS and OS X
	rake test:logic:ios        # Run the logic tests for iOS
	rake test:logic:osx        # Run the logic tests for OS X

Rake is also used for a number of other automation tasks in the project. Consult the full list of tasks via `rake -T` for more info.

Test Server
-------------

RestKit includes a [Sinatra](http://www.sinatrarb.com/) powered test server that is required to exercise the majority of the HTTP specific functionality within the library. Execution of the test server is handled via a rich library of Rake tasks provided by the [RestKit Gem](https://github.com/RestKit/RestKit-Gem).

The server can be run interactively or daemonized into a background process. Tasks are provided for stopping, starting, restarting, tailing the logs of a backgrounded process, and for automatically starting and stopping the server via Rake task dependencies. A list of the available server tasks as of this writing (as obtained via `rake -T server`) follows:

	rake server                       # Run the Test server in the foreground
	rake server:abort_unless_running  # Abort the task chain unless the Test server is running
	rake server:autostart             # Starts the server if there is not already an instance running
	rake server:autostop              # Stops the server if executed via autostart
	rake server:logs                  # Dumps the last 25 lines from the Test server logs
	rake server:logs:tail             # Tails the Test server logs
	rake server:restart               # Restart the Test server daemon
	rake server:start                 # Start the Test server daemon
	rake server:status                # Check the status of the Test server daemon
	rake server:stop                  # Stop the Test server daemon
	
The tasks are reusable via the RestKit gem and can be used to provide a test server for applications using RestKit as well. Details about configuring the RestKit gem to quickly build an application specific test server are available on the [RestKit Gem Github Page](https://github.com/RestKit/RestKit-Gem). An example application leveraging the test server is provided in the [RKGithub](https://github.com/RestKit/RKGithub) application.

Writing Tests
-------------

RestKit tests are divided into two portions. There are pure unit tests, which only require the test harness to be
configured and there are integration tests that test the full request/response life-cycle. In general, testing RestKit is very straight-forward. There are only a few items to keep in mind:

1. Tests are implemented in Objective-C and run inside the Simulator or on the Device.
1. Test files live in sub-directories under Tests/ appropriate to the layer the code under test belongs to
1. Tests begin with "test" and should be camel-cased descriptive. i.e. testShouldConsiderA200ResponseSuccessful
1. Expectations are provided using [Expecta](https://github.com/specta/expecta) and [OCHamcrest](https://github.com/hamcrest/OCHamcrest). Expectations are generally of th form:
        expect(someObject).to.equal(@"some value"); // Expecta
        assertThat([someObject someMethod], is(equalTo(@"some value"))); // OCHamcrest
        
    There is a corresponding `notTo` and `isNot` method available as well.
1. The RKTestEnvironment.h header includes a number of helpers for initializing and configuring a clean testing environment.
1. OCMock is available for mock objects support. See [http://ocmock.org/](http://ocmock.org/) for details.
1. RestKit is available for 32bit (iOS) and 64bit (OS X) platforms. This introduces some complexity when working with integer data types as NSInteger
and NSUInteger are int's on 32bit and long's on 64bit. Cocoa and OC Hamcrest provide helper methods for dealing with these differences. Rather than using the **Int**
flavor of methods (i.e. `[NSNumber numberWithInt:3]`) use the **Integer** flavor (i.e. `[NSNumber numberWithInteger:]`). This will account for the type differences without
generating warnings or requiring casting.

### RestKit Testing Classes

RestKit includes a number of testing specific classes as part of the library that are used within the test suite and are also available for testing applications leveraging RestKit. This functionality is covered in detail in the [Unit Testing with RestKit](https://github.com/RestKit/RestKit/wiki/Unit-Testing-with-RestKit) article on the Github site.

### Writing Integration Tests

RestKit ships with a Sinatra powered specs server for testing portions of the codebase that require interaction
with a web service. Sinatra is a simple Ruby DSL for defining web server. See the [Sinatra homepage](http://www.sinatrarb.com/) for more details.

The Test server is built as a modular Sinatra application in the Tests/Server subdirectory of the RestKit distribution. When you are adding new integration test coverage to the library, you may need to add new routes to Sinatra to serve your needs. By convention, these are namespaced by functional unit for simplicity. For example, if we are adding a new
caching component to the application and want to test the functionality, we might add a new route to the Test server at Tests/Server/server.rb like so:

        get '/author.json' do
          content_type 'application/json'
          { :author => { :name => "Blake Watters", :organization => "RestKit" } }.to_json
        end

You now have a functional server-side component to work with. Consult the Sinatra documentation for example on setting
response headers, MIME types, etc. It's all very simple and low ceremony.

You can now switch to the RestKit sources and look in the Tests directory. To test our new '/author.json' endpoint, we could create a new test and import "RKTestEnvironment.h" or find an existing test case that matches the functionality we are testing. In this case, we are doing some basic testing of object mapping over HTTP, so we might add the test to 'RKObjectRequestOperationTest.m'. Once we have found a proper home for the test, we can then implement the appropriate code. 

RestKit was designed with testability in mind, so in this we would only need to leverage the `RKObjectRequestOperation` and some appropriate matchers. Let's take a look at an example of how to write a basic test:

     - (void)testShouldFailAuthenticationWithInvalidCredentialsForHTTPAuthBasic
     {
        RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKAuthor class]];
        [mapping addAttributeMappingsFromArray:@[ @"name", @"organization" ]];
        NSURL *URL = [NSURL URLWithString:@"/author.json" relativeToURL:[RKTestFactory baseURL]];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/author.json" keyPath:@"author" statusCodes:[NSIndexSet indexSetWithIndex:200]];        
        RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
        [operation start];
        [operation waitUntilFinished];
        expect(operation.error).to.beNil();
        expect(operation.mappingResult).to.haveCountOf(1);
        RKAuthor *author = [operation.mappingResult firstObject];
        expect(author.name).to.equal(@"Blake Watters");
        expect(author.organization).to.equal(@"RestKit");
      }

That's really all there is to it. Consult the existing test code in Tests/ for reference.


Continuous Integration
-------------

**Note:** RestKit currently uses [Travis CI](https://travis-ci.org/RestKit/RestKit)

The RestKit team keeps the master, development, and active branches of RestKit under the watchful eye of the [Jenkins Continuous Integration Server](http://jenkins-ci.org/). There is a fair amount of complexity involved in getting iOS projects running under Jenkins, so to make things as easy as possible all Jenkins configuration has been collected into a single script within the source code. Currently use of the Jenkins build **requires** the use of RVM for managing the Ruby environment.

To configure Jenkins to build RestKit, do the following:

1. Ensure the RestKit test suite executes cleanly on the CI host using the above reference.
1. Install Jenkins (again, we recommend [Homebrew](https://github.com/Homebrew/homebrew)): `brew install jenkins`
2. Install Jenkins as a system service. Instructions are printed post installation via Homebrew
3. Configure your CI user's OS X account to automatically manage the RVM environment. Create an `~/.rvmrc` file and populate it with the following:
```bash
export rvm_install_on_use_flag=1
export rvm_gemset_create_on_use_flag=1
export rvm_trust_rvmrcs_flag=1
export rvm_always_trust_rvmrc_flag=1
```
4. Install the Git plugin for Jenkins and configure it for the fork you are tracking.
5. Create a Jenkins project for building RestKit within the Jenkins UI.
6. Add an **Execute shell** build step to the Jenkins project with a Command value of: `bash -x ./Tests/cibuild`
7. Save the project and tap the **Build Now** button to force Jenkins to build the project.

When the RestKit build is invoked, the cibuild script will leverage Bundler to bundle all the required Ruby gems and then start up an instance of the test server on port 4567, execute all the tests, then shut down the server.
