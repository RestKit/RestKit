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

desc "Run all specs"
task :default => 'uispec:all'
