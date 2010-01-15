require File.dirname(__FILE__) + '/../test_helper'

class PeopleControllerTest < ActionController::TestCase
  def setup
    @person = accounts :one
  end

  should_be_restful do |resource|
    resource.formats = [:html]
    resource.klass   = Account
    resource.object  = :person
    
    resource.create.redirect = 'person_url(@person)'
    resource.update.redirect = 'person_url(@person)'
    resource.destroy.redirect = 'people_url'
  end
  
  context "before create" do
    setup do
      post :create, :person => {}
    end

    should "name account Bob Loblaw" do
      assert_equal "Bob Loblaw", assigns(:person).name
    end
  end
end
