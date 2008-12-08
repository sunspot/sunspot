require 'rcov/rcovtask'
Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/**/test_*.rb']
  t.rcov_opts << "--sort coverage"
  t.rcov_opts << "--only-uncovered"
end
