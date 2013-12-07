inhibit_all_warnings!

def import_pods
  pod 'RestKit', path: '.'
  pod 'RestKit/Testing', path: '.'
  pod 'RestKit/Search', path: '.'
  
  pod 'AFNetworking', path: 'Vendor/AFNetworking'
  
  pod 'Specta', '0.2.1'
  pod 'OCMock', '2.2.1'
  pod 'OCHamcrest', '3.0.1'
  pod 'Expecta', '0.2.3'
  
  # Used for testing Value Transformer integration
  pod 'RKCLLocationValueTransformer', git: 'https://github.com/RestKit/RKCLLocationValueTransformer'
end

target :ios do
  platform :ios, '6.0'
  link_with 'RestKitTests'
  import_pods
end

target :osx do
  platform :osx, '10.8'
  link_with 'RestKitFrameworkTests'
  import_pods
end
