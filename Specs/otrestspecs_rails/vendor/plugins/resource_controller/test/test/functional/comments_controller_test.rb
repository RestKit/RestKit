require File.dirname(__FILE__) + '/../test_helper'

class CommentsControllerTest < ActionController::TestCase
  def setup
    @comment = Comment.find 1
  end
  
  context "with parent post" do
    should_be_restful do |resource|
      resource.formats = [:html]
    
      resource.parent = :post
    end
  end
  
  should_be_restful do |resource|
    resource.formats = [:html]
  end
end
