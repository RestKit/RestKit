require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "to_json should only include basic attributes" do
    user = User.new(:username => 'restkit', :email => 'restkit@restkit.org')
    attributes = ActiveSupport::JSON.decode(user.to_json)['user']
    puts attributes.inspect
  end
end
