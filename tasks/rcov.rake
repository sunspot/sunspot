require 'rcov/rcovtask'
Rcov::RcovTask.new do |t|
  t.test_files = FileList['spec/*_spec.rb']
  t.rcov_opts << "-e 'spec'"
  t.rcov_opts << "--sort coverage"
  t.rcov_opts << "--only-uncovered"
end
