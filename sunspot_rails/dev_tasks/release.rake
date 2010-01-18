namespace :release do
  desc 'Release gem on RubyForge and GitHub'
  task :all => [:release, :"rubyforge:release:gem"]
end
