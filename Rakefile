require 'rubygems'

begin
  gem 'uispecrunner'
  require 'uispecrunner'
  require 'uispecrunner/options'
rescue LoadError => error
  puts "Unable to load UISpecRunner: #{error}"
end

namespace :uispec do
  desc "Run all specs"
  task :all do
    options = UISpecRunner::Options.from_file('uispec.opts') rescue {}
    uispec_runner = UISpecRunner.new(options)
    uispec_runner.run_all!
  end
  
  desc "Run all unit specs (those that implement UISpecUnit)"
  task :units do
    options = UISpecRunner::Options.from_file('uispec.opts') rescue {}
    uispec_runner = UISpecRunner.new(options)
    uispec_runner.run_protocol!('UISpecUnit')
  end
  
  desc "Run all integration specs (those that implement UISpecIntegration)"
  task :integration do
    options = UISpecRunner::Options.from_file('uispec.opts') rescue {}
    uispec_runner = UISpecRunner.new(options)
    uispec_runner.run_protocol!('UISpecIntegration')
  end
  
  desc "Run the Spec server via Shotgun"
  task :server do
    server_path = File.dirname(__FILE__) + '/Specs/Server/server.rb'
    #system("shotgun --port 4567 #{server_path}")
    system("ruby #{server_path}")
  end
end

def restkit_version
  @restkit_version ||= ENV['VERSION'] || File.read("VERSION").chomp
end

def apple_doc_command
  "Vendor/appledoc/appledoc -t Vendor/appledoc/Templates -o Docs/API -p RestKit -v #{restkit_version} -c \"Two Toasters\" " +
  "--company-id org.restkit --warn-undocumented-object --warn-undocumented-member  --warn-empty-description  --warn-unknown-directive " +
  "--warn-invalid-crossref --warn-missing-arg --no-repeat-first-par "
end

def run(command)
  puts "Executing: `#{command}`"
  system(command)
  if $? != 0
    puts "[!] Failed with exit code #{$?} while running: `#{command}`"
    exit($?)
  end
end

desc "Run all specs"
task :default => 'uispec:all'

desc "Build RestKit for iOS and Mac OS X"
task :build do
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk iphoneos4.3 clean build")  
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk macosx10.6 clean build")
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKitThree20 -sdk iphoneos4.3 clean build")
  run("xcodebuild -workspace Examples/RKCatalog/RKCatalog.xcodeproj/project.xcworkspace -scheme RKCatalog -sdk iphoneos4.3 clean build")
end

desc "Generate documentation via appledoc"
task :docs => 'docs:generate'

namespace :docs do
  task :generate do
    command = apple_doc_command << " --no-create-docset --keep-intermediate-files --create-html Code/"
    run(command)
    puts "Generated HTML documentationa at Docs/API/html"
  end
  
  desc "Check that documentation can be built from the source code via appledoc successfully."
  task :check do
    command = apple_doc_command << " --no-create-html Code/"
    run(command)
    if $? != 0
      puts "Documentation failed to generate with exit code #{$?}"
      exit($?)
    else
      puts "Documentation processing with appledoc was successful."
    end
  end
  
  desc "Generate & install a docset into Xcode from the current sources"
  task :install do
    command = apple_doc_command << " --install-docset Code/"
    run(command)
  end
  
  desc "Build and upload the documentation set to the remote server"
  task :upload do
    version = ENV['VERSION'] || File.read("VERSION").chomp
    puts "Generating RestKit docset for version #{version}..."
    command = apple_doc_command <<
            " --keep-intermediate-files" <<
            " --docset-feed-name \"RestKit #{version} Documentation\"" <<
            " --docset-feed-url http://restkit.org/api/%DOCSETATOMFILENAME" <<
            " --docset-package-url http://restkit.org/api/%DOCSETPACKAGEFILENAME --publish-docset Code/"
    run(command)
    if $? == 0
      puts "Uploading docset to restkit.org..."
      command = "rsync -rvpPe ssh --delete Docs/API/html/ restkit.org:/var/www/public/restkit.org/public/api/#{version}"
      run(command)
      
      if $? == 0
        command = "rsync -rvpPe ssh Docs/API/publish/ restkit.org:/var/www/public/restkit.org/public/api/"
        run(command)
      end
    end
  end
end

def is_port_open?(ip, port)
  require 'socket'
  require 'timeout'
  
  begin
    Timeout::timeout(1) do
      begin
        s = TCPSocket.new(ip, port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    end
  rescue Timeout::Error
  end

  return false
end

task :ensure_server_is_running do
  unless is_port_open?('127.0.0.1', 4567)
    puts "Unable to find RestKit Specs server listening on port 4567. Run `rake uispec:server` and try again."
    exit(-1)
  end
end

desc "Validate a branch is ready for merging by checking for common issues"
task :validate => [:build, 'docs:check', :ensure_server_is_running, 'uispec:all'] do
  puts "All tests passed OK. Proceed with merge."
end
