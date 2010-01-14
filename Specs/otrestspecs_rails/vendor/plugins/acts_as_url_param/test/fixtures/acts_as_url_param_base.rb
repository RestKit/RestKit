# Namespace models
module ActsAsUrlParam
end

class ActsAsUrlParamBase < ActiveRecord::Base
  self.abstract_class = true
  self.connection = ACTS_AS_URL_PARAM_TEST_DB
end