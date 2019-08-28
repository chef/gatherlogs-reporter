#!/usr/bin/env ruby

libdir = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'rubygems'
require 'bundler/setup'
require 'gatherlogs'
require 'gatherlogs/cli'

begin
  Gatherlogs::CLI.run
rescue StandardError => e
  puts "[ERROR] #{e}"
  puts 'Backtrace:'
  puts e.backtrace
  exit 1
end
