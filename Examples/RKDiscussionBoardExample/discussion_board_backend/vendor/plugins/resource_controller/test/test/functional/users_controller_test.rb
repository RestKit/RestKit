require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @dude = accounts :one
  end

  should_be_restful do |resource|
    resource.formats = [:html]
    resource.klass   = Account
    resource.object  = :dude
    
    resource.create.redirect = 'dude_url(@dude)'
    resource.update.redirect = 'dude_url(@dude)'
    resource.destroy.redirect = 'dudes_url'
  end  
end
