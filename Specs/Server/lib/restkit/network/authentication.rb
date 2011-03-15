module RestKit
  module Network
    class Authentication < Sinatra::Base
      AUTH_USERNAME = 'restkit'
      AUTH_PASSWORD = 'authentication'
      
      helpers do
        def protected!
            unless authorized?
              response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
              throw(:halt, [401, "Not authorized\n"])
            end
          end

          def authorized?
            @auth ||= Rack::Auth::Basic::Request.new(request.env)
            @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
          end
      end
      
      get '/authentication/none' do
        "Success!"
      end
      
      get '/authentication/basic' do
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
        unless @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [AUTH_USERNAME, AUTH_PASSWORD]
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      get '/authentication/digest' do
        # TODO..
        @auth = Rack::Auth::Digest::Request.new(request.env)
        unless @auth.provided? && @auth.digest? && @auth.credentials && @auth.credentials == [AUTH_USERNAME, AUTH_PASSWORD]
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
        
        # do |username|
        #  username == 'Alice' ? Digest::MD5.hexdigest("Alice:#{realm}:correct-password") : nil
        #end
        # app.realm = realm
        # app.opaque = 'this-should-be-secret'
        # app.passwords_hashed = true
      end
    end
  end
end