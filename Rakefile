require 'rubygems'
require 'bundler/setup'
require 'xcoder'
require 'restkit/rake'

RestKit::Rake::ServerTask.new do |t|
  t.port = 4567
  t.pid_file = 'Tests/Server/server.pid'
  t.rackup_file = 'Tests/Server/server.ru'
  t.log_file = 'Tests/Server/server.log'

  t.adapter(:thin) do |thin|
    thin.config_file = 'Tests/Server/thin.yml'
  end
end

namespace :test do
  task :kill_simulator do
    system(%q{killall -m -KILL "iPhone Simulator"})
  end
  
  namespace :units do
    desc "Run the RestKit unit tests for iOS"
    task :ios => :kill_simulator do
      config = Xcode.project(:RestKit).target(:RestKitTests).config(:Debug)
      builder = config.builder
      build_dir = File.dirname(config.target.project.path) + '/Build'
      builder.symroot = build_dir + '/Products'
      builder.objroot = build_dir
    	builder.test('iphonesimulator')
    end
    
    desc "Run the RestKit unit tests for OS X"
    task :osx => :kill_simulator do
      config = Xcode.project(:RestKit).target(:RestKitFrameworkTests).config(:Debug)
      builder = config.builder
      build_dir = File.dirname(config.target.project.path) + '/Build'
      builder.symroot = build_dir + '/Products'
      builder.objroot = build_dir
    	builder.test('macosx')
    end
  end
  
  desc "Run the RestKit unit tests for iOS and OS X"
  task :units => ['units:ios', 'units:osx']

  task :all => ['test:units', 'test:integration']
end

desc 'Run all the GateGuru tests'
task :test => "test:all"

task :default => "test:all"

def restkit_version
  @restkit_version ||= ENV['VERSION'] || File.read("VERSION").chomp
end

def apple_doc_command
  "Vendor/appledoc/appledoc -t Vendor/appledoc/Templates -o Docs/API -p RestKit -v #{restkit_version} -c \"RestKit\" " +
  "--company-id org.restkit --warn-undocumented-object --warn-undocumented-member  --warn-empty-description  --warn-unknown-directive " +
  "--warn-invalid-crossref --warn-missing-arg --no-repeat-first-par "
end

def run(command, min_exit_status = 0)
  puts "Executing: `#{command}`"
  system(command)
  if $?.exitstatus > min_exit_status
    puts "[!] Failed with exit code #{$?.exitstatus} while running: `#{command}`"
    exit($?.exitstatus)
  end
  return $?.exitstatus
end

desc "Build RestKit for iOS and Mac OS X"
task :build do
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk iphonesimulator5.0 clean build")
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk iphoneos clean build")
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk macosx10.6 clean build")
  run("xcodebuild -workspace Examples/RKCatalog/RKCatalog.xcodeproj/project.xcworkspace -scheme RKCatalog -sdk iphoneos clean build")
end

desc "Generate documentation via appledoc"
task :docs => 'docs:generate'

namespace :docs do
  task :generate do
    command = apple_doc_command << " --no-create-docset --keep-intermediate-files --create-html Code/"
    run(command, 1)
    puts "Generated HTML documentationa at Docs/API/html"
  end
  
  desc "Check that documentation can be built from the source code via appledoc successfully."
  task :check do
    command = apple_doc_command << " --no-create-html --verbose 5 Code/"
    exitstatus = run(command, 1)
    if exitstatus == 0
      puts "appledoc generation completed successfully!"
    elsif exitstatus == 1
      puts "appledoc generation produced warnings"
    elsif exitstatus == 2
      puts "! appledoc generation encountered an error"
      exit(exitstatus)
    else
      puts "!! appledoc generation failed with a fatal error"
    end    
    exit(exitstatus)
  end
  
  desc "Generate & install a docset into Xcode from the current sources"
  task :install do
    command = apple_doc_command << " --install-docset Code/"
    run(command, 1)
  end
  
  desc "Build and upload the documentation set to the remote server"
  task :upload do
    version = ENV['VERSION'] || File.read("VERSION").chomp
    puts "Generating RestKit docset for version #{version}..."
    command = apple_doc_command <<
            " --keep-intermediate-files" <<
            " --docset-feed-name \"RestKit #{version} Documentation\"" <<
            " --docset-feed-url http://restkit.org/api/%DOCSETATOMFILENAME" <<
            " --docset-package-url http://restkit.org/api/%DOCSETPACKAGEFILENAME --publish-docset --verbose 3 Code/"
    run(command, 1)
    puts "Uploading docset to restkit.org..."
    command = "rsync -rvpPe ssh --delete Docs/API/html/ restkit.org:/var/www/public/restkit.org/public/api/#{version}"
    run(command)
    
    if $?.exitstatus == 0
      command = "rsync -rvpPe ssh Docs/API/publish/ restkit.org:/var/www/public/restkit.org/public/api/"
      run(command)
    end
  end
end

namespace :build do
  desc "Build all Example projects to ensure they are building properly"
  task :examples do
    ios_sdks = %w{iphoneos iphonesimulator5.0}
    osx_sdks = %w{macosx}
    osx_projects = %w{RKMacOSX}
    
    examples_path = File.join(File.expand_path(File.dirname(__FILE__)), 'Examples')
    example_projects = `find #{examples_path} -name '*.xcodeproj'`.split("\n")
    puts "Building #{example_projects.size} Example projects..."
    example_projects.each do |example_project|
      project_name = File.basename(example_project).gsub('.xcodeproj', '')
      sdks = osx_projects.include?(project_name) ? osx_sdks : ios_sdks
      sdks.each do |sdk|
        puts "Building '#{example_project}' with SDK #{sdk}..."
        scheme = project_name
        run("xcodebuild -workspace #{example_project}/project.xcworkspace -scheme #{scheme} -sdk #{sdk} clean build")
        #run("xcodebuild -project #{example_project} -alltargets -sdk #{sdk} clean build")
      end
    end
  end
end

desc "Validate a branch is ready for merging by checking for common issues"
task :validate => [:build, 'docs:check', 'uispec:all'] do  
  puts "Project state validated successfully. Proceed with merge."
end
