require 'rubygems'
require 'bundler/setup'
require 'xcoder'
require 'restkit/rake'
require 'ruby-debug'

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
  
  namespace :logic do
    desc "Run the logic tests for iOS"
    task :ios => :kill_simulator do
      config = Xcode.project(:RestKit).target(:RestKitTests).config(:Debug)
      builder = config.builder
      build_dir = File.dirname(config.target.project.path) + '/Build'
      builder.symroot = build_dir + '/Products'
      builder.objroot = build_dir
    	builder.test(:sdk => 'iphonesimulator')
    end
    
    desc "Run the logic tests for OS X"
    task :osx do
      config = Xcode.project(:RestKit).target(:RestKitFrameworkTests).config(:Debug)
      builder = config.builder
      build_dir = File.dirname(config.target.project.path) + '/Build'
      builder.symroot = build_dir + '/Products'
      builder.objroot = build_dir
    	builder.test(:sdk => 'macosx')
    end
  end    
  
  desc "Run the unit tests for iOS and OS X"
  task :logic => ['logic:ios', 'logic:osx']
  
  namespace :application do
    desc "Run the application tests for iOS"
    task :ios => :kill_simulator do
      config = Xcode.project(:RKApplicationTests).target('Application Tests').config(:Debug)
      builder = config.builder
      build_dir = File.dirname(config.target.project.path) + '/Build'
      builder.symroot = build_dir + '/Products'
      builder.objroot = build_dir
    	builder.test(:sdk => 'iphonesimulator')
    end
  end
  
  desc "Run the application tests for iOS"
  task :application => 'application:ios'
  
  desc "Run all tests for iOS and OS X"
  task :all do
    Rake.application.invoke_task("test:logic")
    unit_status = $?.exitstatus
    Rake.application.invoke_task("test:application")
    integration_status = $?.exitstatus
    puts "\033[0;31m!! Unit Tests failed with exit status of #{unit_status}" if unit_status != 0
    puts "\033[0;31m!! Integration Tests failed with exit status of #{integration_status}" if integration_status != 0
    puts "\033[0;32m** All Tests executed successfully" if unit_status == 0 && integration_status == 0
  end
  
  task :check_mongodb do
    port_check = RestKit::Server::PortCheck.new('127.0.0.1', 27017)
    port_check.run
    if port_check.closed?
      puts "\033[0;33m!! Warning: MongoDB was not found running on port 27017"
      puts "MongoDB is required for the execution of the OAuth tests. Tests in RKOAuthClientTest will NOT be executed"
      `which mongo`
      if $?.exitstatus == 0
        puts "Execute MongoDB via `mongod run --config /usr/local/etc/mongod.conf`"
      else
        puts "Install mongodb with Homebrew via `brew install mongodb`"
      end
      puts "\033[0m"
      sleep(5)
    end
  end
end

desc 'Run all the RestKit tests'
task :test => "test:all"

task :default => ["test:check_mongodb", "server:autostart", "test:all", "server:autostop"]

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
  
  desc "Build and publish the documentation set to the remote server (using rsync over SSH)"
  task :publish, :version, :destination do |t, args|
    args.with_defaults(:version => File.read("VERSION").chomp, :destination => "restkit.org:/var/www/public/restkit.org/public/api/")
    version = args[:version]
    destination = args[:destination]    
    puts "Generating RestKit docset for version #{version}..."
    command = apple_doc_command <<
            " --keep-intermediate-files" <<
            " --docset-feed-name \"RestKit #{version} Documentation\"" <<
            " --docset-feed-url http://restkit.org/api/%DOCSETATOMFILENAME" <<
            " --docset-package-url http://restkit.org/api/%DOCSETPACKAGEFILENAME --publish-docset --verbose 3 Code/"
    run(command, 1)
    puts "Uploading docset to #{destination}..."
    versioned_destination = File.join(destination, version)
    command = "rsync -rvpPe ssh --delete Docs/API/html/ #{versioned_destination}"
    run(command)
    
    if $?.exitstatus == 0
      command = "rsync -rvpPe ssh Docs/API/publish/ #{destination}"
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

namespace :payload do
  task :generate do
    require 'json'
    require 'faker'
    
    ids = (1..25).to_a
    child_ids = (50..100).to_a
    child_counts = (10..25).to_a
    hash = ids.inject({'parents' => []}) do |hash, parent_id|
      child_count = child_counts.sample
      children = (0..child_count).collect do
        {'name' => Faker::Name.name, 'childID' => child_ids.sample}
      end
      parent = {'parentID' => parent_id, 'name' => Faker::Name.name, 'children' => children}
      hash['parents'] << parent
      hash
    end
    File.open('payload.json', 'w+') { |f| f << hash.to_json }
    puts "Generated payload at: payload.json"
  end
end
