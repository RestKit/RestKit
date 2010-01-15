# Expose a shared behaviour for disconnecting specs
share_as :Disconnected do
  include NullDB::RSpec::NullifiedDatabase
end
