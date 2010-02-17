require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Resident do
  before(:each) do
    @valid_attributes = {
      :house_id => 1,
      :resideable_type => "value for resideable_type",
      :resideable_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Resident.create!(@valid_attributes)
  end
end
