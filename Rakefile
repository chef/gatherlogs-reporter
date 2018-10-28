require "bundler/gem_tasks"
require 'rake/version_task'
Rake::VersionTask.new do |task|
  task.with_git_tag = true
end

task :default => :spec

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
