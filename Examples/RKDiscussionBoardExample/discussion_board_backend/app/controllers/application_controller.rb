class ApplicationController < ActionController::Base
  protect_from_forgery
  
  protected
  
  def require_user
    # Look for the correct headers
    token = request.headers["HTTP_USER_ACCESS_TOKEN"]
    @user = User.find_by_single_access_token(token)
    if @user.nil?
      render :json => {:error => "Invalid Access Token"}
    end
  end
  
end
