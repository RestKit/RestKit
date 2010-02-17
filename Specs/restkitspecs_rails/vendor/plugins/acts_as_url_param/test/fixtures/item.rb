class ActsAsUrlParam::Item < ActsAsUrlParamBase
  acts_as_url_param :scope => "items.type != 'Newspaper'", :redirectable => true
end