require File.dirname(__FILE__) + '/../test_helper'

class ProjectsControllerTest < ActionController::TestCase
  def setup
    @project = projects :one
  end

  should_be_restful do |resource|
    resource.formats = [:html]
  end

  context "on DELETE to :destroy that fails" do
    setup do
      Project.any_instance.stubs(:destroy).returns(false)
      delete :destroy, :id => @project.to_param
    end

    should_respond_with :redirect
    should_redirect_to "project_url(@project)"
  end
end
