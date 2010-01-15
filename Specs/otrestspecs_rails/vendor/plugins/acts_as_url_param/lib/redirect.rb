# redirectable_type
# redirectable_id
# redirectable_class
# name

class Redirect < ActiveRecord::Base
  belongs_to :redirectable, :polymorphic => true
  before_create :set_real_class
  
  validates_presence_of :url_name
  
  def self.find_by_class_and_name(klass,name)
    find(:first, :conditions => ["redirectable_class = ? AND url_name = ?", klass.to_s, name], :order => "created_at desc")
  end
  
  def to_label
    url_name
  end
  
  private
  def set_real_class
    self.redirectable_class = redirectable.class.to_s
  end
end
