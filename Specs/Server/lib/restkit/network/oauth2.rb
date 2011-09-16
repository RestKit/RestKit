module RestKit
  module Network
    class OAuth2 < Sinatra::Base
      ACCESS_TOKEN = '581b50dca15a9d41eb280d5cbd52c7da4fb564621247848171508dd9d0dfa551a2efe9d06e110e62335abf13b6446a5c49e4bf6007cd90518fbbb0d1535b4dbc'
      
      post '/oauth/authorize' do
        authorization_code = params[:code]
        response = ""
        if "1234" == authorization_code
          response = { 'access_token' => ACCESS_TOKEN, 'timeout' => 31337 }.to_json
        else
          response = {'error' => 'invalid_grant', 'error_description' => 'authorization code not valid'}.to_json
        end
          content_type 'application/json'
          response
      end
      
      get '/me' do
        access_token = params[:Authorization]
        tokenHeader = 'OAuth2 ' + ACCESS_TOKEN
        response = ''
        if access_token.nil?
          status 401
          response = {'message' => "A valid access_token is required to access."}.to_json
        elsif tokenHeader == access_token
          response = {'user_id' => 1, 'name' => 'Rod'}
        else
          status 401
          response = {'message' => "Bad credentials"}.to_json
        end
          content_type 'application/json'
          response      
      end
      
    end            
  end
end