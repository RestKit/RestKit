class ActsAsUrlParam::User < ActsAsUrlParamBase
  acts_as_url_param :from => :login
end