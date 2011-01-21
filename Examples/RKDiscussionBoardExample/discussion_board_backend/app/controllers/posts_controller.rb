class PostsController < ApplicationController
  resource_controller
  
  belongs_to :topic
  
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :require_owner, :only => [:update, :destroy]
  
  index.response do |wants|
    wants.json{ render :json => collection.to_json(:methods => :attachment_path, :include => :user) }
  end
  create.response do |wants|
    wants.json{ render :json => object.to_json(:methods => :attachment_path, :include => :user) }
  end
  update.response do |wants|
    wants.json{ render :json => object.to_json(:methods => :attachment_path, :include => :user) }
  end
  destroy.response do |wants|
    wants.json{ render :json => {} }
  end
  show.response do |wants|
    wants.json{ render :json => object.to_json(:methods => :attachment_path, :include => :user) }
  end
  
  create.before do
    object.user = current_user
  end
end
