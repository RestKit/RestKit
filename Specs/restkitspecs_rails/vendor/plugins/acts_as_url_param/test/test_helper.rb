# Include this file in your test by copying the following line to your test:
#   require File.expand_path(File.dirname(__FILE__) + "/test_helper")

require 'test/unit'
rails_env = File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
if File.exist? rails_env
  ENV["RAILS_ENV"] = "test"
  require rails_env
  require 'active_record/fixtures'
else
  require 'rubygems'
  $:.unshift(File.dirname(__FILE__) + '/../lib')
  RAILS_ROOT = File.dirname(__FILE__)
  require 'active_record'
  require 'active_record/fixtures'
  require "#{File.dirname(__FILE__)}/../init"
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
end

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

load_schema = Proc.new do
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  schema = File.dirname(__FILE__) + "/schema.rb"
  ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])
  load(schema) if File.exist?(schema)
  ACTS_AS_URL_PARAM_TEST_DB = ActiveRecord::Base.connection
end

keep_connection_and_load_schema = Proc.new do
  old_connection = ActiveRecord::Base.connection
  load_schema.call
  ActiveRecord::Base.connection = old_connection
end

ActiveRecord::Base.connected? ? keep_connection_and_load_schema.call : load_schema.call

require "redirect"
Redirect.connection = ACTS_AS_URL_PARAM_TEST_DB

class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
end