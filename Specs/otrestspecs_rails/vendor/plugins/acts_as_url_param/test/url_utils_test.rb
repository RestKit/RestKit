require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class UrlUtilsTest < Test::Unit::TestCase
  include Caring::Utilities::UrlUtils
  
  def test_url_safe
    assert_equal "a1-b-z", url_safe("a1 b@ _Z!")
    assert_equal "a-and-b-and-c-and-d", url_safe("a &amp; b &amp; c & d")
    assert_equal "a1-b-z", url_safe("a1 b@ - Z!")
    assert_equal 'a1#b#_Z', url_safe('a1 b@ _Z', :replacements => { '#', /[^a-zA-Z0-9_-]+/}, :downcase => false)
    assert_equal 'a1-b2---z9', url_safe('a1 b2   z9', :collapse => false)
    assert_equal 'a1_b2___z9', url_safe('a1 b2   z9', :char => '_', :collapse => false)
  end
  
  def test_uniquify
    assert_equal "asdf", uniquify("asdf") { |candidate| true }
    i = 0
    assert_equal "asdf-2", uniquify("asdf") { |candidate| (i = i+1) == 2 }
    i = 0
    assert_equal "asdf-3", uniquify("asdf") { |candidate| (i = i+1) == 3 }
    assert_raises ArgumentError do
      uniquify("asdf", :endings => Generator.new(%w(a b c))) {|c| false}
    end
  end
end