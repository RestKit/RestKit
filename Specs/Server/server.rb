#!/usr/bin/env ruby
# RestKit Spec Server

require 'rubygems'
require 'sinatra/base'
require "sinatra/reloader"
require 'json'
require 'ruby-debug'
Debugger.start

# Import the RestKit Spec server
$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
require 'restkit/network/authentication'
require 'restkit/network/etags'
require 'restkit/network/timeout'
require 'restkit/network/oauth2'

class RestKit::SpecServer < Sinatra::Base
  self.app_file = __FILE__
  use RestKit::Network::Authentication
  use RestKit::Network::ETags
  use RestKit::Network::Timeout
  use RestKit::Network::OAuth2
  
  configure do
    register Sinatra::Reloader
    set :logging, true
    set :dump_errors, true
    set :public, Proc.new { File.join(root, '../Fixtures') }
    set :uploads_path, Proc.new { File.join(root, '../Fixtures/Uploads') }
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
    puts "Got params: #{params.inspect}"
    {:human => {:name => "My Name", :id => 1, :website => "http://restkit.org/"}}.to_json
  end
  
  post '/humans/fail' do
    status 500
    content_type 'application/json'
    send_file 'Specs/Server/../Fixtures/JSON/errors.json'
  end
  
  get '/humans/1' do
    status 200
    content_type 'application/json'
    puts "Got params: #{params.inspect}"
    {:human => {:name => "Blake Watters", :id => 1}}.merge(params).to_json
  end
  
  delete '/humans/1' do
    status 200
    content_type 'application/json'
    "{}"
  end
  
  post '/echo_params' do
    status 200
    content_type 'application/json'
    params.to_json
  end
  
  post '/204' do
    status 204
    content_type 'application/json'
    ""
  end
  
  get '/403' do
    status 403
    content_type 'application/json'
    "{}"
  end
  
  get '/404' do
    status 404
    content_type 'text/html'
    "File Not Found"
  end
  
  get '/encoding' do
    status 200
    content_type 'text/plain; charset=us-ascii'
    "ASCII Charset"
  end
  
  post '/notNestedUser' do
    content_type 'application/json'
    { 'email' => 'changed', 'ID' => 31337 }.to_json
  end
  
  delete '/humans/1234' do
    content_type 'application/json'
    status 200
  end
  
  get '/users/empty' do
    content_type 'application/json'
    status 200
    { :firstUser => {}, :secondUser => {}}.to_json
  end
  
  put '/ping' do
    status 200
    content_type 'application/json'
    params.to_json
  end
  
  get '/empty/array' do
    status 200
    content_type 'application/json'
    [].to_json
  end
  
  get '/empty/dictionary' do
    status 200
    content_type 'application/json'
    {}.to_json
  end
  
  get '/empty/string' do
    status 200
    content_type 'application/json'
    ""
  end
  
  # Expects an uploaded 'file' param
  post '/upload' do
    unless params['file']
      status 500
      return "No file parameter was provided"
    end
    upload_path = File.join(settings.uploads_path, params['file'][:filename])
    File.open(upload_path, "w") do |f|
      f.write(params['file'][:tempfile].read)
    end
    status 200
    "Uploaded successfully to '#{upload_path}'"
  end
  # Return 200 after a delay
  get '/ok-with-delay/:delay' do
    sleep params[:delay].to_f
    status 200
    content_type 'application/json'
    ""
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
