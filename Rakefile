require 'rubygems'

namespace :spec do
  desc "Run the RestKit spec server"
  task :server do
    server_path = File.dirname(__FILE__) + '/Specs/Server/server.rb'
    system("ruby #{server_path}")
  end
end

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

task :default => 'spec:server'

desc "Build RestKit for iOS and Mac OS X"
task :build do
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk iphonesimulator5.0 clean build")
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk iphoneos clean build")
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKit -sdk macosx10.6 clean build")
  run("xcodebuild -workspace RestKit.xcodeproj/project.xcworkspace -scheme RestKitThree20 -sdk iphoneos clean build")
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
      exit(exitstatus)
    end    
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
task :validate => [:ensure_server_is_running, :build, 'docs:check', 'uispec:all'] do  
  puts "Project stated validated successfully. Proceed with merge."  
end
