require "bundler/gem_tasks"
require "bump/tasks"

Bump.tag_by_default = true

task :default => :spec

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
