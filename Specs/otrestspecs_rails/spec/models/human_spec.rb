require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Human do
  it do
    should validate_presence_of(:name)
  end
  
  it do
    should validate_format_of(:name).with(/[\w]+/)
  end
  
  it do
    should validate_presence_of(:birthday)
  end
  
  it do
    should validate_presence_of(:age)
  end
  
  it "should calculate age" do
    human = Factory(:human, :birthday => '11/27/1982')
    human.age.should == 27
  end
  
  it "should require the sex to be male or female" do
    human = Human.new(:sex => 'monster')
    human.valid?
    human.should have(1).error_on(:sex)
    human.errors.on(:sex).should == 'is not included in the list'
  end
end
