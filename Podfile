inhibit_all_warnings!

target :ios do
  platform :ios, '5.0'
  link_with 'RestKitTests'
  
  pod 'Specta', '0.1.7'
  pod 'OCMock', '2.0.1.classmocks', :git => 'git://github.com/blakewatters/ocmock.git'
  pod 'OCHamcrest', '1.9'
  pod 'Expecta', '0.2.0', :git => 'git://github.com/blakewatters/expecta.git', :branch => 'restkit'
end

target :osx do
  platform :osx, '10.7'
  link_with 'RestKitFrameworkTests'
  
  pod 'Specta', '0.1.7'
  pod 'OCMock', '2.0.1.classmocks', :git => 'git://github.com/blakewatters/ocmock.git'
  pod 'OCHamcrest', '1.9'
  pod 'Expecta', '0.2.0', :git => 'git://github.com/blakewatters/expecta.git', :branch => 'restkit'
end
