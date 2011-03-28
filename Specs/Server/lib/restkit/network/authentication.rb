module RestKit
  module Network
    class Authentication < Sinatra::Base
      AUTH_USERNAME = 'restkit'
      AUTH_PASSWORD = 'authentication'
      AUTH_REALM    = 'RestKit'
      AUTH_OPAQUE   = '7e7e7e7e7e'
      
      get '/authentication/none' do
        "Success!"
      end
      
      get '/authentication/basic' do
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
        unless @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [AUTH_USERNAME, AUTH_PASSWORD]
          response['WWW-Authenticate'] = %(Basic realm="#{AUTH_REALM}")
          throw(:halt, [401, "Not authorized\n"])
        end
      end
      
      get '/authentication/digest' do
        app = lambda do |env|
          [ 200, {'Content-Type' => 'text/plain'}, ["Hi #{env['REMOTE_USER']}"] ]
        end
        auth = Rack::Auth::Digest::MD5.new(app) do |username|
          username == AUTH_USERNAME ? Digest::MD5.hexdigest("#{AUTH_USERNAME}:#{AUTH_REALM}:#{AUTH_PASSWORD}") : nil
        end
        auth.realm = AUTH_REALM
        auth.opaque = AUTH_OPAQUE
        auth.passwords_hashed = true
        auth.call(request.env)
      end            
    end
  end
end
