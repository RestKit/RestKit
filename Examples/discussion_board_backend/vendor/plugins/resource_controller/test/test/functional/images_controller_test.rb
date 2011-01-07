require File.dirname(__FILE__) + '/../test_helper'

class ImagesControllerTest < ActionController::TestCase
  def setup
    @image = images :one
  end

  context "with user as parent" do
    
    context "on post to :create" do
      setup do
        post :create, :user_id => 1, :photo => {}
      end

      should_redirect_to 'user_image_path(@image.user)'
      should_assign_to :image
      should_assign_to :user
      should "scope image to user" do
        assert users(:one), assigns(:image).user
      end
    end
    
  end  
  
  should "not respond to show" do
    assert_raise(ActionController::UnknownAction) do
      get :show
    end
  end
end
