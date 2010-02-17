require "zlib"

task_name = Rake::Task.task_defined?("db:seed") ? "seed_fu" : "seed"

namespace :db do
  desc <<-EOS
    Loads seed data for the current environment. It will look for
    ruby seed files in <RAILS_ROOT>/db/fixtures/ and 
    <RAILS_ROOT>/db/fixtures/<RAILS_ENV>/.

    By default it will load any ruby files found. You can filter the files
    loaded by passing in the SEED environment variable with a comma-delimited
    list of patterns to include. Any files not matching the pattern will
    not be loaded.
    
    You can also change the directory where seed files are looked for
    with the FIXTURE_PATH environment variable. 
    
    Examples:
      # default, to load all seed files for the current environment
      rake db:seed
      
      # to load seed files matching orders or customers
      rake db:seed SEED=orders,customers
      
      # to load files from RAILS_ROOT/features/fixtures
      rake db:seed FIXTURE_PATH=features/fixtures 
  EOS
  task task_name => :environment do
    fixture_path = ENV["FIXTURE_PATH"] ? ENV["FIXTURE_PATH"] : "db/fixtures"

    seed_files = (
      ( Dir[File.join(RAILS_ROOT, fixture_path, '*.rb')] +
        Dir[File.join(RAILS_ROOT, fixture_path, '*.rb.gz')] ).sort +
      ( Dir[File.join(RAILS_ROOT, fixture_path, RAILS_ENV, '*.rb')] +
        Dir[File.join(RAILS_ROOT, fixture_path, RAILS_ENV, '*.rb.gz')] ).sort
    ).uniq
    
    if ENV["SEED"]
      filter = ENV["SEED"].gsub(/,/, "|")
      seed_files.reject!{ |file| !(file =~ /#{filter}/) }
      puts "\n == Filtering seed files against regexp: #{filter}"
    end

    seed_files.each do |file|
      pretty_name = file.sub("#{RAILS_ROOT}/", "")
      puts "\n== Seed from #{pretty_name} " + ("=" * (60 - (17 + File.split(file).last.length)))

      old_level = ActiveRecord::Base.logger.level
      begin
        ActiveRecord::Base.logger.level = 7

        ActiveRecord::Base.transaction do
          if pretty_name[-3..pretty_name.length] == '.gz'
            # If the file is gzip, read it and use eval
            #
            Zlib::GzipReader.open(file) do |gz|
              chunked_ruby = ''
              gz.each_line do |line|
                if line == "# BREAK EVAL\n"
                  eval(chunked_ruby)
                  chunked_ruby = ''
                else
                  chunked_ruby << line
                end
              end
              eval(chunked_ruby) unless chunked_ruby == ''
            end
          else
            # Just load regular .rb files
            #
            File.open(file) do |file|
              chunked_ruby = ''
              file.each_line do |line|
                if line == "# BREAK EVAL\n"
                  eval(chunked_ruby)
                  chunked_ruby = ''
                else
                  chunked_ruby << line
                end
              end
              eval(chunked_ruby) unless chunked_ruby == ''
            end
          end
        end

      ensure
        ActiveRecord::Base.logger.level = old_level
      end
    end
  end
end
