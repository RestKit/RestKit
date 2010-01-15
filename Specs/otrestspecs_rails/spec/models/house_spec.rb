require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe House do
  before(:each) do
    @valid_attributes = {
      :street => "value for street",
      :city => "value for city",
      :state => "value for state",
      :zip => "value for zip",
      :owner_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    House.create!(@valid_attributes)
  end
end
