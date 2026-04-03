source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

workspace 'RestKit.xcworkspace'

def import_pods
  pod 'RestKit/Testing', :path => '.'
  pod 'RestKit/Search', :path => '.'

  pod 'Specta', '2.0.0'
  pod 'OCMock', '3.9.4'
  pod 'OCHamcrest', '9.0.3'
  pod 'Expecta', '1.0.6'

  # Used for testing Value Transformer integration
  pod 'RKCLLocationValueTransformer', '~> 1.1.0'
end

target 'RestKit' do
  platform :ios, '16.6'
  podspec

  target 'RestKitTests' do
      inherit! :search_paths
      import_pods
  end
end

target 'RestKitFramework' do
  platform :osx, '11.5'
  podspec

  target 'RestKitFrameworkTests' do
      inherit! :search_paths
      import_pods
  end
end
