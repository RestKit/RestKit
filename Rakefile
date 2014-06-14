require 'rubygems'
require 'bundler/setup'
Bundler.setup
require 'xctasks/test_task'
require 'rakeup'

RakeUp::ServerTask.new do |t|
  t.port = 4567
  t.pid_file = 'Tests/Server/server.pid'
  t.rackup_file = 'Tests/Server/server.ru'
  t.server = :thin
end

XCTasks::TestTask.new(:test) do |t|
  t.workspace = 'RestKit.xcworkspace'
  t.schemes_dir = 'Tests/Schemes'
  t.runner = :xcpretty
  t.actions = %w{test}
  
  t.subtask(ios: 'RestKitTests') do |s|
    s.sdk = :iphonesimulator
  end
  
  t.subtask(osx: 'RestKitFrameworkTests') do |s|
    s.sdk = :macosx
  end
end

task default: 'test'

namespace :test do
  # Provides validation that RestKit continues to build without Core Data. This requires conditional compilation that is error prone
  task :building_without_core_data do
    system("cd Examples/RKTwitter && pod install")
    system("xctool -workspace Examples/RKTwitter/RKTwitter.xcworkspace -scheme RKTwitterCocoaPods -sdk iphonesimulator clean build ONLY_ACTIVE_ARCH=NO")
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
    puts "Generated HTML documentation at Docs/API/html"
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
    ios_sdks = %w{iphonesimulator5.0 iphonesimulator6.0}
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
        run("xctool -workspace #{example_project}/project.xcworkspace -scheme #{scheme} -sdk #{sdk} clean build")
      end
    end
  end
end

desc "Validate a branch is ready for merging by checking for common issues"
task :validate => ['build:examples', 'docs:check', :test] do  
  puts "Project state validated successfully. Proceed with merge."
end

task :lint do
  system('bundle exec pod lib lint')
end

desc 'Runs the CI suite'
task :ci => ['server:start', :test, 'test:building_without_core_data', :lint]

