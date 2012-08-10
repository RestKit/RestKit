require File.dirname(__FILE__) + "/spec_helper"

describe "OAuth2" do
  def app
    Rack::Builder.parse_file(File.dirname(__FILE__) + "/../server.ru").first
  end
  
  before(:all) do
    clear_database
    @client = Server.register(RESTKIT_CLIENT_PARAMS)
    @params = {:redirect_uri=>'http://restkit.org/', :client_id=>@client.id, :client_secret=>@client.secret, :response_type=>"code", :scope=>"read write", :state=>"bring this back" }
  end

  def clear_database
    Rack::OAuth2::Server::Client.collection.drop
    Rack::OAuth2::Server::AuthRequest.collection.drop
    Rack::OAuth2::Server::AccessGrant.collection.drop
    Rack::OAuth2::Server::AccessToken.collection.drop
    Rack::OAuth2::Server::Issuer.collection.drop
  end
    
  context "Resetting the OAuth2 pathway" do
    it "should clear the database" do
      clear_database
      Rack::OAuth2::Server::Client.collection.count.should eq 0
      Rack::OAuth2::Server::AuthRequest.collection.count.should eq 0
      Rack::OAuth2::Server::AccessGrant.collection.count.should eq 0
      Rack::OAuth2::Server::AccessToken.collection.count.should eq 0
      Rack::OAuth2::Server::Issuer.collection.count.should eq 0
      
      Rack::OAuth2::Server.register(RESTKIT_CLIENT_PARAMS)
      Rack::OAuth2::Server::Client.collection.count.should eq 1

      get "/oauth2/basic/authorize?" + Rack::Utils.build_query(@params)
      get last_response["Location"] if last_response.status == 303

      Rack::OAuth2::Server::AuthRequest.collection.count.should eq 1

      get "/oauth2reset/reset"
      
      Rack::OAuth2::Server::Client.collection.count.should eq 0
      Rack::OAuth2::Server::AuthRequest.collection.count.should eq 0
      Rack::OAuth2::Server::AccessGrant.collection.count.should eq 0
      Rack::OAuth2::Server::AccessToken.collection.count.should eq 0
      Rack::OAuth2::Server::Issuer.collection.count.should eq 0
    end
  end
  
  context "Given a basic OAuth2 setup" do
    context "Requesting the authorization URL" do    
          
      context "With valid params" do
        it "Should report the client" do
          get "/oauth2/basic/authorize?" + Rack::Utils.build_query(@params)
          get last_response["Location"] if last_response.status == 303

          response = last_response.body.split("\n").inject({}) { |h,l| n,v = l.split(/:\s*/) ; h[n.downcase] = v ; h }
          response["client"].should eq @client.display_name
        end
      end
      
      context "Without valid params" do  
        it "Should fail" do
          get "/oauth2/basic/authorize"
          last_response.should_not be_successful
          last_response.should_not be_redirect
        end
      end
    end
    
    context "And a pre-generated authorization token and access grant" do
      context "Requesting the authorization URL with the token" do
        it "should report the client" do
          get "/oauth2/pregen/authorize?" + Rack::Utils.build_query({:authorization => '4fa8182d7184797dd5000001'})
          response = last_response.body.split("\n").inject({}) { |h,l| n,v = l.split(/:\s*/) ; h[n.downcase] = v ; h }
          response["client"].should eq @client.display_name
        end
      end

      context "Requesting the token URL with the access grant token" do   
        it "should return a token" do
          params = {
            :code => '4fa8182d7184797dd5000002',
            :client_id => @client.id,
            :client_secret => @client.secret,
            :redirect_uri => @client.redirect_uri,
            :grant_type => 'authorization_code'
          }
          post "/oauth2/pregen/token", params
          JSON.parse(last_response.body)["access_token"].should_not be_nil
        end
      end
    end
  end
end