class ActsAsUrlParam::FromMethodItem < ActsAsUrlParam::Item
  acts_as_url_param :from => :my_method
  
  def my_method
    "a-nice-name-for-you"
  end
end