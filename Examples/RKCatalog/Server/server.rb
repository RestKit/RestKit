# RestKit RKCatalog Sample

require 'rubygems'
require 'sinatra/base'
require 'json'

class RKExampleServer < Sinatra::Base
  self.app_file = __FILE__
  
  configure do
    set :logging, true
    set :dump_errors, true
    set :show_exceptions, true
  end
  
  post '/RKParamsExample' do
    "OK"
  end
  
  get '/RKRequestQueueExample' do
    sleep(1.0)
    "OK"
  end
  
  get '/RKBackgroundRequestExample' do
    content_type 'text/plain'
    sleep(5)
    "OK"
  end
  
  get '/RKKeyValueMappingExample' do
    content_type 'application/json'
    %Q{{
          "id": 1234,
          "name": "Personal Checking",
          "balance": 5013.26,
          "transactions": [
            {"id": 1, "payee": "Joe Blow", "amount": 50.16},
            {"id": 2, "payee": "Grocery Store", "amount": 200.15},
            {"id": 3, "payee": "John Doe", "amount": 325.00},
            {"id": 4, "payee": "Grocery Store", "amount": 25.15}]
      }}
  end
  
  # Used by the Relationship mapping examples
  get '/RKRelationshipMappingExample' do
    content_type 'application/json'
    %Q{
      [{"project": {
              "id": 123,
              "name": "Produce RestKit Sample Code",
              "description": "We need more sample code!",
              "user": {
                  "id": 1,
                  "name": "Blake Watters",
                  "email": "blake@twotoasters.com"
              },
              "tasks": [
                  {"id": 1, "name": "Identify samples to write", "assigned_user_id": 1},
                  {"id": 2, "name": "Write the code", "assigned_user_id": 1},
                  {"id": 3, "name": "Push to Github", "assigned_user_id": 1},
                  {"id": 4, "name": "Update the mailing list", "assigned_user_id": 1}
              ]
          }},
          {"project": {
              "id": 456,
              "name": "Document Object Mapper",
              "description": "The object mapper could really use some docs!",
              "user": {
                  "id": 2,
                  "name": "Jeremy Ellison",
                  "email": "jeremy@twotoasters.com"
              },
              "tasks": [
                  {"id": 5, "name": "Mark up methods with Doxygen markup", "assigned_user_id": 2},
                  {"id": 6, "name": "Generate docs and review formatting", "assigned_user_id": 2},
                  {"id": 7, "name": "Review docs for accuracy and completeness", "assigned_user_id": 1},
                  {"id": 8, "name": "Publish to Github", "assigned_user_id": 2}
              ]
          }},
          {"project": {
              "id": 789,
              "name": "Wash the Cat",
              "description": "Mr. Fluffy is looking like Mr. Scruffy! Time for a bath!",
              "user": {
                  "id": 3,
                  "name": "Rachit Shukla",
                  "email": "rachit@twotoasters.com"
              },
              "tasks": [
                  {"id": 9, "name": "Place cat in bathtub", "assigned_user_id": 3},
                  {"id": 10, "name": "Run water", "assigned_user_id": 3},
                  {"id": 11, "name": "Try not to get scratched", "assigned_user_id": 3}
              ]
          }}]
    }
  end
end

RKExampleServer.run!
