require 'rake'
require 'spec/rake/spectask'
 
desc 'Default: run unit tests.'
task :default => :spec
 
spec_files = Rake::FileList["spec/**/*_spec.rb"]
 
desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = spec_files
  t.spec_opts = ['--options', "spec/spec.opts"]
end
 