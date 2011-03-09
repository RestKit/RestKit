require 'rubygems'
require 'sinatra'
require 'json'
require 'ruby-debug'

Debugger.start

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
  humans = (1..4).map { Human.new.to_hash }
  JSON.generate(:humans => humans)
end
