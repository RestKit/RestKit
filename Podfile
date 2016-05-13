source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

target :RestKit do
  platform :ios, '5.1.1'
  podspec
end

target :RestKitFramework do
  platform :osx, '10.7'
  podspec
end

def import_pods
  pod 'RestKit', :path => '.'
  pod 'RestKit/Testing', :path => '.'
  pod 'RestKit/Search', :path => '.'

  pod 'Specta', '0.2.1'
  pod 'OCMock', '2.2.4'
  pod 'OCHamcrest', '3.0.1'
  pod 'Expecta', '0.3.1'

  # Used for testing Value Transformer integration
  pod 'RKCLLocationValueTransformer', '~> 1.1.0'
end

target 'RestKitTests' do
  platform :ios, '5.1.1'
  import_pods
end

target 'RestKitFrameworkTests' do
  platform :osx, '10.7'
  import_pods
end
