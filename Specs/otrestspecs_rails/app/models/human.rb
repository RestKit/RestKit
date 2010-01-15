class Human < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name, :with => /[\w]+/
  
  validates_format_of :nick_name, :with => /[\w]+/, :allow_nil => true
  
  validates_presence_of :birthday
  
  attr_protected :age
  validates_presence_of :age
  before_validation :calculate_age_from_birthday
  
  validates_inclusion_of :sex, :in => %w{male female}
  
  has_many :cats
  
  private
    def calculate_age_from_birthday
      if birthday
        date = Date.today
        day_diff = date.day - birthday.day
        month_diff = date.month - birthday.month - (day_diff < 0 ? 1 : 0)
        self.age = date.year - birthday.year - (month_diff < 0 ? 1 : 0)
      end
    end
end
