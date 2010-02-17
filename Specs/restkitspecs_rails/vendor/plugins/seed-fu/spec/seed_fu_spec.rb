require File.dirname(__FILE__) + '/spec_helper'

load(File.dirname(__FILE__) + '/schema.rb')

describe SeedFu::Seeder do
  it "should create a model if one doesn't exist" do
    SeededModel.seed(:id) do |s|
      s.id = 1
      s.login = "bob"
      s.first_name = "Bob"
      s.last_name = "Bobson"
      s.title = "Peon"
    end
    
    bob = SeededModel.find_by_id(1)
    bob.first_name.should == "Bob"
    bob.last_name.should == "Bobson"
  end
  
  it "should be able to handle multiple constraints" do
    SeededModel.seed(:title, :login) do |s|
      s.login = "bob"
      s.title = "Peon"
      s.first_name = "Bob"
    end
    
    SeededModel.count.should == 1
    
    SeededModel.seed(:title, :login) do |s|
      s.login = "frank"
      s.title = "Peon"
      s.first_name = "Frank"
    end
    
    SeededModel.count.should == 2
    
    SeededModel.find_by_login("bob").first_name.should == "Bob"
    SeededModel.seed(:title, :login) do |s|
      s.login = "bob"
      s.title = "Peon"
      s.first_name = "Steve"
    end
    SeededModel.find_by_login("bob").first_name.should == "Steve"
  end
  
  it "should be able to create models from an array of seed attributes" do
    SeededModel.seed_many(:title, :login, [
      {:login => "bob", :title => "Peon", :first_name => "Steve"},
      {:login => "frank", :title => "Peasant", :first_name => "Francis"},
      {:login => "harry", :title => "Noble", :first_name => "Harry"}
    ])
    
    SeededModel.find_by_login("bob").first_name.should == "Steve"
    SeededModel.find_by_login("frank").first_name.should == "Francis"
    SeededModel.find_by_login("harry").first_name.should == "Harry"
  end
  
  #it "should raise an error if constraints are not unique" do
  #  SeededModel.create(:login => "bob", :first_name => "Bob", :title => "Peon")
  #  SeededModel.create(:login => "bob", :first_name => "Robert", :title => "Manager")
  #  
  #  SeededModel.seed(:login) do |s|
  #    s.login = "bob"
  #    s.title = "Overlord"
  #  end
  #end
  
  it "should default to an id constraint"
  it "should update, not create, if constraints are met"
  it "should require that all constraints are defined"
  it "should raise an error if validation fails"
  it "should retain fields that aren't specifically altered in the seeding"
end