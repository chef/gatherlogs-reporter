require 'bundler/gem_tasks'
require 'bump/tasks'

Bump.tag_by_default = true

task default: :test

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task test: %i[spec rubocop]
