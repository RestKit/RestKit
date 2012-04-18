module RestKit
  module Network
    class Redirection < Sinatra::Base
      get '/redirection' do
        [302, {"Location" => '/redirection/target'}, ""]
      end
    
      get '/redirection/target' do
        [200, {"Content-Type" => "application/json"}, {"redirected" => true}.to_json]
      end
    end
  end  
end