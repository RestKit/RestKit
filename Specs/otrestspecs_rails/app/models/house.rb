class House < ActiveRecord::Base
  belongs_to :owner, :class_name => 'Human'
  has_many :residents
  has_many :residables, :through => :residents
  
  validates_presence_of :street
  validates_uniqueness_of :street
  
  validates_presence_of :city
  validates_presence_of :state
  
  validates_presence_of :zip
  validates_numericality_of :zip
  
  validates_presence_of :owner_id
end
