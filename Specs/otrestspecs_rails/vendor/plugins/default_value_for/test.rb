# Copyright (c) 2008, 2009 Phusion
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rubygems'
require 'active_record'
require 'test/unit'
require File.dirname(__FILE__) + '/init'
Dir.chdir(File.dirname(__FILE__))

if RUBY_PLATFORM == "java"
	database_adapter = "jdbcsqlite3"
else
	database_adapter = "sqlite3"
end

File.unlink('test.sqlite3') rescue nil
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Base.establish_connection(
	:adapter => database_adapter,
	:database => 'test.sqlite3'
)
ActiveRecord::Base.connection.create_table(:users, :force => true) do |t|
	t.string :username
	t.integer :default_number
end
ActiveRecord::Base.connection.create_table(:numbers, :force => true) do |t|
	t.string :type
	t.integer :number
	t.integer :count, :null => false, :default => 1
	t.integer :user_id
	t.timestamp :timestamp
end

class User < ActiveRecord::Base
	has_many :numbers, :class_name => 'TestClass'
end

class Number < ActiveRecord::Base
end

class DefaultValuePluginTest < Test::Unit::TestCase
	def setup
		Number.create(:number => 9876)
	end
	
	def teardown
		Number.delete_all
	end
	
	def define_model_class(name = "TestClass", parent_class_name = "ActiveRecord::Base", &block)
		Object.send(:remove_const, name) rescue nil
		eval("class #{name} < #{parent_class_name}; end", TOPLEVEL_BINDING)
		klass = eval(name, TOPLEVEL_BINDING)
		klass.class_eval do
			set_table_name 'numbers'
		end
		klass.class_eval(&block) if block_given?
	end
	
	def test_default_value_can_be_passed_as_argument
		define_model_class do
			default_value_for(:number, 1234)
		end
		object = TestClass.new
		assert_equal 1234, object.number
	end
	
	def test_default_value_can_be_passed_as_block
		define_model_class do
			default_value_for(:number) { 1234 }
		end
		object = TestClass.new
		assert_equal 1234, object.number
	end
	
	def test_works_with_create
		define_model_class do
			default_value_for :number, 1234
		end
		TestClass.create
		assert_not_nil TestClass.find_by_number(1234)
	end
	
	def test_overwrites_db_default
		define_model_class do
			default_value_for :count, 1234
		end
		object = TestClass.new
		assert_equal 1234, object.count
	end
	
	def test_doesnt_overwrite_values_provided_by_mass_assignment
		define_model_class do
			default_value_for :number, 1234
		end
		object = TestClass.new(:number => 1, :count => 2)
		assert_equal 1, object.number
	end
  
	def test_doesnt_overwrite_values_provided_by_multiparameter_assignment
		define_model_class do
			default_value_for :timestamp, Time.mktime(2000, 1, 1)
		end
		timestamp = Time.mktime(2009, 1, 1)
		object = TestClass.new('timestamp(1i)' => '2009', 'timestamp(2i)' => '1', 'timestamp(3i)' => '1')
		assert_equal timestamp, object.timestamp
	end
	
	def test_doesnt_overwrite_values_provided_by_constructor_block
		define_model_class do
			default_value_for :number, 1234
		end
		object = TestClass.new do |x|
			x.number = 1
			x.count = 2
		end
		assert_equal 1, object.number
	end
	
	def test_doesnt_overwrite_explicitly_provided_nil_values_in_mass_assignment
		define_model_class do
			default_value_for :number, 1234
		end
		object = TestClass.new(:number => nil)
		assert_nil object.number
	end
	
	def test_default_values_are_inherited
		define_model_class("TestSuperClass") do
			default_value_for :number, 1234
		end
		define_model_class("TestClass", "TestSuperClass")
		object = TestClass.new
		assert_equal 1234, object.number
	end
	
	def test_doesnt_set_default_on_saved_records
		define_model_class do
			default_value_for :number, 1234
		end
		assert_equal 9876, TestClass.find(:first).number
	end
	
	def test_also_works_on_attributes_that_arent_database_columns
		define_model_class do
			default_value_for :hello, "hi"
			attr_accessor :hello
		end
		object = TestClass.new
		assert_equal 'hi', object.hello
	end
	
	def test_constructor_ignores_forbidden_mass_assignment_attributes
		define_model_class do
			default_value_for :number, 1234
			attr_protected :number
		end
		object = TestClass.new(:number => 5678, :count => 987)
		assert_equal 1234, object.number
		assert_equal 987, object.count
	end
	
	def test_doesnt_conflict_with_overrided_initialize_method_in_model_class
		define_model_class do
			def initialize(attrs = {})
				@initialized = true
				super(:count => 5678)
			end
			
			default_value_for :number, 1234
		end
		object = TestClass.new
		assert_equal 1234, object.number
		assert_equal 5678, object.count
		assert object.instance_variable_get('@initialized')
	end
	
	def test_model_instance_is_passed_to_the_given_block
		$instance = nil
		define_model_class do
			default_value_for :number do |n|
				$instance = n
			end
		end
		object = TestClass.new
		assert_same object, $instance
	end
	
	def test_can_specify_default_value_via_association
		user = User.create(:username => 'Kanako', :default_number => 123)
		define_model_class do
			belongs_to :user
			
			default_value_for :number do |n|
				n.user.default_number
			end
		end
		object = user.numbers.create
		assert_equal 123, object.number
	end
	
	def test_default_values
		define_model_class do
			default_values :type => "normal",
			               :number => lambda { 10 + 5 }
		end
		
		object = TestClass.new
		assert_equal("normal", object.type)
		assert_equal(15, object.number)
	end
	
	def test_default_value_order
		define_model_class do
			default_value_for :count, 5
			default_value_for :number do |this|
				this.count * 2
			end
		end
		object = TestClass.new
		assert_equal(5, object.count)
		assert_equal(10, object.number)
	end
	
	def test_attributes_with_default_values_are_not_marked_as_changed
		define_model_class do
			default_value_for :count, 5
			default_value_for :number, 2
		end
		
		object = TestClass.new
		assert(!object.changed?)
		assert_equal([], object.changed)
		
		object.type = "foo"
		assert(object.changed?)
		assert_equal(["type"], object.changed)
	end
	
	def test_default_values_are_not_duplicated
		define_model_class do
			set_table_name "users"
			default_value_for :username, "hello"
		end
		user1 = TestClass.new
		user1.username << " world"
		user2 = TestClass.new
		assert_equal("hello world", user2.username)
	end
	
	def test_constructor_does_not_affect_the_hash_passed_to_it
		define_model_class do
			default_value_for :count, 5
		end
		
		options = { :count => 5, :user_id => 1 }
		options_dup = options.dup
		object = TestClass.new(options)
		assert_equal(options_dup, options)
	end
end
