class Topic < ActiveRecord::Base
  belongs_to :user
  has_many :posts
  
  validates_presence_of :name
  validates_presence_of :user
  
  delegate :username, :to => :user
end
