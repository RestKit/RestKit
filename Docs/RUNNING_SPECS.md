RestKit Spec Environment
========================

RestKit ships with a testing infrastructure built around UISpec and
an associated Ruby Gem called UISpecRunner. To be able to run the
tests, you need to do a little bit of setup:

1. Initialize the UISpec submodule: `git submodule init && git submodule update`
1. Install the Ruby Bundler Gem (if necessary): `sudo gem install bundler`
1. Install the other required Gems via Bundler: `bundle`
1. Verify the configuration by running the specs: `uispec -v`

If the project builds the UISpec target correctly and executes the suite, then
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

* Run all specs: `uispec`
* Run a specific spec class: `uispec -s RKClientSpec`
* Run a specific spec example: `uispec -s RKClientSpec -e itShouldDetectNetworkStatusWithAHostname`
* Run all specs conforming to a protocol: `uispec -p UISpecUnit`

Common spec groupings (i.e. Units and Integration) are configured for execution via the Rakefile.