class User < ActiveRecord::Base
  acts_as_authentic

  validates_presence_of :username
  validates_presence_of :email
  
  def to_json(options = {})
    super(options.reverse_merge(:only => [:username, :id, :email]))
  end
end
