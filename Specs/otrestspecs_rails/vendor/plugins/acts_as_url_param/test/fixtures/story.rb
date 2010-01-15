class ActsAsUrlParam::Story < ActsAsUrlParamBase
  acts_as_url_param :story_url, :allow_blank => true
end