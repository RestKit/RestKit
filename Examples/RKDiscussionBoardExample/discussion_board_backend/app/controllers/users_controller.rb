class UsersController < ApplicationController  
  def create
    @user = User.new(params[:user])
    if @user.save
      render :json => {:username => @user.username, :single_access_token => @user.single_access_token, :id => @user.id, :email => @user.email}
    else
      render :json => {:errors => @user.errors.full_messages}, :status => 422
    end
  end  
end
