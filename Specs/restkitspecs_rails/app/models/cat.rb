class Cat < ActiveRecord::Base
  belongs_to :human
  validates_presence_of :human
  
  validates_presence_of :name
  validates_format_of :name, :with => /[\w]+/
  
  validates_format_of :nick_name, :with => /[\w]+/, :allow_nil => true
  
  validates_presence_of :birth_year
  
  attr_protected :age
  validates_presence_of :age
  before_validation :calculate_age_from_birth_year
  
  validates_inclusion_of :sex, :in => %w{male female}
  
  private
    def calculate_age_from_birth_year
      if birth_year
        birthday = Date.parse("1/1/#{birth_year}")
        date = Date.today
        day_diff = date.day - birthday.day
        month_diff = date.month - birthday.month - (day_diff < 0 ? 1 : 0)
        self.age = date.year - birthday.year - (month_diff < 0 ? 1 : 0)
      end
    end
end
