require File.expand_path(File.dirname(__FILE__) + "/test_helper")
require "mocha"

require "acts_as_url_param_base"
require "author"
require "blog_post"
require "item"
require "book"
require "magazine"
require "newspaper"
require "user"
require "story"
require "before_item"
require "scoped_item"
require "from_method_item"

class ActsAsUrlParamTest < Test::Unit::TestCase
  
  def test_should_define_finder
    item = ActsAsUrlParam::Item.create(:name => 'just try and find me')
    assert_equal item, ActsAsUrlParam::Item.find_by_url(item.to_param)
  end
  
  def test_should_set_url_name_on_create
    assert !ActsAsUrlParam::Item.create(:name => 'test a url param').url_name.blank?
  end
  
  def test_should_not_set_url_name_if_already_set
    item = ActsAsUrlParam::Item.create(:name => 'test a url param', :url_name => 'test-this')
    assert_equal('test-this', item.to_param)
  end
  
  def test_should_make_manually_set_urls_safe
    item = ActsAsUrlParam::Item.create(:name => 'test a manual url param', :url_name => 'test this one')
    assert_equal('test-this-one', item.to_param)
  end
  
  def test_should_set_url_name_if_blank
    item = ActsAsUrlParam::Item.create(:name => 'no url param')
    item.send(:write_attribute, :url_name, nil)
    item.save
    assert item.url_name
  end
  
  def test_should_make_custom_urls_safe
    ActsAsUrlParam::Item.any_instance.expects(:url_safe)
    ActsAsUrlParam::Item.new(:url_name => 'make me safe')
  end
  
  def test_should_use_correct_column_to_create_url_name
    assert ActsAsUrlParam::User.create(:name => 'john doe', :login => 'jdog').url_name =~ /jdog/
  end
  
  def test_should_be_invalid_without_content_to_create_url
    user = ActsAsUrlParam::User.create(:name => 'john doe')
    assert !user.valid?
  end
  
  def test_should_allow_blank_url_param_if_specified
    item = ActsAsUrlParam::Story.create
    assert item.valid?
  end
  
  def test_should_check_if_url_param_available
    ActsAsUrlParam::User.create(:login => 'tester')
    assert !ActsAsUrlParam::User.url_param_available?('tester')
    assert ActsAsUrlParam::User.url_param_available?('goodman')
  end
  
  def test_should_use_block_to_check_if_url_param_available
    ActsAsUrlParam::Story.create!(:title => 'new post')
    assert !ActsAsUrlParam::BlogPost.url_param_available?('new-post')
  end
  
  def test_should_use_block_to_compute_url_name
    post = ActsAsUrlParam::BlogPost.new(:title => 'post')
    assert_equal 'post', post.compute_url_param
    story = ActsAsUrlParam::Story.create(:title => 'new post')
    new_post = ActsAsUrlParam::BlogPost.new(:title => 'new post')
    assert_not_equal new_post.compute_url_param, story.to_param
  end
  
  def test_should_create_redirect_trail
    name = "this is a redirectable item"
    item = ActsAsUrlParam::Item.create(:name => name)
    url = item.url_name
    assert_equal 0, item.redirects.size
    item.update_attributes :name => "redirect to me"
    assert_equal 1, item.redirects.count
    assert_equal url, item.redirects.first.url_name
  end
  
  def test_should_create_redirect_trail_with_manual_url
    name = "this is another redirectable item"
    item = ActsAsUrlParam::Item.create(:name => name)
    url = item.url_name
    assert_equal 0, item.redirects.size
    item.update_attributes :url_name => "a-new-url-for-you"
    assert_equal 1, item.redirects.count
    assert_equal url, item.redirects.first.url_name
  end
  
  def test_should_find_from_url_trail
    name = "this is a redirectable item"
    item = ActsAsUrlParam::Item.create(:name => name)
    url = item.url_name
    item.update_attributes :name => "redirect to me"
    assert item.to_param != url
    assert_equal item, ActsAsUrlParam::Item.find_redirect(url)
  end
  
  def test_should_check_redirects_table_for_available_names
    name = "this is a redirectable item"
    item = ActsAsUrlParam::Book.create(:name => name)
    url = item.url_name
    item.update_attributes(:name => "second one")
    assert !ActsAsUrlParam::Book.url_param_available?(url)
    assert ActsAsUrlParam::Magazine.url_param_available?(url)
  end
  
  def test_should_compute_url_name
    name = 'this is a url param'
    item = ActsAsUrlParam::Item.new(:name => name)
    assert !ActsAsUrlParam::Item.compute_url_param(name).blank?
    assert_equal(item.compute_url_param, ActsAsUrlParam::Item.compute_url_param(name))
  end
  
  def test_should_update_url_name_on_custom_callback
    author = ActsAsUrlParam::Author.create(:label => 'name of author')
    author_url = author.to_param
    author.update_attributes(:label => 'a new author')
    assert_not_equal(author_url, author.to_param)
  end
  
  def test_should_not_update_url_name_on_custom_callback_when_no_change
    author = ActsAsUrlParam::Author.create(:label => 'name of author')
    author_url = author.to_param
    author.update_attributes(:bio => 'unrelated to url param')
    assert_equal(author_url, author.to_param)
  end
  
  def test_should_not_set_existing_url_name_to_blank
    author = ActsAsUrlParam::Author.create(:label => 'name of author')
    author_url = author.to_param
    author.update_attributes(:label => '')
    assert_equal(author_url, author.to_param)
  end

  def test_should_not_update_url_name_by_default
    item = ActsAsUrlParam::Newspaper.create(:name => 'this is a url param')
    item_url = item.to_param
    item.update_attributes(:name => 'not updated')
    assert_equal(item_url, item.to_param)
  end
  
  def test_should_work_with_two_items_of_same_name
    name = "just another name"
    item = ActsAsUrlParam::Item.create(:name => name)
    url = item.to_param
    item.update_attributes(:content => "irrelevant")
    assert_equal url, item.to_param
  end
  
  def test_should_work_with_sti
    item = ActsAsUrlParam::Item.create(:name => 'an item')
    book = ActsAsUrlParam::Book.create(:name => 'an item')
    newspaper = ActsAsUrlParam::Newspaper.create(:name => 'an item')
    assert_not_equal(item.to_param, book.to_param)
    assert_equal(item.to_param, newspaper.to_param)
    
    newspaper = ActsAsUrlParam::Newspaper.create(:name => 'another item')
    book = ActsAsUrlParam::Book.create(:name => 'another item')
    assert_equal(book.to_param, newspaper.to_param)
  end
  
  def test_should_use_method_for_url_from_if_exists
    magazine = ActsAsUrlParam::Magazine.create()
    assert !magazine.to_param.blank?
  end
  
  def test_should_run_before_method_if_passed
    ActsAsUrlParam::BeforeItem.any_instance.expects(:set_name)
    item = ActsAsUrlParam::BeforeItem.create(:name => 'the name')
  end
  
  def test_should_run_before_method_before_setting_url
    item = ActsAsUrlParam::BeforeItem.create(:name => 'the name')
    assert_match /is-set/, item.to_param
  end
  
  def test_should_use_scope
    one = ActsAsUrlParam::ScopedItem.create(:name => 'scoper', :scope_by_id => 23)
    two = ActsAsUrlParam::ScopedItem.create(:name => 'scoper', :scope_by_id => 24)
    three = ActsAsUrlParam::ScopedItem.create(:name => 'scoper', :scope_by_id => 24)
    assert_equal one.url_name, two.url_name
    assert one.url_name != three.url_name
  end
  
  def test_should_keep_first_url_on_double_save
    item = ActsAsUrlParam::Item.create(:name => 'boring', :url_name => 'exciting')
    assert_equal item.to_param, 'exciting'
    item.content = 'drivel'
    item.save
    assert_equal item.to_param, 'exciting'
  end
  
  def test_with_url_from_method
    i = ActsAsUrlParam::FromMethodItem.create
    assert_equal i.to_param, i.my_method
  end
  
  private  
  def acts_as_url_name_model(column = nil, options = {})
    m = Class.new(ActiveRecord::Base)
    m.class_eval do
      set_table_name :items
      if column
        acts_as_url_param column, options
      else
        acts_as_url_param options
      end
    end
    m
  end
end