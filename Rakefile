$:.unshift(File.dirname(__FILE__) + '/lib/')
require 'jimson/version'
require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

gem 'rubygems-tasks', '~> 0.2'
require 'rubygems/tasks'

Gem::Tasks.new

desc "Run all specs"
RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :rspec

require 'rdoc/task'

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "jimson #{Jimson::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
