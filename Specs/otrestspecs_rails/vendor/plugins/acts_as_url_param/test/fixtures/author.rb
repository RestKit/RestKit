class ActsAsUrlParam::Author < ActsAsUrlParamBase
  acts_as_url_param :on => :update, :allow_blank => true
end