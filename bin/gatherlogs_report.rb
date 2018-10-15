#!/usr/bin/env ruby

require_relative '../lib/gatherlogs'

begin
  puts "Generating report..."
  reporter = Gatherlogs::Reporter.new()
  reporter.report(JSON.parse(STDIN.read))
rescue => e
  puts "[ERROR] #{e}"
  puts "Backtrace:"
  puts e.backtrace
  exit 1
end
