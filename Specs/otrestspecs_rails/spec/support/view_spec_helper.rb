module ViewSpecHelper
  
  def page_title
    assigns[:content_for_page_title]
  end
  
  def stub_authentication_logged_in!
    template.stub!(:logged_in?).and_return(true)
    activate_authlogic
    @user = Factory(:user)
    UserSession.create(@user)
    template.stub!(:current_user).and_return(@user)
  end
  
  # Authenticate the Spec harness
  def stub_current_user!
    @user = Factory.build(:user, :admin => false)
    template.stub!(:current_user).and_return(@user)
    @user
  end
  
  def stub_admin_user!
    @user = Factory.build(:user, :admin => true)
    template.stub!(:current_user).and_return(@user)
    @user    
  end
  
  def content_for(name)
    response.template.instance_variable_get("@content_for_#{name}")
  end
  
end
