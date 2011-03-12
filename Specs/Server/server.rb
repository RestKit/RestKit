#!/usr/bin/env ruby
# RestKit Spec Server

require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'json'
require 'ruby-debug'
Debugger.start

# TODO: Push the lib directory onto the include path...
require 'restkit'

# TODO: Move this out somewhere/somehow...
# Replace with ActiveModel or something???
class Model
  def self.attributes(*attributes)
    @attributes ||= []
    @attributes += attributes
    attributes.each { |attr| attr_accessor attr }
  end
  
  def self.defined_attributes
    @attributes
  end
  
  def initialize(options = {})
    options.each { |k,v| self.send("#{k}=", v) }
  end
  
  def to_hash
    self.class.defined_attributes.inject({}) { |hash, attr| hash[attr] = self.send(attr); hash }
  end
  
  def to_json
    JSON.generate(self.to_hash)
  end
end

class Human < Model
  attributes :id, :name, :sex, :age, :birthday, :created_at, :updated_at
end

class RestKit::SpecServer < Sinatra::Base
  use RestKit::Network::Authentication
  
  post '/photo' do
    content_type 'application/json'
    "OK"
  end

  get '/humans/1' do
    content_type 'application/json'
    JSON.generate(:human => Human.new(:name => 'Blake Watters').to_hash)
  end

  get '/humans' do
    content_type 'application/json'
    JSON.generate([{:human => Human.new(:name => 'Blake Watters').to_hash}, {:human => Human.new(:name => "Other").to_hash}])
  end

  # TODO: Factor these out...
  get '/authentication/basic' do

  end

  get '/authentication/digest' do
  end
  
  # start the server if ruby file executed directly
  run! if app_file == $0
end
