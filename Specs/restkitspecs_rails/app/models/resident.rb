class Resident < ActiveRecord::Base
  belongs_to :house  
  belongs_to :resideable, :polymorphic => true
  
  validates_presence_of :house
  validates_presence_of :resideable
  
  validates_uniqueness_of [:resideable_type, :resideable_id], :scope => :house_id
  
  def to_xml(options = {})
    super(options.merge(:include => :resideable))
  end
end
