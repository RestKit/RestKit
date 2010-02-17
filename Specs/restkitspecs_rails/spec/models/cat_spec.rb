require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cat do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :nick_name => "value for nick_name",
      :birth_year => 1,
      :age => 1,
      :color => "value for color",
      :human_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Cat.create!(@valid_attributes)
  end
end
