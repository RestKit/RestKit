inhibit_all_warnings!

def import_pods
  pod 'RestKit', :podspec => 'RestKit.podspec'
  pod 'RestKit/Testing', :podspec => '.'
  pod 'RestKit/Search', :podspec => '.'
  
  pod 'Specta', '0.1.9'
  pod 'OCMock', '2.1.1'
  pod 'OCHamcrest', '2.1.0'
  pod 'Expecta', '0.2.1'
  
  # Used for testing Value Transformer integration
  pod 'RKCLLocationValueTransformer', :git => 'https://github.com/RestKit/RKCLLocationValueTransformer'
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
