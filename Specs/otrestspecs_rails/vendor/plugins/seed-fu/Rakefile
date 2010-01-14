require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "seed-fu"
    gemspec.summary = "Allows easier database seeding of tables in Rails."
    gemspec.email = "michael@intridea.com"
    gemspec.homepage = "http://github.com/mblegih/seed-fu"
    gemspec.description = "Seed Fu is an attempt to once and for all solve the problem of inserting and maintaining seed data in a database. It uses a variety of techniques gathered from various places around the web and combines them to create what is hopefully the most robust seed data system around."
    gemspec.authors = ["Michael Bleigh"]
    gemspec.add_dependency 'rails', '>= 2.1'
    gemspec.files = FileList["[A-Z]*", "{lib,spec,rails}/**/*"] - FileList["**/*.log"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end


desc 'Default: run specs.'
task :default => :spec
