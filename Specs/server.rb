require 'rubygems'
require 'sinatra'
require 'json'
require 'ruby-debug'

Debugger.start

post '/photo' do
  puts "Got request: #{request.body.read}"
end
