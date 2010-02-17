require 'custom_error_message'

ActiveRecord::Errors.send(:include, CustomErrorMessage)
ActiveResource::Errors.send(:include, CustomErrorMessage)