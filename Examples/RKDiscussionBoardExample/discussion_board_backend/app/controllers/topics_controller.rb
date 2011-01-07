class TopicsController < ApplicationController
  resource_controller
  protect_from_forgery :except => [:create, :update, :destroy]
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :requre_owner, :only => [:update, :destroy]
  
  index.response do |wants|
    wants.js { render :json => collection }
  end
  create.response do |wants|
    wants.js { render :json => object }
  end
  update.response do |wants|
    wants.js { render :json => object }
  end
  destroy.response do |wants|
    wants.js { render :json => {} }
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
