RestKit Spec Environment
========================

RestKit ships with a testing infrastructure built around UISpec and
an associated Ruby Gem called UISpecRunner. To be able to run the
tests, you need to do a little bit of setup:

1. Install the Ruby Bundler Gem (if necessary): `gem install bundler`
1. Install the other required Gems via Bundler: `bundle`
1. Start the spec server: `rake uispec:server`
1. Verify the configuration by running the specs: `uispec -v`

If the project builds the Specs target correctly and executes the suite, then
you are all set. If there are any issues, you may need to reach out to the mailing
list for help debugging.

Once your spec environment has been configured and set up, you can run the entire suite
by executing `rake` or `uispec`.

Running Specs
-------------

UISpecRunner is both a library and a general purpose CLI runner. The library works
by plugging into the application and executing specs as configured by some environment
variables.

You can use the `uispec` executable to target and run specific specs or grouping of specs
(i.e. unit, functional, integration):

* Run all specs: `bundle exec uispec`
* Run a specific spec class: `bundle exec uispec -s RKClientSpec`
* Run a specific spec example: `bundle exec uispec -s RKClientSpec -e itShouldDetectNetworkStatusWithAHostname`
* Run all specs conforming to a protocol: `bundle exec uispec -p UISpecUnit`

Common spec groupings (i.e. Units and Integration) are configured for execution via the Rakefile. Execute
`rake -T` for a full listing of the pre-configured spec groups available.

Writing Specs
-------------

RestKit specs are divided into two portions. There are pure unit tests, which only require the test harness to be
configured and there are integration tests that test the full request/response life-cycle. In general, testing RestKit is very straight-forward. There are only a few items to keep in mind:

1. Specs are implemented in Objective-C and run inside the Simulator or on the Device.
1. Spec files live in sub-directories under Specs/ appropriate to the layer the code under test belongs to
1. UISpec executes Specs via categories. Adding the `UISpec` category to your spec class definition will cause it to be picked up and executed.
1. Specs begin with "it" and should be camel-cased descriptive. i.e. itShouldConsiderA200ResponseSuccessful
1. Expectations are provided using OCHamcrest. Details of the matchers are available on the [OCHamcrest Github Page](http://jonreid.github.com/OCHamcrest/). Generally the matchers are of the form:

        assertThat([someObject someMethod], is(equalTo(@"some value")));
    There is a corresponding `isNot` method available as well.
1. The RKSpecEnvironment.h header includes a number of helpers for initializing and configuring a clean testing environment.
1. OCMock is available for mock objects support. See [http://www.mulle-kybernetik.com/software/OCMock/](http://www.mulle-kybernetik.com/software/OCMock/) for details

### Writing Integration Tests

RestKit ships with a Sinatra powered specs server for testing portions of the codebase that require interaction
with a web service. Sinatra is a simple Ruby DSL for defining web server. See the [Sinatra homepage](http://www.sinatrarb.com/) for more details.

The specs server is built as a set of modular Sinatra application in the Specs/Server subdirectory of the RestKit
distribution. When you are adding new integration test coverage to the library, you will need to create a new Sinatra application
to serve your needs. By convention, these are namespaced by functional unit for simplicity. For example, if we are adding a new
cacheing component to the application and want to test the functionality, we would:

1. Create a new file at `Server/lib/restkit/network/cacheing.rb`
1. Create a namespaced Ruby class inheriting from Sinatra::Base to suit our purposes:

        module RestKit
          module Network
            class Cacheing < Sinatra::Base
              get '/cacheing/index' do
                "OK"
              end
            end
          end
        end
1. Open restkit.rb and add a require for the cacheing server:

        require 'restkit/network/cacheing'
1. Open server.rb and add a use directive to the main spec server to import our module:

        class RestKit::SpecServer < Sinatra::Base
          self.app_file = __FILE__
          use RestKit::Network::Authentication
          use RestKit::Network::Cacheing

You now have a functional server-side component to work with. Consult the Sinatra documentation for example on setting
response headers, MIME types, etc. It's all very simple and low ceremony.

You can now switch to the RestKit sources and look the in Specs directory. Keeping with the cacheing example, we would create a new RKCacheingSpec.m file and pull in RKSpecEnvironment.h. From there we can utilize `RKSpecResponseLoader` to asynchronously test
the entire request/response cycle. The response loader essentially spins the run-loop to allow background processing to execute and
simulate a blocking API. The response, objects, or errors generated by processing the response are made available via properties
on the RKSpecResponseLoader object.

Let's take a look at an example of how to use the response loader to test some functionality:

     - (void)itShouldFailAuthenticationWithInvalidCredentialsForHTTPAuthBasic {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        RKClient* client = [RKClient clientWithBaseURL:RKSpecGetBaseURL()];
        client.username = RKAuthenticationSpecUsername;
        client.password = @"INVALID";
        [client get:@"/authentication/basic" delegate:loader];
        [loader waitForResponse];
        assertThatBool([loader.response isOK], is(equalToBool(NO)));
        assertThatInt([loader.response statusCode], is(equalToInt(0)));
        assertThatInt([loader.failureError code], is(equalToInt(NSURLErrorUserCancelledAuthentication)));
      }

That's really all there is to it. Consult the existing test code in Specs/ for reference. 

Happy Testing!
