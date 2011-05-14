#!/usr/bin/env ruby
# RestKit Spec Server

require 'rubygems'
require 'sinatra/base'
require 'json'
require 'ruby-debug'
Debugger.start

# Import the RestKit Spec server
$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
require 'restkit/network/authentication'

class RestKit::SpecServer < Sinatra::Base
  self.app_file = __FILE__
  use RestKit::Network::Authentication
  
  configure do
    set :logging, true
    set :dump_errors, true
    set :public, Proc.new { File.join(root, '../Fixtures') }
  end
  
  get '/' do
    content_type 'application/json'
    {'status' => 'ok'}.to_json
  end
  
  post '/photo' do
    content_type 'application/json'
    "OK"
  end
  
  get '/errors.json' do
    status 401
    content_type 'application/json'
    send_file 'Specs/Server/../Fixtures/JSON/errors.json'
  end
  
  post '/humans' do
    status 201
    content_type 'application/json'
    {:human => {:name => "My Name", :id => 1}}.to_json
  end
  
  delete '/humans/1' do
    status 200
    content_type 'application/json'
    "{}"
  end
  
  # start the server if ruby file executed directly
  run! if app_file == $0
end
