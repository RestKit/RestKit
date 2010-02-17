class ActsAsUrlParam::BlogPost < ActsAsUrlParamBase
  acts_as_url_param do |candidate|
    url_param_available_for_model?(candidate) &&
    Story.url_param_available?(candidate)
  end
end