class ActsAsUrlParam::BeforeItem < ActsAsUrlParam::Item
  acts_as_url_param :before => :set_name
  
  def set_name
    self.name += " is set"
  end
end
