require File.dirname(__FILE__) + '/spec_helper'
require 'active_record'
require 'custom_error_message'
require 'action_controller'

include ActionView::Helpers::ActiveRecordHelper
include ActionView::Helpers::TextHelper
include ActionView::Helpers::TagHelper

def create_ar_object_that_validates_presence_of(field, message)
  test_model_class = Class.new(ActiveRecord::Base) do
    validates_presence_of field, :message => message

    #to avoid hitting the db
    class_methods = Module.new do
      define_method :columns do
        [ActiveRecord::ConnectionAdapters::Column.new(field.to_s, nil, 'string', false)]
      end
    end
    extend class_methods
  end
  return test_model_class.new
end

def create_ar_object_with_columns(*cols)
  ar_class = Class.new(ActiveRecord::Base) do
    class_methods = Module.new do
      define_method :columns do
        cols.inject([]) do |array, column|
          array << ActiveRecord::ConnectionAdapters::Column.new(column.to_s, nil, 'string', false)
        end
      end
    end
    extend class_methods
  end
  return ar_class.new
end

describe 'custom_err_msg with a declarative validation' do
  it 'without circumflex should not change behaviour' do
    @rec = create_ar_object_that_validates_presence_of :email, 'is not present'
    @rec.valid?
    error_messages_for(:object => @rec).should match(/Email is not present/)
  end

  it 'with circumflex in the beginning should show only the message' do
    @rec = create_ar_object_that_validates_presence_of :email, '^The email is missing'
    @rec.valid?
    error_messages_for(:object => @rec).should match(/>The email is missing/)
  end

  it 'with a proc should show procs result' do
    @rec = create_ar_object_that_validates_presence_of :email, Proc.new { "You forgot the email" }
    @rec.valid?
    error_messages_for(:object => @rec).should match(/>You forgot the email/)
  end

  it 'with circumflex not in the beginning should leave original behaviour' do
    @rec = create_ar_object_that_validates_presence_of :email, 'is not ^ present'
    @rec.valid?
    error_messages_for(:object => @rec).should match(/Email is not \^ present/)
  end
end

describe 'custom_err_msg using the errors.add method' do
  
  before :each do
    @rec = create_ar_object_with_columns :name
  end
 
  it 'query of error without circumflex should not change behaviour' do
    @rec.errors.add(:name, 'is too long')
    @rec.errors.on(:name).should == 'is too long'
  end

  it 'added error without circumflex should not change behaviour' do
    @rec.errors.add(:name, 'is too long')
    error_messages_for(:object => @rec).should match(/Name is too long/)
  end

  it 'query of error with circumflex should show the message' do
    @rec.errors.add(:name, '^You forgot the name')
    @rec.errors.on(:name).should == '^You forgot the name'
  end

  it 'added error with circumflex should only show the message' do
    @rec.errors.add(:name, '^You forgot the name')
    error_messages_for(:object => @rec).should match(/>You forgot the name/)
  end

  it 'can specify error message as a proc' do
    @rec.name = 'Bobby'
    @rec.errors.add(:name, Proc.new {|ar| "#{ar.name} is an ugly name"})
    error_messages_for(:object => @rec).should match(/>Bobby is an ugly name/)
  end

  it 'should handle correctly a field with one normal, one circumflex based and one proc based error message' do
    @rec.name = 'Bobby'
    @rec.errors.add(:name, '^You forgot the name')
    @rec.errors.add(:name, 'is not pretty')
    @rec.errors.add(:name, Proc.new {|ar| "#{ar.name} is an ugly name"})

    error_messages_for(:object => @rec).should match(/>You forgot the name/)
    error_messages_for(:object => @rec).should match(/Name is not pretty/)
    error_messages_for(:object => @rec).should match(/>Bobby is an ugly name/)
  end
end

