# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
require 'spec/autorun'
require 'spec/rails'

# Uncomment the next line to use webrat's matchers
# require 'webrat/integrations/rspec-rails'

# Load the Objective Spec framework
require 'objective_spec'

# Load additional helpers
require 'authlogic/test_case'
require 'factory_girl'
require 'nokogiri'
require 'nulldb_rspec'

# Load the Factory Girl global factories
require File.join(Rails.root, 'spec', 'factories')

# Load up the Email Spec helpers
require "email_spec/helpers"
require "email_spec/matchers"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  
  config.include(Authlogic::TestCase)
  
  # Work around problem with generated spec's being annoyed at the URL Rewriter...
  config.include(ActionController::UrlWriter, :type => :view)
  config.include(ViewSpecHelper, :type => :view)
  config.include(ControllerSpecHelper, :type => :controller)
  
  # TODO - Encapsulate into objective_spec/mailer.rb
  config.include(EmailSpec::Helpers, :type => :mailer)
  config.include(EmailSpec::Matchers, :type => :mailer)
  config.include(ActionController::UrlWriter, :type => :mailer)
  
  # Disconnect all specs except for Model and Controller
  config.include(Disconnected, :type => :helper)
  config.include(Disconnected, :type => :mailer)
  config.include(Disconnected, :type => :view)
  
  config.include(CommonSpecHelper)  
end
