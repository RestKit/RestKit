#!/usr/bin/env ruby
# RestKit Spec Server

require 'rubygems'
#require 'sinatra'
require 'sinatra/base'
require 'json'
require 'ruby-debug'
Debugger.start

# Import the RestKit Spec server
$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
require 'restkit'

# TODO: Factor me out...
class Human < Model
  attributes :id, :name, :sex, :age, :birthday, :created_at, :updated_at
end

class RestKit::SpecServer < Sinatra::Base
  self.app_file = __FILE__
  use RestKit::Network::Authentication
  
  configure do
    set :logging, true
    set :dump_errors, true
  end
  
  post '/photo' do
    content_type 'application/json'
    "OK"
  end

  # TODO: Move to object_mapping dir
  get '/humans/1' do
    content_type 'application/json'
    JSON.generate(:human => Human.new(:name => 'Blake Watters').to_hash)
  end

  get '/humans' do
    content_type 'application/json'
    JSON.generate([{:human => Human.new(:name => 'Blake Watters').to_hash}, {:human => Human.new(:name => "Other").to_hash}])
  end
  
  # start the server if ruby file executed directly
  run! if app_file == $0
end
