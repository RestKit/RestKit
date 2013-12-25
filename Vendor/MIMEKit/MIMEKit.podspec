Pod::Spec.new do |s|
  s.name     = 'MIMEKit'
  s.version  = '1.0.0'
  s.license  = 'Apache2'
  s.summary  = 'A uniform content serialization API supporting registration by MIME Type.'
  s.homepage = 'https://github.com/blakewatters/MIMEKit'
  s.authors  = { 'Blake Watters' => 'blakewatters@gmail.com' }
  s.source   = { :git => 'https://github.com/blakewatters/MIMEKit.git', :tag => s.version.to_s }
  s.source_files = 'Code'
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
