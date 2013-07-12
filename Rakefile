require 'rubygems'
require 'bundler/setup'
require 'rakeup'
require 'debugger'

RakeUp::ServerTask.new do |t|
  t.port = 4567
  t.pid_file = 'Tests/Server/server.pid'
  t.rackup_file = 'Tests/Server/server.ru'
  t.server = :thin
end

namespace :test do
  task :prepare do    
    system(%Q{mkdir -p "RestKit.xcworkspace/xcshareddata/xcschemes" && cp Tests/Schemes/*.xcscheme "RestKit.xcworkspace/xcshareddata/xcschemes/"})
  end
  
  desc "Run the unit tests for iOS"
  task :ios => :prepare do
    $ios_success = system("xctool -workspace RestKit.xcworkspace -scheme RestKitTests -sdk iphonesimulator build build-tests run-tests -test-sdk iphonesimulator")
  end
  
  desc "Run the unit tests for OS X"
  task :osx => :prepare do
    $osx_success = system("xctool -workspace RestKit.xcworkspace -scheme RestKitFrameworkTests -sdk macosx build build-tests run-tests -test-sdk macosx")
  end
end

desc 'Run all the RestKit tests'
task :test => ['test:ios', 'test:osx'] do
  puts "\033[0;31m!! iOS unit tests failed" unless $ios_success
  puts "\033[0;31m!! OS X unit tests failed" unless $osx_success
  if $ios_success && $osx_success
    puts "\033[0;32m** All tests executed successfully"
  else
    exit(-1)
  end
end

task :default => ["server:autostart", :test, "server:autostop"]

def restkit_version
  @restkit_version ||= ENV['VERSION'] || File.read("VERSION").chomp
end

def apple_doc_command
  "/usr/local/bin/appledoc -o Docs/API -p RestKit -v #{restkit_version} -c \"RestKit\" " +
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
  run("xcodebuild -workspace RestKit.xcworkspace -scheme RestKit -sdk iphonesimulator5.0 clean build")
  run("xcodebuild -workspace RestKit.xcworkspace -scheme RestKit -sdk iphoneos clean build")
  run("xcodebuild -workspace RestKit.xcworkspace -scheme RestKit -sdk macosx10.6 clean build")
end

desc "Generate documentation via appledoc"
task :docs => 'docs:generate'

namespace :appledoc do
  task :check do
    unless File.exists?('/usr/local/bin/appledoc')
      puts "appledoc not found at /usr/local/bin/appledoc: Install via homebrew and try again: `brew install --HEAD appledoc`"
      exit 1
    end
  end
end

namespace :docs do
  task :generate => 'appledoc:check' do
    command = apple_doc_command << " --no-create-docset --keep-intermediate-files --create-html `find Code/ -name '*.h'`"
    run(command, 1)
    puts "Generated HTML documentationa at Docs/API/html"
  end
  
  desc "Check that documentation can be built from the source code via appledoc successfully."
  task :check => 'appledoc:check' do
    command = apple_doc_command << " --no-create-html --verbose 5 `find Code/ -name '*.h'`"
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
  task :install => 'appledoc:check' do
    command = apple_doc_command << " --install-docset `find Code/ -name '*.h'`"
    run(command, 1)
  end
  
  desc "Build and publish the documentation set to the remote server (using rsync over SSH)"
  task :publish, :version, :destination, :publish_feed do |t, args|
    args.with_defaults(:version => File.read("VERSION").chomp, :destination => "restkit.org:/var/www/public/restkit.org/public/api/", :publish_feed => 'true')
    version = args[:version]
    destination = args[:destination]    
    puts "Generating RestKit docset for version #{version}..."
    command = apple_doc_command <<
            " --keep-intermediate-files" <<
            " --docset-feed-name \"RestKit #{version} Documentation\"" <<
            " --docset-feed-url http://restkit.org/api/%DOCSETATOMFILENAME" <<
            " --docset-package-url http://restkit.org/api/%DOCSETPACKAGEFILENAME --publish-docset --verbose 3 `find Code/ -name '*.h'`"
    run(command, 1)
    puts "Uploading docset to #{destination}..."
    versioned_destination = File.join(destination, version)
    command = "rsync -rvpPe ssh --delete Docs/API/html/ #{versioned_destination}"
    run(command)
    
    should_publish_feed = %{yes true 1}.include?(args[:publish_feed].downcase)
    if $?.exitstatus == 0 && should_publish_feed
      command = "rsync -rvpPe ssh Docs/API/publish/* #{destination}"
      run(command)
    end
  end
end

namespace :build do
  desc "Build all Example projects to ensure they are building properly"
  task :examples do
    ios_sdks = %w{iphoneos iphonesimulator5.0 iphonesimulator6.0}
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
