RestKit UISpec README
=====================

RestKit contains some amount of test coverage via UISpec. The
coverage is not nearly as complete as it can and should be, but
does provide some amount of coverage. We expect this support to 
be expanded over time and supported with continuous integration.

In order to run the tests, you must run two Ruby servers that 
different parts of the suite interact with. One is a Rails 
app and the other is a Sinatra server.

Initializing the Spec Environment
---------------------------------

Before you can run the specs, you need to initialize the Rails
spec server. To do so:
1. Change directories to the Rails app: `cd Specs/restkitspecs_rails/`
1. Initialize the database: `rake db:create db:migrate`
1. Seed the database: `rake db:seed`

You now have the environment prepared to run the specs.

To Run the Specs
----------------
1. Start the Rails application. From the project root, run:
    ./Specs/restkitspecs_rails/script/server
1. Start the Sinatra application. From the project root, run:
    ruby Specs/server.rb
1. Build & Run the UISpec target from Xcode.