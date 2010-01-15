$LOAD_PATH.unshift(RAILS_ROOT + '/vendor/plugins/cucumber/lib') if File.directory?(RAILS_ROOT + '/vendor/plugins/cucumber/lib')

begin
  require 'cucumber/rake/task'
  require 'spec/rake/verify_rcov'

  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format pretty"
  end
  task :features => 'db:test:prepare'

  namespace :features do
    Cucumber::Rake::Task.new(:all) do |t|
      t.cucumber_opts = "--format pretty"
    end
    
    begin
      Cucumber::Rake::Task.new(:rcov) do |t|    
        t.rcov = true
        t.rcov_opts = IO.readlines("#{RAILS_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
        t.rcov_opts << %[-o "coverage/features"]
      end

      RCov::VerifyTask.new('rcov:verify' => 'features:rcov') do |t| 
        t.threshold = 95.0
        t.index_html = 'coverage/features/index.html'
       end
    rescue
    end
   end
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end

