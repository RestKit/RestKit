require File.dirname(__FILE__) + '/../test_helper'

class SomethingsControllerTest < ActionController::TestCase
  def setup
    @something = somethings :one
  end

  context "actions specified" do
    [:create, :edit, :update, :destroy, :new].each do |action|
      should "not respond to #{action}" do
        assert !@controller.respond_to?(action)
      end
    end
  end
  
  should_be_restful do |resource|
    resource.formats = [:html]
    
    resource.actions = [:index, :show]
  end
end
