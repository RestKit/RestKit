class PostsController < ApplicationController
  resource_controller
  belongs_to :topic
  
  protect_from_forgery :except => [:create, :update, :destroy]
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :requre_owner, :only => [:update, :destroy]
  
  index.response do |wants|
    wants.json{ render :json => collection.to_json(:methods => [:attachment_path, :user_login]) }
  end
  create.response do |wants|
    wants.json{ render :json => object.to_json(:methods => [:attachment_path, :user_login]) }
  end
  update.response do |wants|
    wants.json{ render :json => object.to_json(:methods => [:attachment_path, :user_login]) }
  end
  destroy.response do |wants|
    wants.json{ render :json => {} }
  end
  show.response do |wants|
    wants.json{ render :json => object.to_json(:methods => [:attachment_path, :user_login]) }
  end
  
  create.before do
    object.user = @user
  end
  
  protected
  
  def requre_owner
    unless @user == object.user
      render :json => {:error => "Unauthorized"}
    end
  end
  
  
end
