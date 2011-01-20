class SessionsController < ApplicationController
  def create
    # this method logs you in and returns you a single_access_token token for authentication.
    @user_session = UserSession.new(params[:user])
    if @user_session.save
      @user = @user_session.user
      render :json => {:username => @user.username, :single_access_token => @user.single_access_token, :id => @user.id, :email => @user.email}
    else
      render :json => {:errors => ["Invalid username or password"]}, :status => 401
    end
  end
  
  def destroy    
    if current_user
      current_user.update_attributes!(:single_access_token => nil)
    end
    render :json => {:user => {:single_access_token => nil}}, :status => :ok
  end
end
