require 'rubygems'
require 'spec'
require 'active_record'
$: << File.join(File.dirname(__FILE__), "..", "lib")

class Employee < ActiveRecord::Base
  after_save :on_save_finished

  def on_save_finished
  end
end

RAILS_ROOT = "RAILS_ROOT"

describe "NullDB with no schema pre-loaded" do
  before :each do
    Kernel.stub!(:load)
    ActiveRecord::Migration.stub!(:verbose=)
  end

  it "should load RAILS_ROOT/db/schema.rb if no alternate is specified" do
    ActiveRecord::Base.establish_connection :adapter => :nulldb
    Kernel.should_receive(:load).with("RAILS_ROOT/db/schema.rb")
    ActiveRecord::Base.connection.columns('schema_info')
  end

  it "should load the specified schema relative to RAILS_ROOT" do
    Kernel.should_receive(:load).with("RAILS_ROOT/foo/myschema.rb")
    ActiveRecord::Base.establish_connection :adapter => :nulldb,
                                            :schema => "foo/myschema.rb"
    ActiveRecord::Base.connection.columns('schema_info')
  end

  it "should suppress migration output" do
    ActiveRecord::Migration.should_receive(:verbose=).with(false)
    ActiveRecord::Base.establish_connection :adapter => :nulldb,
                                            :schema => "foo/myschema.rb"
    ActiveRecord::Base.connection.columns('schema_info')
  end
end

describe "NullDB" do
  before :all do
    ActiveRecord::Base.establish_connection :adapter => :nulldb
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define do
      create_table(:employees) do |t|
        t.string  :name
        t.date    :hire_date
        t.integer :employee_number
        t.decimal :salary
      end

      add_fk_constraint "foo", "bar", "baz", "buz", "bungle"
      add_pk_constraint "foo", "bar", {}, "baz", "buz"
    end
  end

  before :each do
    @employee =  Employee.new(:name           => "John Smith",
                             :hire_date       => Date.civil(2000, 1, 1),
                             :employee_number => 42,
                             :salary          => 56000.00)
  end

  it "should enable instantiation of AR objects without a database" do
    @employee.should_not be_nil
    @employee.should be_a_kind_of(ActiveRecord::Base)
  end

  it "should remember columns defined in migrations" do
    should_have_column(Employee, :name, :string)
    should_have_column(Employee, :hire_date, :date)
    should_have_column(Employee, :employee_number, :integer)
    should_have_column(Employee, :salary, :decimal)
  end

  it "should enable simulated saving of AR objects" do
    lambda { @employee.save! }.should_not raise_error
  end

  it "should enable AR callbacks during simulated save" do
    @employee.should_receive(:on_save_finished)
    @employee.save
  end

  it "should enable simulated deletes of AR objects" do
    lambda { @employee.destroy }.should_not raise_error
  end

  it "should enable simulated creates of AR objects" do
    emp = Employee.create(:name => "Bob Jones")
    emp.name.should == "Bob Jones"
  end

  it "should generate new IDs when inserting unsaved objects" do
    cxn = Employee.connection
    id1 = cxn.insert("some sql", "SomeClass Create", "id", nil, nil)
    id2 = cxn.insert("some sql", "SomeClass Create", "id", nil, nil)
    id2.should == (id1 + 1)
  end

  it "should re-use object ID when inserting saved objects" do
    cxn = Employee.connection
    id1 = cxn.insert("some sql", "SomeClass Create", "id", 23, nil)
    id1.should == 23
  end

  it "should log executed SQL statements" do
    cxn = @employee.connection
    exec_count = cxn.execution_log.size
    @employee.save!
    cxn.execution_log.size.should == (exec_count + 1)
  end

  it "should have the adapter name 'NullDB'" do
    @employee.connection.adapter_name.should == "NullDB"
  end

  it "should support migrations" do
    @employee.connection.supports_migrations?.should be_true
  end

  it "should always have a schema_info table definition" do
    @employee.connection.tables.should include("schema_info")
  end

  it "should return an empty array from #select" do
    @employee.connection.select_all("who cares", "blah").should == []
  end

  it "should provide a way to set log checkpoints" do
    cxn = @employee.connection
    @employee.save!
    cxn.execution_log_since_checkpoint.size.should > 0
    cxn.checkpoint!
    cxn.execution_log_since_checkpoint.size.should == 0
    @employee.save!
    cxn.execution_log_since_checkpoint.size.should == 1
  end

  def should_contain_statement(cxn, entry_point)
    cxn.execution_log_since_checkpoint.should \
      include(ActiveRecord::ConnectionAdapters::NullDBAdapter::Statement.new(entry_point))
  end

  def should_not_contain_statement(cxn, entry_point)
    cxn.execution_log_since_checkpoint.should_not \
      include(ActiveRecord::ConnectionAdapters::NullDBAdapter::Statement.new(entry_point))
  end

  it "should tag logged statements with their entry point" do
    cxn = @employee.connection

    should_not_contain_statement(cxn, :insert)
    @employee.save
    should_contain_statement(cxn, :insert)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :update)
    @employee.save
    should_contain_statement(cxn, :update)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :delete)
    @employee.destroy
    should_contain_statement(cxn, :delete)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :select_all)
    Employee.find(:all)
    should_contain_statement(cxn, :select_all)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :select_value)
    Employee.count_by_sql("frobozz")
    should_contain_statement(cxn, :select_value)
  end

  it "should allow #finish to be called on the result of #execute" do
    @employee.connection.execute("blah").finish
  end

  def should_have_column(klass, col_name, col_type)
    col = klass.columns_hash[col_name.to_s]
    col.should_not be_nil
    col.type.should == col_type
  end
end
