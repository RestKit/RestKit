require File.expand_path(File.dirname(__FILE__)) + '/server'

# Basic OAuth 2.0 implementation
map '/oauth2/basic' do
  run RestKit::Network::OAuth2::Scenarios::App.new(nil)
end

map '/oauth2/pregen' do
  run RestKit::Network::OAuth2::Scenarios::PregeneratedTokens.new(nil)
end

# Should just be /reset 
map '/oauth2reset' do 
  run RestKit::Network::OAuth2::Scenarios::App.new(nil)
end

map '/oauth1' do
  use RestKit::Network::OAuth1::Middleware
  run RestKit::Network::OAuth1::App
end

map '/' do
  run RestKitTestServer
end