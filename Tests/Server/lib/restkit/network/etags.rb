module RestKit
  module Network
    class ETags < Sinatra::Base

      get '/etags' do
        "Success!"
      end

      get '/etags/cached' do
        tag = "686897696a7c876b7e"
        if tag == request.env["HTTP_IF_NONE_MATCH"]
          status 304
          ""
        else
          headers "ETag" => tag
          "This Should Get Cached"
        end
      end

    end
  end
end
