inhibit_all_warnings!

def import_pods
  pod 'RestKit', :path => '.'
  pod 'RestKit/Testing', :path => '.'
  pod 'RestKit/Search', :path => '.'
  
  pod 'Specta', '0.2.1'
  pod 'OCMock', '2.2.1'
  pod 'OCHamcrest', '3.0.1'
  pod 'Expecta', '0.3.1'
  
  # Used for testing Value Transformer integration
  pod 'RKCLLocationValueTransformer', '~> 1.1.0'
end

target :ios do
  platform :ios, '5.0'
  link_with 'RestKitTests'
  import_pods
end

target :osx do
  platform :osx, '10.7'
  link_with 'RestKitFrameworkTests'
  import_pods
end
