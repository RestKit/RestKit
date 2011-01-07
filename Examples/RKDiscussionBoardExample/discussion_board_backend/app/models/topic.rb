class Topic < ActiveRecord::Base
  belongs_to :user
  has_many :posts
end
