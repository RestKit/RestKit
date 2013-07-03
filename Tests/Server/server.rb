#!/usr/bin/env ruby
# RestKit Test Server
require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'json'
require 'debugger'

class Person < Struct.new(:name, :age)
  def to_json(*args)
    {:name => name, :age => age}.to_json
  end
end

class RestKitTestServer < Sinatra::Base
  self.app_file = __FILE__

  configure do
    enable :logging, :dump_errors
    set :public_folder, Proc.new { File.expand_path(File.join(root, '../Fixtures')) }
    set :uploads_path, Proc.new { File.expand_path(File.join(root, '../Fixtures/Uploads')) }
  end

  def render_fixture(path, options = {})
    send_file File.join(settings.public_folder, path), options
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
    content_type 'application/json'
    render_fixture('/JSON/errors.json', :status => 400)
  end

  post '/humans' do
    status 201
    content_type 'application/json'
    {:human => {:name => "My Name", :id => 1, :website => "http://restkit.org/"}}.to_json
  end

  post '/humans/and_cats' do
    content_type 'application/json'
    render_fixture('/JSON/humans/and_cats.json', :status => 201)
  end

  post '/humans/fail' do
    content_type 'application/json'
    render_fixture('/JSON/errors.json', :status => 500)
  end

  get '/humans/1' do
    etag('2cdd0a2b329541d81e82ab20aff6281b')
    status 200
    content_type 'application/json'
    {:human => {:name => "Blake Watters", :id => 1}}.merge(params).to_json
  end

  delete '/humans/1' do
    status 200
    content_type 'application/json'
    "{}"
  end

  delete '/humans/204' do
    status 204
    content_type 'application/json'
  end

  delete '/humans/empty' do
    status 200
    content_type 'application/json'
    ""
  end

  delete '/humans/success' do
    status 200
    content_type 'application/json'
    {:human => {:status => 'OK'}}.to_json
  end

  post '/echo_params' do
    status 200
    content_type 'application/json'
    params.to_json
  end

  post '/204' do
    status 204
    content_type 'application/json'
    "".to_json
  end

  get '/204' do
    status 204
    content_type 'application/json'
    "".to_json
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

  get '/503' do
    status 503
    "Internal Server Error"
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

  get '/timeout' do
    # We need to leave this around 4 seconds so we don't hold up the
    # process too long and cause the tests launched after to fail.
    sleep 4
    status 200
    content_type 'application/json'
    params.to_json
  end

  post '/timeout' do
    sleep 2
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

  get '/fail' do
    content_type 'application/json'
    render_fixture('/JSON/errors.json', :status => 500)
  end

  get '/500' do
    status 500
    content_type 'application/json'
  end

  # Expects an uploaded 'file' param
  post '/api/upload/' do
    unless params['file']
      status 500
      return "No file parameter was provided"
    end
    upload_path = File.join(settings.uploads_path, params['file'][:filename])
    File.open(upload_path, "w") do |f|
      f.write(params['file'][:tempfile].read)
    end
    status 200
    content_type 'application/json'
    { :name => "Blake" }.to_json
  end

  # Return 200 after a delay
  get '/ok-with-delay/:delay' do
    sleep params[:delay].to_f
    status 200
    content_type 'application/json'
    ""
  end

  get '/paginate' do
    status 200
    content_type 'application/json'

    per_page = 3
    total_entries = 6
    current_page = params[:page].to_i
    entries = []

    case current_page
      when 1
        entries << Person.new('Blake', 29)
        entries << Person.new('Sarah', 30)
        entries << Person.new('Colin', 27)
      when 2
        entries << Person.new('Asia', 8)
        entries << Person.new('Roy', 2)
        entries << Person.new('Lola', 9)
      when 3
        # Return an error payload
        status 422
        return {:error => "Invalid page number."}
      else
        status 404
        return ""
    end

    {:per_page => per_page, :total_entries => total_entries,
     :current_page => current_page, :entries => entries, :total_pages => 3}.to_json
  end

  get '/paginate/' do
    status 200
    content_type 'application/json'
    {:per_page => 10, :total_entries => 0,
     :current_page => 1, :entries => [], :total_pages => 0}.to_json
  end

  get '/coredata/etag' do
    content_type 'application/json'
    tag = '2cdd0a2b329541d81e82ab20aff6281b'
    cache_control(:private, :must_revalidate, :max_age => 0)
    if tag == request.env["HTTP_IF_NONE_MATCH"]
      status 304
      ""
    else
      etag(tag)
      render_fixture '/JSON/humans/all.json'
    end
  end

  get '/object_manager/cancel' do
    sleep 0.05
    status 204
  end

  get '/object_manager/:objectID/cancel' do
    sleep 0.05
    status 204
  end

  get '/304' do
    status 304
  end

  delete '/humans/1234/whitespace' do
    content_type 'application/json'
    status 200
    ' '
  end

  post '/ComplexUser' do
    content_type 'application/json'
    render_fixture('/JSON/ComplexNestedUser.json', :status => 200)
  end

  get '/posts.json' do
    content_type 'application/json'
    { :posts => [{:title => 'Post Title', :body => 'Some body.', :tags => [{ :name => 'development' }, { :name => 'restkit' }] }] }.to_json
  end

  post '/posts.json' do
    content_type 'application/json'
    { :post => { :title => 'Post Title', :body => 'Some body.', :tags => [{ :name => 'development' }, { :name => 'restkit' }] } }.to_json
  end

  get '/posts_with_invalid.json' do
    content_type 'application/json'
    { :posts => [{:title => 'Post Title', :body => 'Some body.'}, {:title => '', :body => 'Some body.'} ] }.to_json
  end

  get '/posts/:post_id/tags' do
    content_type 'application/json'
    [{ :name => 'development' }, { :name => 'restkit' }].to_json
  end

  post '/tags' do
    content_type 'application/json'
    [{ :name => 'development' }, { :name => 'restkit' }].to_json
  end

  get '/user' do
    content_type 'application/json'
    render_fixture('/JSON/user.json', :status => 200)
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
