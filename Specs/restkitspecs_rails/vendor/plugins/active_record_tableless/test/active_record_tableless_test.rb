require 'test/unit'
require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + '/../lib/active_record/tableless'



ActiveRecord::Base.establish_connection(  {
  :adapter => 'sqlite3',
  :database => ":memory:",
  :timeout => 500
  
})

ActiveRecord::Base.send(:include, ActiveRecord::Tableless)

class TablelessModel < ActiveRecord::Base
  tableless :columns => [
                [:email, :string],
                [:password, :string],
                [:password_confirmation] ]
  
  validates_presence_of     :email, :password, :password_confirmation
  validates_confirmation_of :password
  
end

class ActiveRecordTablelessTest < Test::Unit::TestCase
  
  def setup
    super
    @valid_attributes = {
      :email => "robin@bogus.com", 
      :password => "password", 
      :password_confirmation => "password"
    }
  end
  
  def test_create
    assert TablelessModel.create(@valid_attributes).valid?
  end
  
  def test_validations
    # Just check a few validations to make sure we didn't break ActiveRecord::Validations::ClassMethods
    assert_not_nil TablelessModel.create(@valid_attributes.merge(:email => "")).errors[:email]
    assert_not_nil TablelessModel.create(@valid_attributes.merge(:password => "")).errors[:password]
    assert_not_nil TablelessModel.create(@valid_attributes.merge(:password_confirmation => "")).errors[:password]
  end
  
  def test_save
    assert TablelessModel.new(@valid_attributes).save 
    assert !TablelessModel.new(@valid_attributes.merge(:password => "no_match")).save 
  end
  
  def test_valid?
    assert TablelessModel.new(@valid_attributes).valid? 
    assert !TablelessModel.new(@valid_attributes.merge(:password => "no_match")).valid? 
  end
  
  
  def test_exists!
    m = TablelessModel.new(@valid_attributes)
    
    assert_nil m.id 
    assert m.new_record?
    
    m.exists!
    assert_equal 1, m.id 
    assert !m.new_record?
    
    m.exists!(250)
    assert_equal 250, m.id 
    assert !m.new_record?
  end
end
