inhibit_all_warnings!

def import_pods
  pod 'Specta', '0.1.9'
  pod 'OCMock', '2.1.1'
  pod 'OCHamcrest', '2.1.0'
  pod 'Expecta', '0.2.1'
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
