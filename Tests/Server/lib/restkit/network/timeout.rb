module RestKit
  module Network
    class Timeout < Sinatra::Base

      get '/disk/cached' do
        "This Should Get Cached For 5 Seconds"
      end

    end
  end
end
