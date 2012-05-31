require File.dirname(__FILE__) + "/../server"
require File.expand_path(File.dirname(__FILE__)) + '/../fixtures'
require "rubygems"
require "test/unit"
require "rack/test"
require "rack/oauth2/server"

Rack::OAuth2::Server.options.database = Mongo::Connection.new[ENV["DB"]]
Rack::OAuth2::Server.options.collection_prefix = "oauth2_prefix"

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include Rack::OAuth2
end