require File.expand_path(File.dirname(__FILE__)) + '/server'

map '/' do
  run RestKitTestServer
end