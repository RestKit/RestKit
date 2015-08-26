Pod::Spec.new do |s|
  s.name             =  'RestKit'
  s.version          =  '0.25.0'
  s.summary          =  'RestKit is a framework for consuming and modeling RESTful web resources on iOS and OS X.'
  s.homepage         =  'https://github.com/RestKit/RestKit'
  s.social_media_url =  'https://twitter.com/RestKit'
  s.author           =  { 'Blake Watters' => 'blakewatters@gmail.com' }
  s.source           =  { :git => 'https://github.com/RestKit/RestKit.git', :tag => "v#{s.version}" }
  s.license          =  'Apache License, Version 2.0'

  # Platform setup
  s.requires_arc = true
  s.ios.deployment_target = '5.1.1'
  s.osx.deployment_target = '10.7'

  # Exclude optional Search and Testing modules
  s.default_subspec = 'Core'

  # Add Core Data to the PCH if the Core Data subspec is imported. This enables conditional compilation to kick in.
  s.prefix_header_contents = <<-EOS
#if __has_include("RKCoreData.h")
    #import <CoreData/CoreData.h>
#endif
EOS

  # Preserve the layout of headers in the Code directory
  s.header_mappings_dir = 'Code'

  ### Subspecs

  s.subspec 'Core' do |cs|
    cs.dependency 'RestKit/ObjectMapping'
    cs.dependency 'RestKit/Network'
    cs.dependency 'RestKit/CoreData'
  end

  s.subspec 'ObjectMapping' do |os|
    os.source_files   = 'Code/ObjectMapping.h', 'Code/ObjectMapping'
    os.dependency       'RestKit/Support'
    os.dependency       'RKValueTransformers', '~> 1.1.0'
    os.dependency       'ISO8601DateFormatterValueTransformer', '~> 0.6.1'
  end

  s.subspec 'Network' do |ns|
    ns.source_files   = 'Code/Network.h', 'Code/Network'
    ns.ios.frameworks = 'CFNetwork', 'Security', 'MobileCoreServices', 'SystemConfiguration'
    ns.osx.frameworks = 'CoreServices', 'Security', 'SystemConfiguration'
    ns.dependency       'SOCKit'
    ns.dependency       'AFNetworking', '~> 1.3.0'
    ns.dependency       'RestKit/ObjectMapping'
    ns.dependency       'RestKit/Support'

    ns.prefix_header_contents = <<-EOS
#import <Availability.h>

#define _AFNETWORKING_PIN_SSL_CERTIFICATES_

#if __IPHONE_OS_VERSION_MIN_REQUIRED
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <MobileCoreServices/MobileCoreServices.h>
  #import <Security/Security.h>
#else
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <CoreServices/CoreServices.h>
  #import <Security/Security.h>
#endif
EOS
  end

  s.subspec 'CoreData' do |cdos|
    cdos.source_files = 'Code/CoreData.h', 'Code/CoreData'
    cdos.frameworks   = 'CoreData'
    cdos.dependency 'RestKit/ObjectMapping'
  end

  s.subspec 'Testing' do |ts|
    ts.source_files = 'Code/Testing.h', 'Code/Testing'
    ts.dependency 'RestKit/Network'
    ts.prefix_header_contents = <<-EOS
#import <Availability.h>

#define _AFNETWORKING_PIN_SSL_CERTIFICATES_

#if __IPHONE_OS_VERSION_MIN_REQUIRED
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <MobileCoreServices/MobileCoreServices.h>
  #import <Security/Security.h>
#else
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <CoreServices/CoreServices.h>
  #import <Security/Security.h>
#endif
EOS
  end

  s.subspec 'Search' do |ss|
    ss.source_files   = 'Code/Search.h', 'Code/Search'
    ss.dependency 'RestKit/CoreData'
  end

  s.subspec 'Support' do |ss|
    ss.source_files   = 'Code/RestKit.h', 'Code/Support.h', 'Code/Support', 'Vendor/LibComponentLogging/Core'
    ss.dependency 'TransitionKit', '~> 2.2'
  end
end
