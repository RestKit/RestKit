class UsersController < ApplicationController
  protect_from_forgery :except => [:login, :signup]
  
  def login
    # this method logs you in and returns you a single_access_token token for authentication.
    user_session = UserSession.new(params)
    if user_session.save
      user = user_session.user
      render :json => {:login => user.login, :single_access_token => user.single_access_token, :user_id => user.id}
    else
      render :json => {:error => "Invalid Login"}
    end
  end
  
  def signup
    user = User.new(params[:user])
    if user.save
      render :json => {:login => user.login, :single_access_token => user.single_access_token, :user_id => user.id}
    else
      render :json => {:errors => user.errors.full_messages}
    end
  end
  
end
