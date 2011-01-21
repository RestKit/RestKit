Discussion Board
================

This directory contains a full example of building an
iPhone client application using RestKit and interacting
with and a Rails backend server application.

You do not need to run the backend application yourself
to work with the client example. If you use the 'Production'
configuration, the client will talk to an instance of the
server provisioned on Heroku.

Configuring the Server
----------------------

If you wish to work with a local server, you will need to
have a functioning installation of Ruby, Rails and the Bundler
Gem installed. Once you have this basic environment set up:

1. Move into the server directory: 
  `cd Examples/RKDiscussionBoardExample/discussion_board_backend`
1. Invoke Bundler:
  `bundle`  
1. Create & migrate the database:
  `rake db:create db:migrate`  
1. Start the server:
  `./script/rails server`

You can now build and run the DiscussionBoard iOS application
on the 'Development' configuration.

Building the Client
-------------------

The iOS example application utilizes RestKit and the Three20
integration to drive the interface. We have bundled a binary
build of Three20 to avoid adding any external dependencies and
complexity. The Three20 static libraries are fat and the application
will run in the simulator or on your device.

If you wish to use your device, you will need to manually edit the
base URL configuration in the DBEnvironment.h file (or build with 
the Production configuration).

We hope you find this example app helpful in getting started with
RestKit and understanding the framework!
