begin
  require 'spec/rake/spectask'
  require 'spec/rake/verify_rcov'

  RCov::VerifyTask.new('spec:rcov:verify' => 'spec:rcov') do |t| 
    t.threshold = 95.0
    t.index_html = 'coverage/specs/index.html'
    t.require_exact_threshold = false
  end
rescue LoadError
  task 'spec:rcov:verify' do
    puts "Failure!"
  end
end

