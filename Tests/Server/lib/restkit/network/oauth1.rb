require 'rack/auth/abstract/request'
require 'simple_oauth'
require 'ruby_debug'

TOKEN_SECRET = 'monkey'
CLIENT_SECRET = 'restkit_secret'

module RestKit
  module Network
    module OAuth1
      class Middleware

        # This class modified from https://github.com/tonywok/forcefield

        # Copyright (c) 2011 EdgeCase, Tony Schneider
        # 
        # Permission is hereby granted, free of charge, to any person obtaining
        # a copy of this software and associated documentation files (the
        # "Software"), to deal in the Software without restriction, including
        # without limitation the rights to use, copy, modify, merge, publish,
        # distribute, sublicense, and/or sell copies of the Software, and to
        # permit persons to whom the Software is furnished to do so, subject to
        # the following conditions:
        # 
        # The above copyright notice and this permission notice shall be
        # included in all copies or substantial portions of the Software.
        # 
        # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
        # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
        # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
        # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
        # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
        # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        
        def initialize(app)
          @app = app
        end

        def call(env) 
          # rebuild the original path so that signatures match
          env.delete 'SCRIPT_NAME'
          env['PATH_INFO'] = '/oauth1' + env['PATH_INFO']
          
          @request = RestKit::Network::OAuth1::Request.new(env)

          @request.with_valid_request do
            if client_verified?
              @app.call(env)
            else
              [401, {}, ["Unauthorized."]]
            end
          end
        end

        private

        def client_verified?
          @request.verify_signature("restkit_secret")
        end
      end
      
      class Request < Rack::Auth::AbstractRequest

        # This class modified from https://github.com/tonywok/forcefield

        # Copyright (c) 2011 EdgeCase, Tony Schneider
        # 
        # Permission is hereby granted, free of charge, to any person obtaining
        # a copy of this software and associated documentation files (the
        # "Software"), to deal in the Software without restriction, including
        # without limitation the rights to use, copy, modify, merge, publish,
        # distribute, sublicense, and/or sell copies of the Software, and to
        # permit persons to whom the Software is furnished to do so, subject to
        # the following conditions:
        # 
        # The above copyright notice and this permission notice shall be
        # included in all copies or substantial portions of the Software.
        # 
        # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
        # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
        # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
        # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
        # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
        # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        
        
        # This method encapsulates the various checks we need to make against the request's
        # Authorization header before we deem it ready for verification.
        # Upon passing the checks, we yield to the block so that simple_oauth can determine
        # whether or not the request has been properly signed.
        #
        def with_valid_request
            if provided? # #provided? defined in Rack::Auth::AbstractRequest
              if !oauth?
                [400, {}, ["Bad request. No auth scheme provided."]]
              elsif params[:consumer_key].nil?
                [400, {}, ["Bad request. No consumer key provided."]]
              elsif params[:signature].nil?
                [400, {}, ["Bad request. No signature provided."]]
              elsif params[:signature_method].nil?
                [400, {}, ["Bad request. No signature method provided."]]
              else
                yield(request.env)
              end
            else
              [400, {}, ["Bad request."]]
            end
        end

        def verify_signature(client_secret)
          return false unless client_secret
          header = SimpleOAuth::Header.new(request.request_method, request.url, included_request_params, auth_header)
          
          header.valid?({:consumer_secret => CLIENT_SECRET, :token_secret => TOKEN_SECRET})
        end

        def consumer_key
          params[:consumer_key]
        end

        private

        def params
          @params ||= SimpleOAuth::Header.parse(auth_header)
        end

        # #scheme is defined as an instance method on Rack::Auth::AbstractRequest
        #
        def oauth?
          scheme == :oauth
        end

        def auth_header
          @env[authorization_key]
        end

        # only include request params if Content-Type is set to application/x-www/form-urlencoded
        # (see http://tools.ietf.org/html/rfc5849#section-3.4.1)
        #
        def included_request_params
          request.content_type == "application/x-www-form-urlencoded" ? request.params : nil
        end
      end
      
      class App < Sinatra::Base
        configure do
          enable :logging, :dump_errors
        end
        
        get '/oauth1/me' do
          response = {'user_id' => 1, 'name' => 'Rod'}
          content_type 'application/json'
          response
        end
      end
         
    end
  end
end