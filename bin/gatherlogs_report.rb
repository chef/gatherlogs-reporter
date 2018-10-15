#!/usr/bin/env ruby

require_relative '../lib/gatherlogs'
require_relative '../lib/gatherlogs/cli'

begin
  puts "Generating report..."
  cli = Gatherlogs::CLI.new(ARGV)
  cli.report_from_stdin()
rescue => e
  puts "[ERROR] #{e}"
  puts "Backtrace:"
  puts e.backtrace
  exit 1
end
