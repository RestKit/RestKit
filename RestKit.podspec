Pod::Spec.new do |s|
  s.name         =  'RestKit'
  s.version      =  '0.20.0'
  s.summary      =  'RestKit is a framework for consuming and modeling RESTful web resources on iOS and OS X.'
  s.homepage     =  'http://www.restkit.org'
  s.author       =  { 'Blake Watters' => 'blakewatters@gmail.com' }
  s.source       =  { :git => 'https://github.com/RestKit/RestKit.git', :branch => 'feature/reboot-networking-layer' }
  s.license      =  'Apache License, Version 2.0'

  s.source_files =  'Code/RestKit.h'
  
  # Platform setup
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  
  s.dependency 'RestKit/Network'
  s.dependency 'RestKit/JSONKit'
  s.dependency 'RestKit/ObjectMapping'
  s.dependency 'RestKit/ObjectMapping/CoreData'
  s.dependency 'RestKit/Search'
  s.dependency 'RestKit/Testing'

  ### Subspecs

  s.subspec 'Network' do |ns|
    ns.source_files   = 'Code/Network', 'Code/Support'
    ns.ios.frameworks = 'CFNetwork', 'Security', 'MobileCoreServices', 'SystemConfiguration'
    ns.osx.frameworks = 'CoreServices', 'Security', 'SystemConfiguration'
    ns.dependency       'LibComponentLogging-NSLog', '>= 1.0.4'
    ns.dependency       'SOCKit'
    ns.dependency       'AFNetworking', '1.0RC1'
  end
  
  s.subspec 'JSONKit' do |jos|
    jos.source_files = 'Code/Support/Parsers/JSON/RKJSONParserJSONKit.{h,m}'
    jos.dependency     'JSONKit', '>= 1.5pre'
  end    
  
  s.subspec 'ObjectMapping' do |os|
    os.source_files = 'Code/ObjectMapping'
    os.dependency     'ISO8601DateFormatter', '>= 0.6'
    os.dependency     'RestKit/Network'    

    os.subspec 'CoreData' do |cdos|
      cdos.source_files = 'Code/CoreData'
      cdos.frameworks   = 'CoreData'
    end
  end
  
  s.subspec 'Testing' do |ts|
    ts.source_files = 'Code/Testing'
  end
  
  s.subspec 'Search' do |ss|
    ss.source_files   = 'Code/Search'
    ss.ios.frameworks = 'CoreData'
    ss.osx.frameworks = 'CoreData'
    ss.dependency 'RestKit/ObjectMapping/CoreData'
  end
end
