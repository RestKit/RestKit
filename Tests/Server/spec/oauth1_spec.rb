require File.dirname(__FILE__) + "/spec_helper"
require 'simple_oauth'

describe "OAuth1" do
  def app
    Rack::Builder.parse_file(File.dirname(__FILE__) + "/../server.ru").first
  end

  before(:all) do
    @oauth = {
      :token => "12345",
      :consumer_key => "restkit",
      :consumer_secret => "restkit_secret",
      :token_secret => "monkey"
    }
  end
  
  def header_without(key = nil)
    oauth_header = SimpleOAuth::Header.new(:get, "http://example.org/oauth1/me", nil, @oauth)
    attributes = oauth_header.signed_attributes.clone
    attributes.delete key if key
    "OAuth " + attributes.sort_by{|k,v| k.to_s }.map{|k,v| %(#{k}="#{SimpleOAuth::Header.encode(v)}") }.join(', ')
  end
  
  context "Dispatching a valid OAuth1.0a header" do
    it "should succeed" do
      header 'Authorization', header_without(nil)
      get "/oauth1/me"
      
      last_response.should be_successful
    end
  end
  
  context "Dispatching an invalid OAuth1.0a header" do
    context "without a consumer key" do
      it "should fail" do
        header 'Authorization', header_without(:oauth_consumer_key)
        get "/oauth1/me"

        last_response.status.should eq 400
        last_response.body.should eq "Bad request. No consumer key provided."
      end
    end
    
    context "without a signature" do
      it "should fail" do
        header 'Authorization', header_without(:oauth_signature)
        get "/oauth1/me"

        last_response.status.should eq 400
        last_response.body.should eq "Bad request. No signature provided."
      end
    end
    
    context "without a signature method" do
      it "should fail" do
        header 'Authorization', header_without(:oauth_signature_method)
        get "/oauth1/me"

        last_response.status.should eq 400
        last_response.body.should eq "Bad request. No signature method provided."
      end
    end
    
    context "without a header at all" do
      it "should fail" do
        get "/oauth1/me"

        last_response.status.should eq 400
        last_response.body.should eq "Bad request."
      end
    end
  end
  
end