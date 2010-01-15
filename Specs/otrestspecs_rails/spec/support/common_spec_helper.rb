module CommonSpecHelper
  
  def will_paginate_collection(*collection)
    WillPaginate::Collection.create(1, 10, collection.size) do |pager|
      pager.replace(collection.flatten)
    end
  end
  
  def whitelisted_mock_classes
    [Paperclip::Attachment]
  end
  
  def mock_model(model_class, options_and_stubs = {}, &block)
    if whitelisted_mock_classes.include?(model_class)
      super
    else
      raise "mock_model is not allowed for #{model_class} objects! Use a Factory!"
    end
  end
  
  def stub_model(model_class, stubs={})
    if whitelisted_mock_classes.include?(model_class)
      super
    else
      raise "stub_model is not allowed for #{model_class} objects! Use a Factory!"
    end
  end
  
  def save_response(path = "#{RAILS_ROOT}/response.body")
    puts "Saving response body to #{path}"
    File.open(path, 'w+') {|f| f << response.body}
  end
  
end
