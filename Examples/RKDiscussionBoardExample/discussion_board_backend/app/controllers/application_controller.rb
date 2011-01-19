class ApplicationController < ActionController::Base  
  protected  
    def user_access_token
      request.headers["HTTP_X_USER_ACCESS_TOKEN"] || request.headers["HTTP_USER_ACCESS_TOKEN"]
    end
  
    def current_user
      if token = user_access_token
        @user ||= User.find_by_single_access_token(token)
      end
    end
  
    def require_user    
      unless current_user
        render :json => {:error => "Invalid Access Token"}, :status => 401
      end
    end
  
    def require_owner
      unless current_user && current_user == object.user
        render :json => {:error => "Unauthorized"}
      end
    end
end
