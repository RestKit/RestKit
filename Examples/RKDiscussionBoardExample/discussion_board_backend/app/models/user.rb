class User < ActiveRecord::Base
  acts_as_authentic
  validates_presence_of :login
  validates_presence_of :email
  
end
