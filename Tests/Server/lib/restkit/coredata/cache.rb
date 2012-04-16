module RestKit
  module CoreData
    class Cache < Sinatra::Base

      get '/coredata/etag' do
        tag = '2cdd0a2b329541d81e82ab20aff6281b'
        if tag == request.env["HTTP_IF_NONE_MATCH"]
          status 304
          ""
        else
          etag(tag)
          content_type 'application/json'
          send_file 'Tests/Server/../Fixtures/JSON/humans/all.json'
        end
      end
    end
  end
end
