require "rack/oauth2/sinatra"
require "rack/oauth2/server"

# Override this so we can specify an ObjectId manually
module Rack
	module OAuth2
		class Server
			class AuthRequest
				class << self
          def create(client, scope, redirect_uri, response_type, state, id = nil)
            scope = Utils.normalize_scope(scope) & client.scope # Only allowed scope
            fields = { :client_id=>client.id, :scope=>scope, :redirect_uri=>client.redirect_uri || redirect_uri,
		          :response_type=>response_type, :state=>state,
		          :grant_code=>nil, :authorized_at=>nil,
		          :created_at=>Time.now.to_i, :revoked=>nil }
            fields[:_id] = BSON::ObjectId.from_string(id) if id
            fields[:_id] = collection.insert(fields)
            Server.new_instance self, fields
          end
				end
			end
		end
	end
end

module RestKit
  module Network
    module OAuth2
      module Scenarios
        class App          
          def initialize(app)
            @base_url = '/oauth2/basic'
          end
  
          def db_setup
            Rack::OAuth2::Server.options.database = Mongo::Connection.new[ENV["DB"]]
            Rack::OAuth2::Server.options.collection_prefix = "oauth2_prefix"
          end    
  
          def setup(env)
            Rack::OAuth2::Server.options.authorize_path = "/authorize"
            Rack::OAuth2::Server.options.access_token_path = "/token"
            Rack::OAuth2::Server.options.authorization_types = ["code", "token"]
            create_fixtures
          end
          
          def create_fixtures
            @client = Rack::OAuth2::Server.register(RESTKIT_CLIENT_PARAMS)
          end
  
          def teardown(response)
            if redirect?(response)
              response[1]["Location"].gsub!(/\/authorize/, @base_url + '/authorize')
              response[1]["Location"].gsub!(/\/token/, @base_url + '/token')
              response[1]["Location"].gsub!(/\/me/, @base_url + '/me')
            end
          end
          
          def redirect?(response)
            response && response[1] && response[1]["Location"]
          end
          
          def drop_all
            Rack::OAuth2::Server::Client.collection.drop
            Rack::OAuth2::Server::AuthRequest.collection.drop
            Rack::OAuth2::Server::AccessGrant.collection.drop
            Rack::OAuth2::Server::AccessToken.collection.drop
            Rack::OAuth2::Server::Issuer.collection.drop
          end
  
          def call(env)
            env.delete 'SCRIPT_NAME'  # otherwise Rack::OAuth::Server will merge this back into path_info
            db_setup
            
            if env['PATH_INFO'] =~ /^\/reset/
              drop_all
              [200, {}, "Aye, aye!"]
            else
              setup env
              response = OAuth2App.call(env)
              teardown response
              response
            end
          end
          
          def create_access_grant(identity, client, scope, id = nil, redirect_uri = nil, expires = nil)
            raise ArgumentError, "Identity must be String or Integer" unless String === identity || Integer === identity
            scope = Rack::OAuth2::Server::Utils.normalize_scope(scope) & client.scope # Only allowed scope
            expires_at = Time.now.to_i + (expires || 300)
            id = Rack::OAuth2::Server.secure_random unless id
            fields = { :_id=>id, :identity=>identity, :scope=>scope,
                       :client_id=>client.id, :redirect_uri=>client.redirect_uri || redirect_uri,
                       :created_at=>Time.now.to_i, :expires_at=>expires_at, :granted_at=>nil,
                       :access_token=>nil, :revoked=>nil }
            Rack::OAuth2::Server::AccessGrant.collection.insert fields
            Rack::OAuth2::Server.new_instance Rack::OAuth2::Server::AccessGrant, fields
          end
        end
        
        class PregeneratedTokens < App
          def initialize(app)
            @base_url = '/oauth2/pregen'
          end
          
          def setup(env)
            drop_all
            super
          end
          
          def create_fixtures
            @client = Rack::OAuth2::Server.register(RESTKIT_CLIENT_PARAMS)
            @auth_request = Rack::OAuth2::Server::AuthRequest.find('4fa8182d7184797dd5000001') || Rack::OAuth2::Server::AuthRequest.create(@client, @client.scope, @client.redirect_uri.to_s, 'code', nil, '4fa8182d7184797dd5000001')
            @access_grant = create_access_grant("Identity", @client, @client.scope, '4fa8182d7184797dd5000002', @client.redirect_uri)

            @auth_request.grant_code = @access_grant.code
            Rack::OAuth2::Server::AuthRequest.collection.update({:_id=>@auth_request.id, :revoked=>nil}, {:$set=>{ :grant_code=>@access_grant.code, :authorized_at=> Time.now}})
          end
        end
      end

      class OAuth2App < Sinatra::Base
        register Rack::OAuth2::Sinatra
  
        configure do
          enable :logging, :dump_errors
        end
        
        set :sessions, true
        set :show_exceptions, false
  
        get "/authorize" do
          if oauth.client
            "client: #{oauth.client.display_name}\nscope: #{oauth.scope.join(", ")}\nauthorization: #{oauth.authorization}"
          else
            "No client"
          end
        end
        
        oauth_required "/me"
        
        get '/me' do
          response = {'user_id' => 1, 'name' => 'Rod'}
          content_type 'application/json'
          response
        end
  
      end
    end
  end
end